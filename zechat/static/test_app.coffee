describe 'message sending', ->

  it 'should send the message', ->
    now = zc.utcnow_iso()
    spyOn(zc, 'utcnow_iso').and.returnValue(now)
    app = new Backbone.Marionette.Application
    identity = new Backbone.Model(fingerprint: 'myself')
    app.reqres.setHandler 'identity', -> identity
    send_message = jasmine.createSpy('send_message')
    app.commands.setHandler('send-message', send_message)
    compose = new zc.Compose(app: app, peer: 'friend')

    compose.send('hello world')

    expect(send_message).toHaveBeenCalledWith
      text: 'hello world'
      time: now
      sender: 'myself'
      recipient: 'friend'
