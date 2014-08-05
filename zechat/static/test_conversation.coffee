describe 'conversation', ->

  FIX = zc.fixtures

  beforeEach (done) ->
    $.post(zc.TESTING_URL_MAP.flush, -> done())

  it 'should generate a new identity', (test_done) ->
    local_storage = new zc.MockLocalStorage()
    zc.create_app(
      urls: zc.TESTING_URL_MAP
      el: $('<div>')[0]
      local_storage: local_storage
    )
    .then (app) =>
      identity = JSON.parse(local_storage.getItem('identity'))
      expect(identity.fingerprint.length).toEqual(32)
    .finally ->
      test_done()
    .done()

  it 'should post identity to server', (test_done) ->
    identity_json = JSON.stringify(
      key: FIX.PRIVATE_KEY
      fingerprint: FIX.FINGERPRINT
    )

    $app = $('<div>')
    zc.create_app(
      urls: zc.TESTING_URL_MAP
      el: $app[0]
      local_storage: new zc.MockLocalStorage(identity: identity_json)
    )
    .then (app) =>
      identity = app.request('identity')
      $app.find('.header-btn-myid').click()
      $app.find('.myid-publish').click()
      return zc.waitfor(-> identity.get('public_url'))
    .then (public_url) =>
      expect(public_url).toContain('/id/' + FIX.FINGERPRINT)
    .finally ->
      test_done()
    .done()

  it 'should send a message and receive it back', (test_done) ->
    identity_json = JSON.stringify(key: FIX.PRIVATE_KEY)

    $app = $('<div>')
    zc.create_app(
      urls: zc.TESTING_URL_MAP
      el: $app[0]
      local_storage: new zc.MockLocalStorage(identity: identity_json)
    )
    .then (app) =>
      @app = app
      zc.waitfor(-> zc.some($app.find('.conversation-compose')))
    .then =>
      $form = $app.find('.conversation-compose form')
      $form.find('[name=message]').val('hello world')
      $form.submit()

      get_messages = ->
        $history = $app.find('.conversation-history')
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
