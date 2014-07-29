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


def test_roundtrip(node):
    out = handle(node, mock_ws('one'), ['foo', 'bar'])
    assert out == ['foo', 'bar']


def test_peer_receives_messages(node):
    peer_ws = mock_ws('two')
    with node.transport(peer_ws):
        handle(node, mock_ws('one'), ['foo', 'bar'])

    assert peer_ws.out == ['foo', 'bar']
