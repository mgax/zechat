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

    def relay(self, msg, recipient):
        for client in self.transport_map.values():
            if recipient in client.identities:
                client.send(msg)


class Transport(object):

    def __init__(self, node, ws):
        self.node = node
        self.ws = ws
        self.identities = set()

    def messages(self):
        while True:
            msg = self.ws.receive()
            if msg is None:  # disconnect
                break

            if not msg:  # ping?
                continue

            logger.debug("message: %s", msg)
            yield json.loads(msg)

    def handle(self):
        for msg in self.messages():
            self.message(msg)

    def message(self, msg):
        if msg['type'] == 'authenticate':
            self.identities.add(msg['identity'])

        elif msg['type'] == 'message':
            self.node.relay(msg, msg['recipient'])

        else:
            raise RuntimeError("Unknown message type %r" % msg['type'])

    def send(self, msg):
        self.ws.send(json.dumps(msg))


def init_app(app):
    from flask.ext.uwsgi_websocket import GeventWebSocket
    websocket = GeventWebSocket(app)

    node = Node()

    @websocket.route('/ws/transport')
    def transport(ws):
        with node.transport(ws) as transprot:
            transprot.handle()
