zc.generate_secret = (email, passphrase) ->
  return zc.scrypt(email + ':' + passphrase)


zc.setup_identity = (app) ->
  deferred = Q.defer()

  login_view = new zc.LoginView()
  app.commands.execute('show-main', login_view)

  login_view.on 'login', (data) ->
    model = app.request('identity').model
    model.set(secret: zc.generate_secret(data.email, data.passphrase))
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


class zc.CreateAccoutView extends Backbone.Marionette.ItemView

  tagName: 'form'
  className: 'createaccount'
  template: 'createaccount.html'

  onShow: ->
    @$el.find('[name=email]').focus()

  events:
    'submit': (evt) ->
      evt.preventDefault()
      data = zc.serialize_form(@el)
      @trigger('submit', data)


zc.create_account = (app) ->
  deferred = Q.defer()

  createaccount_view = new zc.CreateAccoutView(model: new Backbone.Model())
  app.commands.execute('show-main', createaccount_view)

  createaccount_view.on 'submit', (data) ->
    if data.passphrase != data.passphrase_confirm
      createaccount_view.model.set(password_mismatch: true)
      createaccount_view.render()
      createaccount_view.onShow()
      return

    secret = zc.generate_secret(data.email, data.passphrase)
    model = app.request('identity').model
    model.set(secret: secret)

    app.request('backend').save('{}')

    .done ->
      home = app.request('urls').home
      history.pushState(null, "ZeChat", home)
      deferred.resolve()


  return deferred.promise


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
