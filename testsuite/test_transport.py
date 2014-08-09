from hashlib import sha1
from contextlib import contextmanager
import pytest
from mock import Mock
import flask
from flask import json


@pytest.yield_fixture
def node(app):
    from zechat.node import Node

    with app.app_context():
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

    def send(self, pkt, serial=None):
        if serial:
            pkt['_serial'] = serial
        self.node.packet(self.transport, pkt)

    @contextmanager
    def connection(self, node):
        self.node = node
        with node.transport(self.ws) as self.transport:
            yield self


def msg(recipient, text):
    return dict(type='message', recipient=recipient, message=dict(text=text))


def reply(serial, **data):
    return dict(type='reply', _serial=serial, **data)


def auth(identity):
    return dict(type='authenticate', identity=identity)


def subscribe(identity):
    return dict(type='subscribe', identity=identity)


def list_(identity):
    return dict(type='list', identity=identity)


def get(identity, messages):
    return dict(type='get', identity=identity, messages=messages)


def msghash(text):
    return sha1(json.dumps(dict(text=text))).hexdigest()


def test_loopback(node):
    with connection(node) as peer:
        peer.send(auth('A'), 1)
        peer.send(subscribe('A'), 2)
        peer.send(msg('A', 'foo'), 3)
        peer.send(msg('A', 'bar'), 4)

    assert peer.out == [
        reply(1), reply(2),
        reply(3), msg('A', 'foo'),
        reply(4), msg('A', 'bar'),
    ]


def test_peer_receives_messages(node):
    with connection(node) as peer:
        peer.send(auth('B'), 1)
        peer.send(subscribe('B'), 2)

        with connection(node) as sender:
            peer.send(msg('B', 'foo'))
            peer.send(msg('B', 'bar'))

    assert peer.out == [reply(1), reply(2), msg('B', 'foo'), msg('B', 'bar')]


def test_messages_filtered_by_recipient(node):
    with connection(node) as a, connection(node) as b:
        a.send(auth('A'), 1)
        a.send(subscribe('A'), 2)
        b.send(auth('B'), 1)
        b.send(subscribe('B'), 2)

        with connection(node) as sender:
            sender.send(msg('A', 'foo'))
            sender.send(msg('B', 'bar'))

    assert a.out == [reply(1), reply(2), msg('A', 'foo')]
    assert b.out == [reply(1), reply(2), msg('B', 'bar')]


def test_message_history(node):
    with connection(node) as a:
        a.send(msg('B', 'foo'))
        a.send(msg('B', 'bar'))

    with connection(node) as b:
        b.send(auth('B'), 1)
        b.out[:] = []

        b.send(list_('B'), 2)
        assert b.out == [reply(2, messages=[msghash('foo'), msghash('bar')])]
        b.out[:] = []

        b.send(get('B', [msghash('foo'), msghash('bar')]), 3)
        assert b.out == [reply(3, messages=[msg('B', 'foo'), msg('B', 'bar')])]
