import logging
from contextlib import contextmanager
from base64 import b64encode, b64decode
from flask import json
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_OAEP

logger = logging.getLogger(__name__)


class Crypto(object):

    def __init__(self, key):
        self.key = RSA.importKey(key)

    def encrypt(self, data):
        return b64encode(PKCS1_OAEP.new(self.key).encrypt(data))

    def decrypt(self, data_b64):
        return PKCS1_OAEP.new(self.key).decrypt(b64decode(data_b64))


class Node(object):

    def __init__(self):
        self.transport_map = {}

    @contextmanager
    def transport(self, ws):
        transport = Transport(self, ws)
        self.transport_map[ws.id] = transport
        try:
            yield transport
        finally:
            del self.transport_map[ws.id]

    def relay(self, pkt, recipient):
        for client in self.transport_map.values():
            if recipient in client.identities:
                client.send(pkt)


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

            pkt = json.loads(data)
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

        else:
            raise RuntimeError("Unknown packet type %r" % pkt['type'])

    def send(self, pkt):
        self.ws.send(json.dumps(pkt))


def init_app(app):
    from flask.ext.uwsgi_websocket import GeventWebSocket
    websocket = GeventWebSocket(app)

    node = Node()

    @websocket.route('/ws/transport')
    def transport(ws):
        with node.transport(ws) as transprot:
            transprot.handle()
