zc.setup_identity = (app) ->
  model = app.request('identity').model

  unless model.get('secret')
    model.set(secret: zc.curve.random_secret())

  return Q()


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
    return zc.curve.derive_key(@model.get('secret'))

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
