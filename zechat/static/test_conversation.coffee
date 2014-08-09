describe 'conversation', ->

  FIX = zc.fixtures

  create_testing_app = (local_storage_data={}, options={}) ->
    _.defaults(options, {
      urls: zc.TESTING_URL_MAP
      el: $('<div>')[0]
      local_storage: new zc.MockLocalStorage(local_storage_data)
    })
    zc.create_app(options)

  beforeEach (done) ->
    $.post(zc.TESTING_URL_MAP.flush, -> done())

  it 'should generate a new identity', (test_done) ->
    local_storage = new zc.MockLocalStorage()
    create_testing_app({}, {local_storage: local_storage})
    .then (app) =>
      identity = JSON.parse(local_storage.getItem('identity'))
      expect(identity.fingerprint.length).toEqual(40)
    .finally ->
      test_done()
    .done()

  it 'should post identity to server', (test_done) ->
    identity_json = JSON.stringify(
      key: FIX.PRIVATE_KEY
      fingerprint: FIX.FINGERPRINT
    )

    create_testing_app(identity: identity_json)
    .then (app) =>
      identity = app.request('identity')
      app.$el.find('.header-btn-myid').click()
      app.$el.find('.myid-publish').click()
      return zc.waitfor(-> identity.get('public_url'))
    .then (public_url) =>
      expect(public_url).toContain('/id/' + FIX.FINGERPRINT)
    .finally ->
      test_done()
    .done()

  it 'should begin a new conversation', (test_done) ->
    identity_a_json = JSON.stringify(
        key: FIX.PRIVATE_KEY
        fingerprint: FIX.FINGERPRINT)
    identity_b_json = JSON.stringify(
        key: FIX.PRIVATE_KEY_B
        fingerprint: FIX.FINGERPRINT_B)

    Q.all([
      create_testing_app({identity: identity_a_json}, {channel: 'app_a'})
      create_testing_app({identity: identity_b_json}, {channel: 'app_b'})
    ])

    .then ([@app_a, @app_b]) =>
      (new zc.Identity(app: @app_b)).publish()

    .then (url_b) =>
      @app_a.$el.find('.header-btn-add-contact').click()
      $form_a = @app_a.$el.find('.app-main > form')
      $form_a.find('[name=url]').val(url_b)
      $form_a.submit()
      zc.waitfor(=> zc.some(@app_a.$el.find('.threadlist')))

    .then ($threadlist) =>
      expect($threadlist.text().trim()).toEqual(FIX.FINGERPRINT_B)
      zc.waitfor(=> zc.some(@app_a.$el.find('.thread-compose form')))

    .then ($form) =>
      $form.find('[name=message]').val("hello from A")
      $form.submit()
      thread = @app_b.request('thread', FIX.FINGERPRINT)
      zc.waitfor(-> zc.some(thread.message_col))

    .then (messages_from_a) =>
      $threadlist_b = @app_b.$el.find('.threadlist')
      expect($threadlist_b.text().trim()).toEqual(FIX.FINGERPRINT)
      expect(messages_from_a.at(0).get('text')).toEqual("hello from A")

    .catch (err) =>
      throw(err) if err != 'timeout'
      expect('timed out').toBe(false)

    .finally ->
      test_done()

    .done()

  it 'should send a message and receive it back', (test_done) ->
    identity_json = JSON.stringify(
      key: FIX.PRIVATE_KEY
      fingerprint: FIX.FINGERPRINT
    )

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

    .finally =>
      test_done()

    .done()

  it 'should read offline messages', (test_done) ->
    sender_app = new Backbone.Marionette.Application
    sender_identity = new Backbone.Model(
      key: FIX.PRIVATE_KEY_B
      fingerprint: FIX.FINGERPRINT_B
    )
    sender_app.reqres.setHandler('identity', -> sender_identity)
    sender_app.reqres.setHandler('urls', -> zc.TESTING_URL_MAP)
    sender_transport = new zc.Transport(app: sender_app)
    sender_transport.connect()

    zc.waitfor(=> sender_transport.model.get('state') == 'open')

    .then =>
      sender_transport.send(
        recipient: FIX.FINGERPRINT
        message: {text: "hello offline", sender: FIX.FINGERPRINT_B}
        type: 'message'
      )

    .then =>
      identity_json = JSON.stringify(
        key: FIX.PRIVATE_KEY
        fingerprint: FIX.FINGERPRINT
      )
      create_testing_app(identity: identity_json)

    .then (@app) =>
      get_messages = =>
        message_col = @app.request('thread', FIX.FINGERPRINT_B).message_col
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

    .finally =>
      test_done()

    .done()
