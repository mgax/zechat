from mock import Mock, call


def run_transport(incoming, client_id='one'):
    from zechat.node import transport
    ws = Mock(id=client_id)
    ws.receive.side_effect = incoming + [None]
    transport(ws)
    return [c[0][0] for c in ws.send.call_args_list]


def test_roundtrip():
    assert run_transport(['foo', 'bar']) == ['foo', 'bar']
