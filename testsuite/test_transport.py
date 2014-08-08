from hashlib import sha1
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


class Client(object):

    _last_ws_id = 0

    @classmethod
    def next_id(cls):
        cls._last_ws_id += 1
        return cls._last_ws_id

    def __init__(self):
        self.ws = mock_ws(self.next_id())
        self.out = self.ws.out

    def send(self, transport, packet):
        transport.packet(packet)


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
    peer = Client()
    with node.transport(peer.ws) as transport:
        peer.send(transport, auth('A'))
        peer.send(transport, msg('A', 'foo'))
        peer.send(transport, msg('A', 'bar'))
    assert peer.out == [msg('A', 'foo'), msg('A', 'bar')]


def test_peer_receives_messages(node):
    peer = Client()
    sender = Client()

    with node.transport(peer.ws) as peer_transport:
        peer.send(peer_transport, auth('B'))

        with node.transport(sender.ws) as sender_transport:
            peer.send(sender_transport, msg('B', 'foo'))
            peer.send(sender_transport, msg('B', 'bar'))

    assert peer.out == [msg('B', 'foo'), msg('B', 'bar')]


def test_messages_filtered_by_recipient(node):
    a = Client()
    b = Client()
    sender = Client()

    with node.transport(a.ws) as tr_a, node.transport(b.ws) as tr_b:
        a.send(tr_a, auth('A'))
        b.send(tr_b, auth('B'))

        with node.transport(sender.ws) as sender_transport:
            sender.send(sender_transport, msg('A', 'foo'))
            sender.send(sender_transport, msg('B', 'bar'))

    assert a.out == [msg('A', 'foo')]
    assert b.out == [msg('B', 'bar')]


def test_message_history(node):
    a = Client()
    b = Client()

    with node.transport(a.ws) as tr_a:
        a.send(tr_a, msg('B', 'foo'))
        a.send(tr_a, msg('B', 'bar'))

    with node.transport(b.ws) as tr_b:
        b.send(tr_b, list_('B'))
        assert b.out == [{'messages': [msghash('foo'), msghash('bar')]}]
        b.out[:] = []

        b.send(tr_b, get('B', [msghash('foo'), msghash('bar')]))
        assert b.out == [msg('B', 'foo'), msg('B', 'bar')]
