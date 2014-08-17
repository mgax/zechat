import pytest
import flask
from mock import patch


@pytest.fixture
def client(app):
    from zechat import backend
    backend.init_app(app)
    return app.test_client()


def json_post(client, url, data, parse=True):
    json_data = flask.json.dumps(data)
    resp = client.post(url, data=json_data, content_type='application/json')
    if parse:
        assert resp.status_code == 200
        return flask.json.loads(resp.data)

    else:
        return resp


def json_get(client, url):
    resp = client.get(url)
    assert resp.status_code == 200
    assert resp.content_type == 'application/json'
    return flask.json.loads(resp.data)


def test_persistence(client, curve):
    from test_crypto import A_KEY, A_PUBKEY

    ch = json_post(client, '/state/challenge', {})
    server_pubkey = str(ch['pubkey'])
    confirmation = curve.encrypt(str(ch['challenge']), A_KEY, server_pubkey)
    auth = dict(
        pubkey=A_PUBKEY,
        signature=ch['signature'],
        confirmation=confirmation,
    )

    json_post(client, '/state/save', dict(auth, state='hello world'))
    state = json_post(client, '/state/load', auth)['state']
    assert state == 'hello world'


def test_verifier(curve):
    from test_crypto import A_KEY, A_PUBKEY, B_KEY
    from zechat.backend import Verifier

    verifier = Verifier()
    (challenge, signature, pubkey) = verifier.challenge()
    (other_challenge, other_signature, pubkey) = verifier.challenge()

    assert verifier.check(signature, A_PUBKEY,
        curve.encrypt(challenge, A_KEY, pubkey))

    # other challenge
    assert not verifier.check(other_signature, A_PUBKEY,
        curve.encrypt(challenge, A_KEY, pubkey))
    assert not verifier.check(signature, A_PUBKEY,
        curve.encrypt(other_challenge, A_KEY, pubkey))

    # key mismatch
    assert not verifier.check(signature, A_PUBKEY,
        curve.encrypt(challenge, B_KEY, pubkey))

    # bogus values
    assert not verifier.check('asdf', A_PUBKEY,
        curve.encrypt(challenge, A_KEY, pubkey))
    assert not verifier.check(signature, A_PUBKEY,
        'asdf')

    # old challenge
    with patch('itsdangerous.time') as time:
        time.time.return_value = 1408000000
        (old_challenge, old_signature, pubkey) = verifier.challenge()

    assert not verifier.check(old_signature, A_PUBKEY,
        curve.encrypt(old_challenge, A_KEY, pubkey))
