import flask
from zechat.models import db, Message

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
    return flask.jsonify(message_list=[flask.json.loads(m.data)
                                       for m in Message.query])
