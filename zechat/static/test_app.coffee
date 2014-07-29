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

  it 'should receive a message', ->
    app = new Backbone.Marionette.Application
    message_col = new Backbone.Collection
    app.reqres.setHandler 'message_col', -> message_col
    receiver = new zc.Receiver(app: app)
    app.vent.trigger('message', text: 'one')
    app.vent.trigger('message', text: 'two')
    expect(message_col.toJSON()).toEqual([{text: 'one'}, {text: 'two'}])
