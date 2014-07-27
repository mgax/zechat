describe 'identity', ->

  it 'should send message', ->
    server = jasmine.createSpyObj('server', ['send'])
    recipient = new zc.Peer(fingerprint: "bar")
    identity = new zc.Identity(server: server)

    identity.send(recipient: recipient, text: "hello friend")

    expect(server.send).toHaveBeenCalledWith
      text: "hello friend"
      recipient: "bar"
