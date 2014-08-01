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


def json_post(client, url, data):
    json_data = flask.json.dumps(data)
    resp = client.post(url, data=json_data, content_type='application/json')
    assert resp.status_code == 200
    return flask.json.loads(resp.data)


def json_get(client, url):
    resp = client.get(url)
    assert resp.status_code == 200
    assert resp.content_type == 'application/json'
    return flask.json.loads(resp.data)


def test_publish_identity(app):
    client = app.test_client()
    json_post(client, '/id/', {'fingerprint': 'foo', 'public_key': 'bar'})
    resp = json_get(client, '/id/foo')
    assert resp == {'fingerprint': 'foo', 'public_key': 'bar'}
