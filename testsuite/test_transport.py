import pytest
from mock import Mock, call


@pytest.fixture
def node():
    from zechat.node import Node
    return Node()


def mock_ws(client_id):
    ws = Mock(id=client_id)
    ws.out = []
    ws.send.side_effect = ws.out.append
    return ws


def communicate(node, ws, incoming):
    ws.receive.side_effect = incoming + [None]
    node.handle_transport(ws)
    return ws.out


def test_roundtrip(node):
    out = communicate(node, mock_ws('one'), ['foo', 'bar'])
    assert out == ['foo', 'bar']


def test_peer_receives_messages(node):
    peer_ws = mock_ws('two')
    with node.register_client(peer_ws):
        communicate(node, mock_ws('one'), ['foo', 'bar'])

    assert peer_ws.out == ['foo', 'bar']
