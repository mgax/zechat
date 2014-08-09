import pytest
import flask


@pytest.fixture
def id_app(app):
    from zechat import node
    app.register_blueprint(node.views)
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


def test_publish_identity(id_app):
    from test_crypto import PUBLIC_KEY, FINGERPRINT
    client = id_app.test_client()
    data = {'fingerprint': FINGERPRINT, 'public_key': PUBLIC_KEY}
    json_post(client, '/id/', data)
    resp = json_get(client, '/id/' + FINGERPRINT)
    assert resp == data


def test_check_fingerprint(id_app):
    client = id_app.test_client()
    data = {'fingerprint': 'foo', 'public_key': 'bar'}
    resp = json_post(client, '/id/', data, parse=False)
    assert resp.status_code == 400
    assert flask.json.loads(resp.data) == {'error': 'fingerprint mismatch'}


def test_republish_with_same_fingerprint(id_app):
    from test_crypto import PUBLIC_KEY, FINGERPRINT
    client = id_app.test_client()
    data = {'fingerprint': FINGERPRINT, 'public_key': PUBLIC_KEY}
    json_post(client, '/id/', data)
    json_post(client, '/id/', data)
    json_post(client, '/id/', data)
    resp = json_get(client, '/id/' + FINGERPRINT)
    assert resp == data
