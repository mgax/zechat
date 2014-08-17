describe 'account', ->

  FIX = zc.fixtures

  beforeEach (done) ->
    $.post(zc.TESTING_URL_MAP.flush, -> done())


  it 'should create a new account', (test_done) ->
    spyOn(window.history, 'pushState')

    app = zc.create_app(
      create_account: true
      urls: zc.TESTING_URL_MAP
      el: $('<div>')[0]
      transport: false
    )

    zc.waitfor(=> zc.some(app.$el.find('form.createaccount')))
    .then ($form) =>
      $form.find('[name=email]').val('foo@example.com')
      $form.find('[name=passphrase]').val('testing one two three')
      $form.submit()

      zc.waitfor(=> zc.some(app.$el.find('.has-error .help-block')))

    .done (msg) =>
      expect(msg.text()).toEqual("passwords don't match")

      $form = app.$el.find('form.createaccount')
      $form.find('[name=email]').val('foo@example.com')
      $form.find('[name=passphrase]').val('testing one two three')
      $form.find('[name=passphrase_confirm]').val('testing one two three')
      $form.submit()

    app.ready
    .done (app) ->
      expect(window.history.pushState).toHaveBeenCalled()
      secret = app.request('identity').model.get('secret')
      expect(secret).toEqual('sk:WHls/a+QF+0YYLorUzLFRmE4l3bcndjJ2oStx6zeGp8=')
      app.stop()
      test_done()


  it 'should prompt for email and password', (test_done) ->
    app = zc.create_app(
      urls: zc.TESTING_URL_MAP
      el: $('<div>')[0]
      transport: false
    )

    zc.waitfor(=> zc.some(app.$el.find('form.login')))
    .done ($form) =>
      $form.find('[name=email]').val('foo@example.com')
      $form.find('[name=passphrase]').val('testing one two three')
      $form.submit()

    app.ready
    .done (app) ->
      secret = app.request('identity').model.get('secret')
      expect(secret).toEqual('sk:WHls/a+QF+0YYLorUzLFRmE4l3bcndjJ2oStx6zeGp8=')
      app.stop()
      test_done()
