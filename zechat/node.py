import logging
from contextlib import contextmanager
from flask import json

logger = logging.getLogger(__name__)


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
