import flask
import itsdangerous
from zechat.cryptos import CurveCrypto, random_key, DecryptionError
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


class Verifier(object):

    def __init__(self):
        self.key = random_key()
        self.curve = CurveCrypto()
        self.pubkey = self.curve.pubkey(self.key)
        self.signer = itsdangerous.Signer(random_key())

    def challenge(self):
        challenge = self.curve.challenge()
        signature = self.signer.sign(challenge)
        return (challenge, signature, self.pubkey)

    def check(self, signature, pubkey, confirmation):
        try:
            challenge = self.signer.unsign(signature)
            recv = self.curve.decrypt(confirmation, pubkey, self.key)

        except (itsdangerous.BadSignature, DecryptionError):
            return False

        else:
            return recv == challenge


def init_app(app):
    app.register_blueprint(views)
