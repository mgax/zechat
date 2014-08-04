zc.waitfor = (timeout, check) ->
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

  interval = setInterval(poll, 100)

  return deferred.promise


describe 'conversation', ->

  # TODO don't touch browser's localstorage

  it 'should send a message and receive it back', (done) ->
    $app = $('<div>')
    app = zc.create_app(
      urls: zc.TESTING_URL_MAP
      el: $app[0]
    )

    zc.waitfor(1000, -> $app.find('.conversation-compose').length or null)
    .then ->
      $form = $app.find('.conversation-compose form')
      $form.find('[name=message]').val('hello world')
      $form.submit()

      get_messages = ->
        $history = $app.find('.conversation-history')
        messages = $history.find('.message-text').text()
        return messages if messages.length > 0

      return zc.waitfor(2000, get_messages)
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
