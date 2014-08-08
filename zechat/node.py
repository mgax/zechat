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


class Inbox(object):

    def __init__(self, identity):
        self.identity = identity

    def save(self, message_data):
        message = models.Message(
            payload=message_data,
            hash=hashlib.sha1(message_data).hexdigest(),
            recipient=self.identity,
        )
        models.db.session.add(message)
        models.db.session.commit()

    def get(self, message_hash):
        message = models.Message.query.filter_by(hash=message_hash).first()
        assert message and message.recipient == self.identity
        return message.payload

    def hash_list(self):
        return [
            message.hash for message in
            models.Message.query.filter_by(recipient=self.identity)
        ]


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

        elif pkt['type'] == 'message':
            recipient = pkt['recipient']
            message_data = flask.json.dumps(pkt['message'])
            Inbox(recipient).save(message_data)

            serial = pkt.pop('_serial', None)
            if serial:
                transport.send(dict(type='reply', _serial=serial))

            for client in self.transport_map.values():
                if recipient in client.identities:
                    client.send(pkt)

        elif pkt['type'] == 'list':
            identity = pkt['identity']
            assert identity in transport.identities
            transport.send(dict(
                type='reply',
                _serial=pkt.get('_serial'),
                messages=Inbox(identity).hash_list(),
            ))

        elif pkt['type'] == 'get':
            identity = pkt['identity']
            assert identity in transport.identities
            inbox = Inbox(identity)
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
