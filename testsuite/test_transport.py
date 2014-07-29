from mock import Mock, call


def test_roundtrip():
    from zechat.node import transport

    ws = Mock(id='one')
    ws.receive.side_effect = ['foo', 'bar', None]

    transport(ws)

    assert ws.send.call_args_list == [call('foo'), call('bar')]
