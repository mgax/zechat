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


def save_message(app, data):
    post_resp = post_json(app, '/save', data)
    assert post_resp.status_code == 200


def test_receive_message(app):
    save_message(app, {'text': 'foo', 'recipient': 'bar'})
    data = get_json(post_json(app, '/get_messages', {'identity': 'bar'}))
    assert data == {
        'message_list': [
            {'text': 'foo', 'recipient': 'bar'},
        ]
    }


def test_fetch_messages_for_identity(app):
    save_message(app, {'text': 'foo', 'recipient': 'one'})
    save_message(app, {'text': 'bar', 'recipient': 'two'})
    save_message(app, {'text': 'baz', 'recipient': 'one'})

    data = get_json(post_json(app, '/get_messages', {'identity': 'one'}))
    assert data == {
        'message_list': [
            {'text': 'foo', 'recipient': 'one'},
            {'text': 'baz', 'recipient': 'one'},
        ]
    }
