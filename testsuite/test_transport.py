from hashlib import sha1
from contextlib import contextmanager
import pytest
from mock import Mock
import flask
from flask import json


@pytest.yield_fixture
def node(request):
    from zechat import models
    from zechat.node import Node

    app0 = flask.Flask(__name__)
    app0.config.from_pyfile('../settings.py', silent=False)
    db_uri = app0.config['TESTING_SQLALCHEMY_DATABASE_URI']

    app = flask.Flask(__name__)
    app.testing = True
    app.config['SQLALCHEMY_DATABASE_URI'] = db_uri
    models.db.init_app(app)

    with app.app_context():
        models.db.drop_all()
        models.db.create_all()
        yield Node()


def mock_ws(client_id):
    ws = Mock(id=client_id)
    ws.out = []
    ws.send.side_effect = lambda i: ws.out.append(json.loads(i))
    return ws


def connection(node):
    return Client().connection(node)


class Client(object):

    _last_ws_id = 0

    @classmethod
    def next_id(cls):
        cls._last_ws_id += 1
        return cls._last_ws_id

    def __init__(self):
        self.ws = mock_ws(self.next_id())
        self.out = self.ws.out

    def send(self, packet):
        self.transport.packet(packet)

    @contextmanager
    def connection(self, node):
        with node.transport(self.ws) as self.transport:
            yield self


def msg(recipient, text):
    return dict(type='message', recipient=recipient, message=dict(text=text))


def auth(identity):
    return dict(type='authenticate', identity=identity)


def list_(identity):
    return dict(type='list', identity=identity)


def get(identity, messages):
    return dict(type='get', identity=identity, messages=messages)


def msghash(text):
    return sha1(json.dumps(dict(text=text))).hexdigest()


def test_loopback(node):
    with connection(node) as peer:
        peer.send(auth('A'))
        peer.send(msg('A', 'foo'))
        peer.send(msg('A', 'bar'))
    assert peer.out == [msg('A', 'foo'), msg('A', 'bar')]


def test_peer_receives_messages(node):
    with connection(node) as peer:
        peer.send(auth('B'))

        with connection(node) as sender:
            peer.send(msg('B', 'foo'))
            peer.send(msg('B', 'bar'))

    assert peer.out == [msg('B', 'foo'), msg('B', 'bar')]


def test_messages_filtered_by_recipient(node):
    with connection(node) as a, connection(node) as b:
        a.send(auth('A'))
        b.send(auth('B'))

        with connection(node) as sender:
            sender.send(msg('A', 'foo'))
            sender.send(msg('B', 'bar'))

    assert a.out == [msg('A', 'foo')]
    assert b.out == [msg('B', 'bar')]


def test_message_history(node):
    with connection(node) as a:
        a.send(msg('B', 'foo'))
        a.send(msg('B', 'bar'))

    with connection(node) as b:
        b.send(list_('B'))
        assert b.out == [{'messages': [msghash('foo'), msghash('bar')]}]
        b.out[:] = []

        b.send(get('B', [msghash('foo'), msghash('bar')]))
        assert b.out == [msg('B', 'foo'), msg('B', 'bar')]
