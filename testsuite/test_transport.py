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
        self.node.handle_packet(self.transport, pkt)

    @contextmanager
    def connection(self, node):
        self.node = node
        with node.transport(self.ws) as self.transport:
            yield self


def msg(recipient, text):
    return dict(type='message', recipient=recipient, message=dict(text=text))


def reply(serial, **data):
    return dict(_reply=serial, **data)


def auth(response, signature):
    return dict(type='authenticate', response=response, signature=signature)


def subscribe(identity):
    return dict(type='subscribe', identity=identity)


def list_(identity):
    return dict(type='list', identity=identity)


def get(identity, messages):
    return dict(type='get', identity=identity, messages=messages)


def msghash(text):
    return sha1(json.dumps(dict(text=text))).hexdigest()


def authenticate(peer, key=None):
    from zechat.cryptos import Crypto

    if key is None:
        from test_crypto import PRIVATE_KEY
        key = PRIVATE_KEY

    peer.send(dict(type='challenge'), 1)
    challenge = peer.out.pop()['challenge']
    crypto = Crypto(key)
    public_key = crypto.public_key()
    response = json.dumps(dict(challenge=challenge, public_key=public_key))
    peer.send(auth(response, crypto.sign(response)), 2)
    assert peer.out.pop()['success'] == True
    return crypto.fingerprint()


def test_loopback(node):
    with connection(node) as peer:
        fp = authenticate(peer)
        peer.send(subscribe(fp), 2)
        peer.send(msg(fp, 'foo'), 3)
        peer.send(msg(fp, 'bar'), 4)

    assert peer.out == [
        reply(2),
        msg(fp, 'foo'), reply(3),
        msg(fp, 'bar'), reply(4),
    ]


def test_peer_receives_messages(node):
    with connection(node) as peer:
        fp = authenticate(peer)
        peer.send(subscribe(fp), 2)

        with connection(node) as sender:
            peer.send(msg(fp, 'foo'), 3)
            peer.send(msg(fp, 'bar'), 4)

    assert peer.out == [
        reply(2),
        msg(fp, 'foo'), reply(3),
        msg(fp, 'bar'), reply(4),
    ]


def test_messages_filtered_by_recipient(node):
    from test_crypto import PRIVATE_KEY_B, FINGERPRINT_B as fp_b
    with connection(node) as a, connection(node) as b:
        fp_a = authenticate(a)
        a.send(subscribe(fp_a), 2)
        assert authenticate(b, PRIVATE_KEY_B) == fp_b
        b.send(subscribe(fp_b), 2)

        with connection(node) as sender:
            sender.send(msg(fp_a, 'foo'))
            sender.send(msg(fp_b, 'bar'))

    assert a.out == [reply(2), msg(fp_a, 'foo')]
    assert b.out == [reply(2), msg(fp_b, 'bar')]


def test_message_history(node):
    from test_crypto import PRIVATE_KEY_B, FINGERPRINT_B as fp_b

    with connection(node) as a:
        a.send(msg(fp_b, 'foo'))
        a.send(msg(fp_b, 'bar'))

    with connection(node) as b:
        assert authenticate(b, PRIVATE_KEY_B) == fp_b

        b.send(list_(fp_b), 2)
        assert b.out == [reply(2, messages=[msghash('foo'), msghash('bar')])]
        b.out[:] = []

        b.send(get(fp_b, [msghash('foo'), msghash('bar')]), 3)
        assert b.out == [reply(3, messages=[msg(fp_b, 'foo'), msg(fp_b, 'bar')])]
