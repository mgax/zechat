describe 'message sending', ->

  it 'should send the message', ->
    now = zc.utcnow_iso()
    spyOn(zc, 'utcnow_iso').and.returnValue(now)
    app = new Backbone.Marionette.Application
    send_message = jasmine.createSpy('send_message')
    app.commands.setHandler('send-message', send_message)
    compose = new zc.Compose(app: app)

    compose.send('hello world')

    expect(send_message).toHaveBeenCalledWith
      text: 'hello world'
      time: now
