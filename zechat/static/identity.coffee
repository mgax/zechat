zc.setup_identity = (app) ->
  model = app.request('identity')

  if model.get('secret')
    return Q()

  else
    key = null

    return (
      zc.generate_key(1024)

      .then (new_key) ->
        key = new_key
        fingerprint = new zc.Crypto(key).fingerprint()
        secret = zc.curve.random_secret()
        model.set(key: key, fingerprint: fingerprint, secret: secret)
        return
    )


class zc.IdentityView extends Backbone.Marionette.ItemView

  className: 'myid-container tall'
  template: 'myid.html'

  events:
    'click .myid-delete': (evt) ->
      evt.preventDefault()
      @trigger('click-delete')


class zc.Identity extends zc.Controller

  initialize: ->
    @model = @app.request('identity')

  fingerprint: ->
    return @model.get('fingerprint')

  key: ->
    return zc.curve.derive_key(@model.get('secret'))

  pubkey: ->
    return zc.curve.derive_pubkey(@model.get('secret'))

  public_key: ->
    return zc.get_public_key(@model.get('key'))

  crypto: ->
    return new zc.Crypto(@model.get('key'))

  createView: ->
    view = new zc.IdentityView(model: @model)

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
        fingerprint: @fingerprint()
        pubkey: @pubkey()
        response: zc.curve.encrypt(resp.challenge, @key(), resp.pubkey)
      )

    .then (resp) =>
      throw "authentication failure" unless resp.success
      transport.send(
        type: 'subscribe'
        identity: @fingerprint()
      )

    return rv
