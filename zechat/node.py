import logging
from contextlib import contextmanager

logger = logging.getLogger(__name__)


class Node(object):

    def __init__(self):
        self.client_map = {}

    @contextmanager
    def register_client(self, ws):
        self.client_map[ws.id] = ws
        try:
            yield
        finally:
            del self.client_map[ws.id]

    def handle_transport(self, ws):
        Transport(self, ws).run()


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

    def run(self):
        with self.node.register_client(self.ws):
            for msg in self.messages():
                for client in self.node.client_map.values():
                    client.send(msg)


def init_app(app):
    from flask.ext.uwsgi_websocket import GeventWebSocket
    websocket = GeventWebSocket(app)

    node = Node()

    @websocket.route('/ws/transport')
    def transport(ws):
        node.handle_transport(ws)
