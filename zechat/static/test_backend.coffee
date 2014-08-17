describe 'backend', ->

  FIX = zc.fixtures

  beforeEach (done) ->
    $.post(zc.TESTING_URL_MAP.flush, -> done())

  it 'should save and load data', (test_done) ->
    zc.create_testing_app(secret: FIX.A_KEY)

    .then (app) =>
      @backend = app.request('backend')
      @backend.save('hello world')

    .then =>
      @backend.load()

    .then (state) =>
      expect(state).toEqual('hello world')

    .done =>
      test_done()
