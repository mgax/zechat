import logging
from flask.ext.uwsgi_websocket import GeventWebSocket

logger = logging.getLogger(__name__)

websocket = GeventWebSocket()

client_map = {}


@websocket.route('/ws/transport')
def transport(ws):
    client_map[ws.id] = ws
    try:
        while True:
            msg = ws.receive()
            if msg is None:  # disconnect
                break

            if not msg:  # ping?
                continue

            logger.debug("message: %s", msg)
            for client in client_map.values():
                client.send(msg)

    finally:
        del client_map[ws.id]
