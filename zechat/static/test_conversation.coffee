describe 'conversation', ->

  FIX = zc.fixtures

  it 'should generate a new identity', (done) ->
    local_storage = new zc.MockLocalStorage()
    zc.create_app(
      urls: zc.TESTING_URL_MAP
      el: $('<div>')[0]
      local_storage: local_storage
    )
    .done (app) =>
      identity = JSON.parse(local_storage.getItem('identity'))
      expect(identity.fingerprint.length).toEqual(32)
      done()

  it 'should send a message and receive it back', (done) ->
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
      done()
