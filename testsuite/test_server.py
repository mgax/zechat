import pytest
import flask


@pytest.fixture
def app():
    from zechat.app import create_app
    from zechat.models import db
    app = create_app()
    app.testing = True
    with app.app_context():
        db.create_all()
    return app.test_client()


def post_json(app, url, data):
    json_data = flask.json.dumps(data)
    return app.post(url, data=json_data, content_type='application/json')


def get_json(resp, status_code=200, content_type='application/json'):
    assert resp.status_code == status_code
    assert resp.content_type == content_type
    return flask.json.loads(resp.data)


def test_receive_message(app):
    post_resp = post_json(app, '/save', {'text': 'foo', 'recipient': 'bar'})
    assert post_resp.status_code == 200

    data = get_json(app.post('/get_messages', {'identity': 'bar'}))
    assert data == {
        'message_list': [
            {'text': 'foo', 'recipient': 'bar'},
        ]
    }
