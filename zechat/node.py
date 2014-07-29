import logging

logger = logging.getLogger(__name__)


client_map = {}


class Transport(object):

    def __init__(self, ws):
        self.ws = ws

    def run(self):
        client_map[self.ws.id] = self.ws
        try:
            while True:
                msg = self.ws.receive()
                if msg is None:  # disconnect
                    break

                if not msg:  # ping?
                    continue

                logger.debug("message: %s", msg)
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
