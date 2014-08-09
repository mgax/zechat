zc.setup_identity = (app) ->
  deferred = Q.defer()
  model = app.request('identity')

  if model.get('key')
    deferred.resolve(model.get('fingerprint'))

  else
    zc.generate_key 1024, (key) ->
      new zc.Crypto(key).fingerprint (fingerprint) ->
        model.set(key: key, fingerprint: fingerprint)
        deferred.resolve(model.get('fingerprint'))

  return deferred.promise


class zc.IdentityView extends Backbone.Marionette.ItemView

  className: 'myid-container tall'
  template: 'myid.html'

  events:
    'click .myid-publish': (evt) ->
      evt.preventDefault()
      @trigger('click-publish')

    'click .myid-delete': (evt) ->
      evt.preventDefault()
      @trigger('click-delete')


class zc.Identity extends zc.Controller

  initialize: ->
    @model = @app.request('identity')

  createView: ->
    view = new zc.IdentityView(model: @model)

    view.on 'click-publish', =>
      @publish()
      .done ->
        view.render()

    view.on 'click-delete', =>
      @model.clear()
      window.location.reload()

    return view

  publish: ->
    url = @app.request('urls').post_identity
    data = {
      fingerprint: @model.get('fingerprint')
      public_key: zc.get_public_key(@model.get('key'))
    }

    return (
      Q(zc.post_json url, data)

      .then (resp) =>
        @model.set('public_url', resp.url)
        return resp.url
    )
