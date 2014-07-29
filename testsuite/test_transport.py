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


def test_handle(node):
    ws = mock_ws('A')
    incoming = [msg('A', 'foo'), msg('A', 'bar')]
    ws.receive.side_effect = [json.dumps(i) for i in incoming] + [None]
    with node.transport(ws) as transport:
        transport.handle()
    assert ws.out == [msg('A', 'foo'), msg('A', 'bar')]


def test_peer_receives_messages(node):
    peer = mock_ws('B')
    with node.transport(peer):
        with node.transport(mock_ws('A')) as sender_transport:
            sender_transport.message(msg('B', 'foo'))
            sender_transport.message(msg('B', 'bar'))

    assert peer.out == [msg('B', 'foo'), msg('B', 'bar')]
