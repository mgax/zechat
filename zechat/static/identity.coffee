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
  template: '#myid-html'


class zc.Identity extends Backbone.Marionette.Controller

  createView: ->
    model = @options.app.request('identity')
    return new zc.IdentityView(model: model)
