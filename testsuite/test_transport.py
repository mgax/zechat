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


def handle(node, ws, incoming):
    ws.receive.side_effect = [json.dumps(i) for i in incoming] + [None]
    with node.transport(ws) as transport:
        transport.handle()
    return ws.out


def msg(recipient, text):
    return dict(recipient=recipient, text=text)


def test_roundtrip(node):
    out = handle(node, mock_ws('A'), [msg('A', 'foo'), msg('A', 'bar')])
    assert out == [msg('A', 'foo'), msg('A', 'bar')]


def test_peer_receives_messages(node):
    peer = mock_ws('B')
    with node.transport(peer):
        handle(node, mock_ws('A'), [msg('B', 'foo'), msg('B', 'bar')])

    assert peer.out == [msg('B', 'foo'), msg('B', 'bar')]
