describe 'conversation', ->

  FIX = zc.fixtures

  beforeEach (done) ->
    $.post(zc.TESTING_URL_MAP.flush, -> done())

  it 'should prompt for email and password', (test_done) ->
    $el = $('<div>')

    zc.waitfor(=> zc.some($el.find('form.login')))
    .done ($form) =>
      $form.find('[name=email]').val('foo@example.com')
      $form.find('[name=passphrase]').val('testing one two three')
      $form.submit()

    zc.create_app(urls: zc.TESTING_URL_MAP, el: $el[0]).ready
    .done (app) ->
      secret = app.request('identity').model.get('secret')
      expect(secret).toEqual('sk:WHls/a+QF+0YYLorUzLFRmE4l3bcndjJ2oStx6zeGp8=')
      test_done()

  it 'should begin a new conversation', (test_done) ->
    Q.all([
      zc.create_testing_app(channel: 'app_a', secret: FIX.A_KEY)
      zc.create_testing_app(channel: 'app_b', secret: FIX.B_KEY)
    ])

    .then ([@app_a, @app_b]) =>
      @app_a.$el.find('.header-btn-add-contact').click()
      $form_a = @app_a.$el.find('.app-main > form')
      $form_a.find('[name=peer]').val(FIX.B_PUBKEY)
      $form_a.submit()
      zc.waitfor(=> zc.some(@app_a.$el.find('.peerlist')))

    .then ($peerlist) =>
      expect($peerlist.text().trim()).toEqual(FIX.B_PUBKEY)
      zc.waitfor(=> zc.some(@app_a.$el.find('.thread-compose form')))

    .then ($form) =>
      $form.find('[name=message]').val("hello from A")
      $form.submit()
      peer = @app_b.request('peer', FIX.A_PUBKEY)
      zc.waitfor(-> zc.some(peer.message_col))

    .then (messages_from_a) =>
      $peerlist_b = @app_b.$el.find('.peerlist')
      expect($peerlist_b.text().trim()).toEqual(FIX.A_PUBKEY)
      expect(messages_from_a.at(0).get('text')).toEqual("hello from A")

    .catch (err) =>
      throw(err) if err != 'timeout'
      expect('timed out').toBe(false)

    .done ->
      test_done()

  it 'should send a message and receive it back', (test_done) ->
    zc.create_testing_app(talk_to_self: true, secret: FIX.A_KEY)

    .then (@app) =>
      zc.waitfor(=> zc.some(@app.$el.find('.thread-compose')))

    .then =>
      $form = @app.$el.find('.thread-compose form')
      $form.find('[name=message]').val('hello world')
      $form.submit()

      get_messages = =>
        $history = @app.$el.find('.thread-history')
        messages = $history.find('.message-text').text()
        return messages if messages.length > 0

      return zc.waitfor(get_messages, 3000)

    .then (messages) =>
      expect(messages).toEqual("hello world")

    .catch (err) =>
      if err == 'timeout'
        expect('timed out').toBe(false)
        return
      throw(err)

    .done =>
      test_done()

  it 'should read offline messages', (test_done) ->
    sender_app = new Backbone.Marionette.Application
    sender_identity = new Backbone.Model(secret: FIX.B_KEY)
    sender_app.reqres.setHandler('identity', -> sender_identity)
    sender_app.reqres.setHandler('urls', -> zc.TESTING_URL_MAP)

    new zc.Transport(app: sender_app).connect()

    .then (sender_transport) =>
      client = new zc.Client(
        app: sender_app
        transport: sender_transport
        identity: new zc.Identity(app: sender_app, model: sender_identity)
      )
      message = {text: "hello offline", sender: FIX.B_PUBKEY}
      peer = new Backbone.Model(pubkey: FIX.A_PUBKEY)
      client.send(peer, message)

    .then =>
      zc.create_testing_app(secret: FIX.A_KEY)

    .then (@app) =>
      get_messages = =>
        message_col = @app.request('peer', FIX.B_PUBKEY).message_col
        if message_col.length
          return message_col.at(0)

      return zc.waitfor(get_messages, 3000)

    .then (message) =>
      expect(message.get('text')).toEqual("hello offline")

    .catch (err) =>
      if err == 'timeout'
        expect('timed out').toBe(false)
        return
      throw(err)

    .done =>
      test_done()
