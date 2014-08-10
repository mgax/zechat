from hashlib import sha1
from base64 import b64encode
from contextlib import contextmanager
import pytest
from mock import Mock
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


class Identity(object):

    def __init__(self, key=None):
        if key is None:
            from test_crypto import PRIVATE_KEY
            key = PRIVATE_KEY

        from zechat.cryptos import Crypto
        self.crypto = Crypto(key)

    @property
    def fp(self):
        return self.crypto.fingerprint()

    def authenticate(self, peer):
        peer.send(dict(type='challenge'), 1)
        challenge = peer.out.pop()['challenge']
        public_key = self.crypto.public_key()
        response = json.dumps(dict(challenge=challenge, public_key=public_key))
        auth_packet = dict(
            type='authenticate',
            response=response,
            signature=self.crypto.sign(response),
        )
        peer.send(auth_packet, 2)
        assert peer.out.pop()['success']

    def message(self, recipient, text):
        payload = b64encode(json.dumps(dict(text=text)))
        return dict(type='message', recipient=recipient, data=payload)


def reply(serial, **data):
    return dict(_reply=serial, **data)


def subscribe(identity):
    return dict(type='subscribe', identity=identity)


def list_(identity):
    return dict(type='list', identity=identity)


def get(identity, messages):
    return dict(type='get', identity=identity, messages=messages)


def hash(data):
    return sha1(data).hexdigest()


def test_loopback(node):
    id = Identity()
    with connection(node) as peer:
        id.authenticate(peer)
        foo = id.message(id.fp, 'foo')
        bar = id.message(id.fp, 'bar')

        peer.send(subscribe(id.fp), 2)
        peer.send(foo, 3)
        peer.send(bar, 4)

    assert peer.out == [
        reply(2),
        foo, reply(3),
        bar, reply(4),
    ]


def test_peer_receives_messages(node):
    id = Identity()
    with connection(node) as peer:
        id.authenticate(peer)
        peer.send(subscribe(id.fp), 2)
        foo = id.message(id.fp, 'foo')
        bar = id.message(id.fp, 'bar')

        with connection(node) as sender:
            sender.send(foo, 3)
            sender.send(bar, 4)

        assert sender.out == [reply(3), reply(4)]

    assert peer.out == [reply(2), foo, bar]


def test_messages_filtered_by_recipient(node):
    from test_crypto import PRIVATE_KEY_B
    id = Identity()  # sender
    id_a = Identity()  # recipient A
    id_b = Identity(PRIVATE_KEY_B)  # recipient B
    with connection(node) as a, connection(node) as b:
        id_a.authenticate(a)
        a.send(subscribe(id_a.fp), 2)
        id_b.authenticate(b)
        b.send(subscribe(id_b.fp), 2)
        foo = id.message(id_a.fp, 'foo')
        bar = id.message(id_b.fp, 'bar')

        with connection(node) as sender:
            sender.send(foo)
            sender.send(bar)

    assert a.out == [reply(2), foo]
    assert b.out == [reply(2), bar]


def test_message_history(node):
    id = Identity()
    foo = id.message(id.fp, 'foo')
    bar = id.message(id.fp, 'bar')
    foo_hash = hash(foo['data'])
    bar_hash = hash(bar['data'])

    with connection(node) as a:
        a.send(foo)
        a.send(bar)

    with connection(node) as b:
        id.authenticate(b)

        b.send(list_(id.fp), 2)
        assert b.out == [reply(2, messages=[foo_hash, bar_hash])]
        b.out[:] = []

        b.send(get(id.fp, [foo_hash, bar_hash]), 3)
        assert b.out == [reply(3, messages=[foo, bar])]
