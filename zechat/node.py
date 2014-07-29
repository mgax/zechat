import logging
from contextlib import contextmanager

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


class Transport(object):

    def __init__(self, node, ws):
        self.node = node
        self.ws = ws

    def messages(self):
        while True:
            msg = self.ws.receive()
            if msg is None:  # disconnect
                break

            if not msg:  # ping?
                continue

            logger.debug("message: %s", msg)
            yield msg

    def handle(self):
        for msg in self.messages():
            for client in self.node.transport_map.values():
                client.send(msg)

    def send(self, msg):
        self.ws.send(msg)


def init_app(app):
    from flask.ext.uwsgi_websocket import GeventWebSocket
    websocket = GeventWebSocket(app)

    node = Node()

    @websocket.route('/ws/transport')
    def transport(ws):
        with node.transport(ws) as transprot:
            transprot.handle()
