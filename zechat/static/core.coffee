zc.utcnow_iso = ->
  (new Date()).toJSON()


class zc.AppLayout extends Backbone.Marionette.LayoutView

  template: '#app-layout-html'

  regions:
    contacts: '.app-contacts'
    main: '.app-main'


class zc.Transport extends Backbone.Marionette.Controller

  initialize: (options) ->
    @options.app.vent.on('start', _.bind(@connect, @))

  connect: ->
    transport_url = @options.app.request('urls')['transport']
    @ws = new WebSocket(transport_url)
    @ws.onmessage = _.bind(@on_message, @)

  on_message: (evt) ->
    @trigger('message', JSON.parse(evt.data))

  send: (data) ->
    @ws.send(JSON.stringify(data))


class zc.Persist extends Backbone.Marionette.Controller

  initialize: ->
    @key = @options.key
    @model = @options.model
    value = localStorage.getItem(@key)
    if value
      @model.set(JSON.parse(value))
    @model.on('change', _.bind(@save, @))

  save: ->
    localStorage.setItem(@key, JSON.stringify(@model))


zc.modules.core = ->
  @models =
    identity: new Backbone.Model
      fingerprint: 'foo'
    message_col: new Backbone.Collection

  @persist_identity = new zc.Persist
    key: 'identity'
    model: @models.identity

  zc.set_identity = (fingerprint) =>
    @models.identity.set('fingerprint', fingerprint)

  @app.reqres.setHandler 'identity', => @models.identity
  @app.reqres.setHandler 'message_col', => @models.message_col

  @transport = new zc.Transport(app: @app)

  @transport.on 'message', (data) =>
    @models.message_col.add(data)

  @app.commands.setHandler 'send-message', (data) =>
    @transport.send(data)

  @app.commands.setHandler 'show-main', (view) =>
    @layout.main.show(view)

  @app.vent.on 'start', =>
    @layout = new zc.AppLayout(el: @app.request('root_el'))
    @layout.render()
