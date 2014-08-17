import flask
import itsdangerous
from zechat.cryptos import CurveCrypto, random_key, DecryptionError
from zechat.models import db, Account

views = flask.Blueprint('backend', __name__)


@views.route('/state/challenge', methods=['POST'])
def challenge():
    (challenge, signature, pubkey) = verifier().challenge()
    return flask.jsonify(
        challenge=challenge,
        signature=signature,
        pubkey=pubkey,
    )


def auth(data):
    return verifier().check(
        data['signature'],
        data['pubkey'],
        data['confirmation'],
    )


@views.route('/state/save', methods=['POST'])
def save():
    data = flask.request.get_json()
    if not auth(data):
        flask.abort(403)
    account = Account.query.filter_by(pubkey=data['pubkey']).first()
    if account is None:
        account = Account(pubkey=data['pubkey'])
        db.session.add(account)
    account.state = data['state']
    db.session.commit()
    return flask.jsonify(ok=True)


@views.route('/state/load', methods=['POST'])
def load():
    data = flask.request.get_json()
    if not auth(data):
        flask.abort(403)
    account = Account.query.filter_by(pubkey=data['pubkey']).first_or_404()
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


def verifier():
    return flask.current_app.extensions['zechat-verifier']


def init_app(app):
    app.extensions['zechat-verifier'] = Verifier()
    app.register_blueprint(views)
