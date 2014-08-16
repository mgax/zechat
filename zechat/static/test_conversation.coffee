describe 'conversation', ->

  FIX = zc.fixtures

  create_testing_app = (local_storage_data={}, options={}) ->
    _.defaults(options, {
      urls: zc.TESTING_URL_MAP
      el: $('<div>')[0]
      local_storage: new zc.MockLocalStorage(local_storage_data)
    })

    app = null

    return (
      zc.create_app(options)

      .then (new_app) ->
        app = new_app
        zc.waitevent(app.request('client'), 'ready')

      .then ->
        return app
    )

  beforeEach (done) ->
    $.post(zc.TESTING_URL_MAP.flush, -> done())

  it 'should generate a new identity', (test_done) ->
    local_storage = new zc.MockLocalStorage()
    create_testing_app({}, {local_storage: local_storage})
    .then (app) =>
      pubkey = app.request('identity-controller').pubkey()
      expect(pubkey.length).toEqual(44)
    .done ->
      test_done()

  it 'should begin a new conversation', (test_done) ->
    identity_a_json = JSON.stringify(secret: FIX.SECRET_A)
    identity_b_json = JSON.stringify(secret: FIX.SECRET_B)

    Q.all([
      create_testing_app({identity: identity_a_json}, {channel: 'app_a'})
      create_testing_app({identity: identity_b_json}, {channel: 'app_b'})
    ])

    .then ([@app_a, @app_b]) =>
      @app_a.$el.find('.header-btn-add-contact').click()
      $form_a = @app_a.$el.find('.app-main > form')
      $form_a.find('[name=peer]').val(FIX.PUBKEY_B)
      $form_a.submit()
      zc.waitfor(=> zc.some(@app_a.$el.find('.peerlist')))

    .then ($peerlist) =>
      expect($peerlist.text().trim()).toEqual(FIX.PUBKEY_B)
      zc.waitfor(=> zc.some(@app_a.$el.find('.thread-compose form')))

    .then ($form) =>
      $form.find('[name=message]').val("hello from A")
      $form.submit()
      peer = @app_b.request('peer', FIX.PUBKEY_A)
      zc.waitfor(-> zc.some(peer.message_col))

    .then (messages_from_a) =>
      $peerlist_b = @app_b.$el.find('.peerlist')
      expect($peerlist_b.text().trim()).toEqual(FIX.PUBKEY_A)
      expect(messages_from_a.at(0).get('text')).toEqual("hello from A")

    .catch (err) =>
      throw(err) if err != 'timeout'
      expect('timed out').toBe(false)

    .done ->
      test_done()

  it 'should send a message and receive it back', (test_done) ->
    identity_json = JSON.stringify(secret: FIX.SECRET_A)

    create_testing_app({identity: identity_json}, {talk_to_self: true})

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
    sender_identity = new Backbone.Model(
      secret: FIX.SECRET_B
    )
    sender_app.reqres.setHandler('identity', -> sender_identity)
    sender_app.reqres.setHandler('urls', -> zc.TESTING_URL_MAP)

    new zc.Transport(app: sender_app).connect()

    .then (sender_transport) =>
      client = new zc.Client(
        app: sender_app
        transport: sender_transport
        identity: new zc.Identity(app: sender_app)
      )
      message = {text: "hello offline", sender: FIX.PUBKEY_B}
      peer = new Backbone.Model(fingerprint: FIX.PUBKEY_A)
      client.send(peer, message)

    .then =>
      identity_json = JSON.stringify(secret: FIX.SECRET_A)
      create_testing_app(identity: identity_json)

    .then (@app) =>
      get_messages = =>
        message_col = @app.request('peer', FIX.PUBKEY_B).message_col
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
