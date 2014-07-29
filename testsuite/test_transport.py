import pytest
from mock import Mock, call


@pytest.fixture
def node():
    from zechat.node import Node
    return Node()


def run_transport(node, incoming, client_id='one'):
    ws = Mock(id=client_id)
    ws.receive.side_effect = incoming + [None]
    node.handle_transport(ws)
    return [c[0][0] for c in ws.send.call_args_list]


def test_roundtrip(node):
    assert run_transport(node, ['foo', 'bar']) == ['foo', 'bar']


def test_peer_receives_messages(node):
    client_map = node.client_map

    peer_ws = Mock(id='two')
    client_map[peer_ws.id] = peer_ws
    try:
        run_transport(node, ['foo', 'bar'])
    finally:
        del client_map[peer_ws.id]

    peer_out = [c[0][0] for c in peer_ws.send.call_args_list]

    assert peer_out == ['foo', 'bar']
