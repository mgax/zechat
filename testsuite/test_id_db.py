import pytest
import flask


@pytest.fixture
def app():
    from zechat import models
    from zechat import node

    app = flask.Flask(__name__)
    app.testing = True
    models.db.init_app(app)
    app.register_blueprint(node.views)

    with app.app_context():
        models.db.create_all()

    return app


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


def test_publish_identity(app):
    from test_crypto import PUBLIC_KEY, FINGERPRINT
    client = app.test_client()
    data = {'fingerprint': FINGERPRINT, 'public_key': PUBLIC_KEY}
    json_post(client, '/id/', data)
    resp = json_get(client, '/id/' + FINGERPRINT)
    assert resp == data


def test_check_fingerprint(app):
    client = app.test_client()
    data = {'fingerprint': 'foo', 'public_key': 'bar'}
    resp = json_post(client, '/id/', data, parse=False)
    assert resp.status_code == 400
    assert flask.json.loads(resp.data) == {'error': 'fingerprint mismatch'}


def test_republish_with_same_fingerprint(app):
    from test_crypto import PUBLIC_KEY, FINGERPRINT
    client = app.test_client()
    data = {'fingerprint': FINGERPRINT, 'public_key': PUBLIC_KEY}
    json_post(client, '/id/', data)
    json_post(client, '/id/', data)
    json_post(client, '/id/', data)
    resp = json_get(client, '/id/' + FINGERPRINT)
    assert resp == data
