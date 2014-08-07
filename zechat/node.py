import logging
from contextlib import contextmanager
from base64 import b64encode, b64decode
import hashlib
from collections import defaultdict
import flask
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_OAEP
from Crypto.Hash import SHA256
from Crypto.Signature import PKCS1_PSS
from zechat import models

logger = logging.getLogger(__name__)


class Crypto(object):

    def __init__(self, key):
        self.key = RSA.importKey(key)

    def _cipher(self):
        return PKCS1_OAEP.new(self.key)

    def _signer(self):
        return PKCS1_PSS.new(self.key)

    def encrypt(self, data):
        return b64encode(self._cipher().encrypt(data))

    def decrypt(self, data_b64):
        return self._cipher().decrypt(b64decode(data_b64))

    def sign(self, data):
        return b64encode(self._signer().sign(SHA256.new(data)))

    def verify(self, data, signature_b64):
        signature = b64decode(signature_b64)
        return self._signer().verify(SHA256.new(data), signature)

    def fingerprint(self):
        data = self.key.publickey().exportKey('DER')
        return hashlib.sha1(data).hexdigest()[:32]


class Node(object):

    def __init__(self):
        self.transport_map = {}
        self.inbox = defaultdict(dict)

    @contextmanager
    def transport(self, ws):
        transport = Transport(self, ws)
        self.transport_map[ws.id] = transport
        try:
            yield transport
        finally:
            del self.transport_map[ws.id]

    def relay(self, pkt, recipient):
        message_data = flask.json.dumps(pkt['message'])
        message_hash = hashlib.sha1(message_data).hexdigest()
        self.inbox[recipient][message_hash] = message_data

        for client in self.transport_map.values():
            if recipient in client.identities:
                client.send(pkt)

    def send_list(self, identity, transport):
        transport.send(dict(messages=list(self.inbox[identity])))

    def send_messages(self, identity, messages, transport):
        for message_hash in messages:
            message = flask.json.loads(self.inbox[identity][message_hash])
            transport.send(dict(
                type='message',
                recipient=identity,
                message=message,
            ))


class Transport(object):

    def __init__(self, node, ws):
        self.node = node
        self.ws = ws
        self.identities = set()

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

    def handle(self):
        for pkt in self.iter_packets():
            self.packet(pkt)

    def packet(self, pkt):
        if pkt['type'] == 'authenticate':
            self.identities.add(pkt['identity'])

        elif pkt['type'] == 'message':
            self.node.relay(pkt, pkt['recipient'])

        elif pkt['type'] == 'list':
            self.node.send_list(pkt['identity'], self)

        elif pkt['type'] == 'get':
            self.node.send_messages(pkt['identity'], pkt['messages'], self)

        else:
            raise RuntimeError("Unknown packet type %r" % pkt['type'])

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

        node = Node()

        websocket = GeventWebSocket(app)

        @websocket.route('/ws/transport')
        def transport(ws):
            with node.transport(ws) as transprot:
                transprot.handle()
