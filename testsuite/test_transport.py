import pytest
from mock import Mock, call
from flask import json


@pytest.fixture
def node():
    from zechat.node import Node
    return Node()


def mock_ws(client_id):
    ws = Mock(id=client_id)
    ws.out = []
    ws.send.side_effect = lambda i: ws.out.append(json.loads(i))
    return ws


def msg(recipient, text):
    return dict(type='message', recipient=recipient, message=dict(text=text))


def auth(identity):
    return dict(type='authenticate', identity=identity)


def test_handle(node):
    ws = mock_ws('A')
    incoming = [auth('A'), msg('A', 'foo'), msg('A', 'bar')]
    ws.receive.side_effect = [json.dumps(i) for i in incoming] + [None]
    with node.transport(ws) as transport:
        transport.handle()
    assert ws.out == [msg('A', 'foo'), msg('A', 'bar')]


def test_peer_receives_messages(node):
    peer = mock_ws('B')
    with node.transport(peer) as peer_transport:
        peer_transport.packet(auth('B'))
        with node.transport(mock_ws('A')) as sender_transport:
            sender_transport.packet(msg('B', 'foo'))
            sender_transport.packet(msg('B', 'bar'))

    assert peer.out == [msg('B', 'foo'), msg('B', 'bar')]


def test_messages_filtered_by_recipient(node):
    a = mock_ws('A')
    b = mock_ws('B')
    with node.transport(a) as tr_a, node.transport(b) as tr_b:
        tr_a.packet(auth('A'))
        tr_b.packet(auth('B'))

        with node.transport(mock_ws('sender')) as sender_transport:
            sender_transport.packet(msg('A', 'foo'))
            sender_transport.packet(msg('B', 'bar'))

    assert a.out == [msg('A', 'foo')]
    assert b.out == [msg('B', 'bar')]
