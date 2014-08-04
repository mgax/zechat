zc.wait_for = (options) ->
  t0 = _.now()

  poll = ->
    if options.check()
      clearInterval(interval)
      options.success()

    else if _.now() - t0 > options.timeout
      clearInterval(interval)
      options.failure()

  interval = setInterval(poll, 100)


describe 'conversation', ->

  # TODO don't touch browser's localstorage
  # TODO use temporary node instance on the server

  it 'should send a message and receive it back', (done) ->
    $app = $('<div>')
    app = zc.create_app(
      urls: {post_identity: '/id/', transport: 'ws://zechat.devel/ws/transport'}
      el: $app[0]
    )

    other = ->
      $form = $app.find('.conversation-compose form')
      $form.find('[name=message]').val('hello world')
      $form.submit()

      messages = ->
        $app.find('.conversation-history').find('.message-text').text()

      zc.wait_for(
        check: -> messages() != ''
        timeout: 2
        success: -> expect(messages()).toEqual("hello world"); test_done()
        failure: -> expect('timed out').toBe(false); test_done()
      )

    test_done = ->
      zc.remove_handlers(app)
      done()

    setTimeout(other, 100)
