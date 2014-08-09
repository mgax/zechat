import logging
from contextlib import contextmanager
import flask
from zechat.cryptos import Crypto
from zechat import models

logger = logging.getLogger(__name__)


class Node(object):

    def __init__(self, app=None):
        self.transport_map = {}
        self.app = app

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
                    self.packet(transprot, pkt)

    def packet(self, transport, pkt):
        if pkt['type'] == 'authenticate':
            transport.identities.add(pkt['identity'])
            transport.send(dict(type='reply', _serial=pkt['_serial']))

        elif pkt['type'] == 'subscribe':
            identity = pkt['identity']
            assert identity in transport.identities
            transport.subscriptions.add(identity)
            transport.send(dict(type='reply', _serial=pkt.get('_serial')))

        elif pkt['type'] == 'message':
            recipient = pkt['recipient']
            message_data = flask.json.dumps(pkt['message'])
            models.Inbox(recipient).save(message_data)

            serial = pkt.pop('_serial', None)
            if serial:
                transport.send(dict(type='reply', _serial=serial))

            for client in self.transport_map.values():
                if recipient in client.subscriptions:
                    client.send(pkt)

        elif pkt['type'] == 'list':
            identity = pkt['identity']
            assert identity in transport.identities
            transport.send(dict(
                type='reply',
                _serial=pkt.get('_serial'),
                messages=models.Inbox(identity).hash_list(),
            ))

        elif pkt['type'] == 'get':
            identity = pkt['identity']
            assert identity in transport.identities
            inbox = models.Inbox(identity)
            message_list = [
                dict(
                    type='message',
                    recipient=identity,
                    message=flask.json.loads(inbox.get(message_hash)),
                )
                for message_hash in pkt['messages']
            ]
            transport.send(dict(
                type='reply',
                _serial=pkt['_serial'],
                messages=message_list,
            ))

        else:
            raise RuntimeError("Unknown packet type %r" % pkt['type'])


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
            logger.debug("packet: %r", pkt)
            yield pkt

    def send(self, pkt):
        self.ws.send(flask.json.dumps(pkt))


views = flask.Blueprint('node', __name__)


def _check_fingerprint(public_key, fingerprint):
    try:
        crypto = Crypto(public_key)
    except ValueError:
        return False
    else:
        return crypto.fingerprint() == fingerprint


@views.route('/id/', methods=['POST'])
def post_identity():
    data = flask.request.get_json()
    public_key = data['public_key']
    fingerprint = data['fingerprint']

    if not _check_fingerprint(public_key, fingerprint):
        return (flask.jsonify(error='fingerprint mismatch'), 400)

    identity = (
        models.Identity.query
        .filter_by(fingerprint=fingerprint)
        .first()
    )

    if identity is None:
        identity = models.Identity(fingerprint=fingerprint)
        models.db.session.add(identity)

    identity.public_key = public_key
    models.db.session.commit()
    return flask.jsonify(
        ok=True,
        url=flask.url_for(
            '.get_identity',
            fingerprint=fingerprint,
            _external=True,
        ),
    )


@views.route('/id/<fingerprint>')
def get_identity(fingerprint):
    identity = (
        models.Identity.query
        .filter_by(fingerprint=fingerprint)
        .first_or_404()
    )
    return flask.jsonify(
        fingerprint=identity.fingerprint,
        public_key=identity.public_key,
    )


def init_app(app):
    app.register_blueprint(views)

    if app.config.get('LISTEN_WEBSOCKET'):
        from flask.ext.uwsgi_websocket import GeventWebSocket

        node = Node(app)

        websocket = GeventWebSocket(app)

        websocket.route('/ws/transport')(node.handle_connection)
