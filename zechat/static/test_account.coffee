describe 'account', ->

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

