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

  it 'should store messages in the right collection', ->
    app = new Backbone.Marionette.Application
    message_manager = new zc.MessageManager(app: app)
    receiver = new zc.Receiver(app: app)

    app.vent.trigger('message', sender: 'a', text: 'one')
    app.vent.trigger('message', sender: 'b', text: 'two')
    app.vent.trigger('message', sender: 'b', text: 'three')

    expect(app.request('message_collection', 'a').toJSON()).toEqual([
      {sender: 'a', text: 'one'}
    ])

    expect(app.request('message_collection', 'b').toJSON()).toEqual([
      {sender: 'b', text: 'two'}
      {sender: 'b', text: 'three'}
    ])
