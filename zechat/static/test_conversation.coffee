zc.waitfor = (timeout, check) ->
  t0 = _.now()
  deferred = Q.defer()

  poll = ->
    rv = check()
    if rv?
      clearInterval(interval)
      deferred.resolve(rv)

    else if _.now() - t0 > timeout
      clearInterval(interval)
      deferred.reject('timeout')

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

    other = ->
      $form = $app.find('.conversation-compose form')
      $form.find('[name=message]').val('hello world')
      $form.submit()

      get_messages = ->
        $history = $app.find('.conversation-history')
        messages = $history.find('.message-text').text()
        return messages if messages.length > 0

      zc.waitfor(2, get_messages)
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

    setTimeout(other, 100)
