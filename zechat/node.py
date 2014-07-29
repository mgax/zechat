import logging

logger = logging.getLogger(__name__)


client_map = {}


class Transport(object):

    def __init__(self, ws):
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
        client_map[self.ws.id] = self.ws
        try:
            for msg in self.messages():
                for client in client_map.values():
                    client.send(msg)

        finally:
            del client_map[self.ws.id]


def transport(ws):
    Transport(ws).run()


def init_app(app):
    from flask.ext.uwsgi_websocket import GeventWebSocket
    websocket = GeventWebSocket(app)
    websocket.route('/ws/transport')(transport)
