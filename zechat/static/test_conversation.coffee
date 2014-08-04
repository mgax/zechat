zc.waitfor = (check, timeout=1000) ->
  t0 = _.now()
  deferred = Q.defer()

  poll = ->
    dt = _.now() - t0
    if dt > timeout
      clearInterval(interval)
      deferred.reject('timeout')
    else

    rv = check()
    if rv?
      clearInterval(interval)
      deferred.resolve(rv)

  interval = setInterval(poll, 50)

  return deferred.promise


zc.some = ($qs) ->
  return $qs if $qs.length > 0


class zc.MockLocalStorage

  constructor: -> @_data = {}

  getItem: (key) -> @_data[key]

  setItem: (key, value) -> @_data[key] = value


describe 'conversation', ->

  it 'should send a message and receive it back', (done) ->
    $app = $('<div>')
    app = zc.create_app(
      urls: zc.TESTING_URL_MAP
      el: $app[0]
      local_storage: new zc.MockLocalStorage()
    )

    zc.waitfor(-> zc.some($app.find('.conversation-compose')))
    .then ->
      $form = $app.find('.conversation-compose form')
      $form.find('[name=message]').val('hello world')
      $form.submit()

      get_messages = ->
        $history = $app.find('.conversation-history')
        messages = $history.find('.message-text').text()
        return messages if messages.length > 0

      return zc.waitfor(get_messages, 3000)
    .then (messages) ->
      expect(messages).toEqual("hello world")
    .catch (err) ->
      if err == 'timeout'
        expect('timed out').toBe(false)
        return
      throw(err)
    .finally ->
      zc.remove_handlers(app)
      done()
