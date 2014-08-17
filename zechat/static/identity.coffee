zc.SCRYPT_DIFFICULTY = 16384
zc.SCRYPT_SALT = 'zechat'


zc.scrypt = (input_txt) ->
  scrypt = scrypt_module_factory()
  input = scrypt.encode_utf8(input_txt)
  salt = scrypt.encode_utf8(zc.SCRYPT_SALT)
  secret = scrypt.crypto_scrypt(input, salt, zc.SCRYPT_DIFFICULTY, 8, 1, 32)
  return zc.encode_secret_key(secret)


zc.setup_identity = (app) ->
  deferred = Q.defer()

  login_view = new zc.LoginView()
  app.commands.execute('show-main', login_view)

  login_view.on 'login', (data) ->
    input_txt = data.email + ':' + data.passphrase
    model = app.request('identity').model
    model.set(secret: zc.scrypt(input_txt))
    deferred.resolve()

  return deferred.promise


class zc.LoginView extends Backbone.Marionette.ItemView

  tagName: 'form'
  className: 'login'
  template: 'login.html'

  onShow: ->
    @$el.find('[name=email]').focus()

  events:
    'submit': (evt) ->
      evt.preventDefault()
      data = zc.serialize_form(@el)
      @trigger('login', data)


class zc.IdentityView extends Backbone.Marionette.ItemView

  className: 'myid-container tall'
  template: 'myid.html'

  events:
    'click .myid-delete': (evt) ->
      evt.preventDefault()
      @trigger('click-delete')


class zc.Identity extends zc.Controller

  initialize: ->
    @model = @options.model

  key: ->
    return @model.get('secret')

  pubkey: ->
    return zc.curve.derive_pubkey(@model.get('secret'))

  createView: ->
    view = new zc.IdentityView(model: new Backbone.Model(pubkey: @pubkey()))

    view.on 'click-delete', =>
      @model.clear()
      window.location.reload()

    return view

  authenticate: (transport) ->
    response = null

    rv = transport.send(type: 'challenge')

    .then (resp) =>
      transport.send(
        type: 'authenticate'
        pubkey: @pubkey()
        response: zc.curve.encrypt(resp.challenge, @key(), resp.pubkey)
      )

    .then (resp) =>
      throw "authentication failure" unless resp.success
      transport.send(
        type: 'subscribe'
        identity: @pubkey()
      )

    return rv
