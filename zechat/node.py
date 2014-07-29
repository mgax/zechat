import logging
import flask
from zechat.models import db, Message
from flask.ext.uwsgi_websocket import GeventWebSocket

logger = logging.getLogger(__name__)

websocket = GeventWebSocket()

views = flask.Blueprint('node', __name__)


@views.route('/save', methods=['POST'])
def save():
    data = flask.request.get_json()
    message = Message(recipient=data['recipient'], data=flask.json.dumps(data))
    db.session.add(message)
    db.session.commit()
    return 'ok'


@views.route('/get_messages', methods=['POST'])
def get_messages():
    identity = flask.request.get_json()['identity']
    message_list = [
        flask.json.loads(m.data)
        for m in Message.query.filter_by(recipient=identity)
    ]
    return flask.jsonify(message_list=message_list)


@websocket.route('/ws/transport')
def transport(ws):
    while True:
        msg = ws.receive()
        if msg is None:
            break

        logger.debug("message: %s", msg)
        ws.send(msg)
