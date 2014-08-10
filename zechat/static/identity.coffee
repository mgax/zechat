zc.setup_identity = (app) ->
  model = app.request('identity')

  if model.get('key')
    return Q(model.get('fingerprint'))

  else
    key = null

    return (
      zc.generate_key(1024)

      .then (new_key) ->
        key = new_key
        new zc.Crypto(key).fingerprint()

      .then (fingerprint) ->
        model.set(key: key, fingerprint: fingerprint)
        return fingerprint
    )


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
    @app.vent.on('message', _.bind(@on_message, @))

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

  on_message: (message) ->
    thread = @app.request('thread', message.sender)
    thread.message_col.add(message)
