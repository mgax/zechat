import flask
from zechat.models import db, Account

views = flask.Blueprint('backend', __name__)


@views.route('/state/<path:pubkey>', methods=['POST'])
def save(pubkey):
    account = Account.query.filter_by(pubkey=pubkey).first()
    if account is None:
        account = Account(pubkey=pubkey)
        db.session.add(account)
    account.state = flask.request.get_json()['state']
    db.session.commit()
    return flask.jsonify(ok=True)


@views.route('/state/<path:pubkey>')
def load(pubkey):
    account = Account.query.filter_by(pubkey=pubkey).first_or_404()
    return flask.jsonify(state=account.state)


def init_app(app):
    app.register_blueprint(views)
