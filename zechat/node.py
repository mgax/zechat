import logging
from contextlib import contextmanager
import flask
from zechat.cryptos import CurveCrypto, random_key
from zechat import models

logger = logging.getLogger(__name__)


class Node(object):

    packet_handlers = {}

    def __init__(self, app=None):
        self.transport_map = {}
        self.app = app
        if app is not None:
            app.extensions['zechat_node'] = self
        self.curve = CurveCrypto()
        self.key = random_key()
        self.pubkey = self.curve.pubkey(self.key)

    @classmethod
    def on(cls, name):
        def decorator(func):
            cls.packet_handlers[name] = func
            return func

        return decorator

    @contextmanager
    def transport(self, ws):
        transport = Transport(ws)
        self.transport_map[ws.id] = transport
        try:
            yield transport
        finally:
            del self.transport_map[ws.id]

    def handle_connection(self, ws):
        with self.transport(ws) as transprot:
            for pkt in transprot.iter_packets():
                with self.app.app_context():
                    self.handle_packet(transprot, pkt)

    def handle_packet(self, transport, pkt):
        serial = pkt.pop('_serial', None)
        func = self.packet_handlers.get(pkt['type'])

        if func is None:
            raise RuntimeError("Unknown packet type %r" % pkt['type'])

        rv = func(self, transport, pkt) or {}
        rv['_reply'] = serial
        transport.send(rv)


def check_identity(func):
    def wrapper(node, transport, pkt):
        identity = pkt['identity']
        assert identity in transport.identities
        return func(node, transport, pkt, identity)
    return wrapper


@Node.on('ping')
def ping(node, transport, pkt):
    return dict()


@Node.on('challenge')
def challenge(node, transport, pkt):
    transport.challenge = node.curve.challenge()
    return dict(challenge=transport.challenge, pubkey=node.pubkey)


@Node.on('authenticate')
def authenticate(node, transport, pkt):
    response = node.curve.decrypt(pkt['response'], pkt['pubkey'], node.key)
    assert response == transport.challenge
    del transport.challenge
    transport.identities.add(pkt['pubkey'])
    return dict(success=True)


@Node.on('subscribe')
@check_identity
def subscribe(node, transport, pkt, identity):
    transport.subscriptions.add(identity)


@Node.on('message')
def message(node, transport, pkt):
    recipient = pkt['recipient']
    models.Inbox(recipient).save(pkt['sender'], pkt['data'])

    for client in node.transport_map.values():
        if recipient in client.subscriptions:
            client.send(pkt)


@Node.on('list')
@check_identity
def list_(node, transport, pkt, identity):
    return dict(messages=models.Inbox(identity).hash_list())


@Node.on('get')
@check_identity
def get(node, transport, pkt, identity):
    inbox = models.Inbox(identity)

    def retrieve(message_hash):
        (sender, data) = inbox.get(message_hash)
        return dict(
            type='message',
            sender=sender,
            recipient=identity,
            data=data,
        )

    message_list = [
        retrieve(message_hash)
        for message_hash in pkt['messages']
    ]
    return dict(messages=message_list)


class Transport(object):

    def __init__(self, ws):
        self.ws = ws
        self.identities = set()
        self.subscriptions = set()

    def iter_packets(self):
        while True:
            data = self.ws.receive()
            if data is None:  # disconnect
                break

            if not data:  # ping?
                continue

            pkt = flask.json.loads(data)
            logger.debug("pkt in %r", pkt)
            yield pkt

    def send(self, pkt):
        logger.debug("pkt out %r", pkt)
        self.ws.send(flask.json.dumps(pkt))


def init_app(app):
    if app.config.get('LISTEN_WEBSOCKET'):
        from flask.ext.uwsgi_websocket import GeventWebSocket

        Node(app)

        websocket = GeventWebSocket(app)

        @websocket.route('/ws/transport')
        def ws_transport(ws):
            node = app.extensions['zechat_node']
            node.handle_connection(ws)
