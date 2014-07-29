import logging
from contextlib import contextmanager

logger = logging.getLogger(__name__)


class Node(object):

    def __init__(self):
        self.client_map = {}

    @contextmanager
    def register_client(self, transport):
        self.client_map[transport.ws.id] = transport
        try:
            yield
        finally:
            del self.client_map[transport.ws.id]

    def transport(self, ws):
        return Transport(self, ws)


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
        with self.node.register_client(self):
            for msg in self.messages():
                for client in self.node.client_map.values():
                    client.send(msg)

    def send(self, msg):
        self.ws.send(msg)


def init_app(app):
    from flask.ext.uwsgi_websocket import GeventWebSocket
    websocket = GeventWebSocket(app)

    node = Node()

    @websocket.route('/ws/transport')
    def transport(ws):
        node.transport(ws).handle()
