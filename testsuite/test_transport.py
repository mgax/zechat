from mock import Mock, call


def run_transport(incoming, client_id='one'):
    from zechat.node import transport
    ws = Mock(id=client_id)
    ws.receive.side_effect = incoming + [None]
    transport(ws)
    return [c[0][0] for c in ws.send.call_args_list]


def test_roundtrip():
    assert run_transport(['foo', 'bar']) == ['foo', 'bar']


def test_peer_receives_messages():
    from zechat.node import client_map

    peer_ws = Mock(id='two')
    client_map[peer_ws.id] = peer_ws
    try:
        run_transport(['foo', 'bar'])
    finally:
        del client_map[peer_ws.id]

    peer_out = [c[0][0] for c in peer_ws.send.call_args_list]

    assert peer_out == ['foo', 'bar']
