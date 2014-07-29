zc = window.zc = {}


zc.utcnow_iso = ->
  (new Date()).toJSON()


class zc.AppLayout extends Backbone.Marionette.LayoutView

  template: '#app-layout-html'

  regions:
    contacts: '.app-contacts'
    main: '.app-main'


class zc.ConversationLayout extends Backbone.Marionette.LayoutView

  className: 'conversation-container'

  template: '#conversation-layout-html'

  regions:
    history: '.conversation-history'
    compose: '.conversation-compose'


class zc.MessageView extends Backbone.Marionette.ItemView

  template: '#message-html'


class zc.HistoryView extends Backbone.Marionette.CollectionView

  childView: zc.MessageView


class zc.History extends Backbone.Marionette.Controller

  createView: ->
    return new zc.HistoryView
      collection: @options.app.request('message_col')


class zc.ComposeView extends Backbone.Marionette.ItemView

  tagName: 'form'

  template: '#compose-html'

  ui:
    message: '[name=message]'

  events:
    'submit': (evt) ->
      evt.preventDefault()
      message = @ui.message.val()
      @ui.message.val("")
      this.trigger('send', message)


class zc.Compose extends Backbone.Marionette.Controller

  createView: ->
    view = new zc.ComposeView
    view.on('send', _.bind(@send, @))
    return view

  send: (message) ->
    identity = @options.app.request('identity')
    data =
      text: message
      time: zc.utcnow_iso()
      sender: identity.get('fingerprint')
    @options.app.commands.execute('send-message', data)


class zc.Transport extends Backbone.Marionette.Controller

  initialize: (options) ->
    transport_url = @options.app.request('urls')['transport']
    @ws = new WebSocket(transport_url)
    @ws.onmessage = _.bind(@on_message, @)

  on_message: (evt) ->
    @trigger('message', JSON.parse(evt.data))

  send: (data) ->
    @ws.send(JSON.stringify(data))


zc.initialize = (options) ->
  app = zc.app = new Backbone.Marionette.Application

  app.identity = new Backbone.Model
    fingerprint: 'foo'
  app.message_col = new Backbone.Collection

  app.reqres.setHandler 'identity', -> app.identity
  app.reqres.setHandler 'message_col', -> app.message_col
  app.reqres.setHandler 'urls', -> options.urls

  app.transport = new zc.Transport(app: app)

  app.transport.on 'message', (data) =>
    app.message_col.add(data)

  app.commands.setHandler 'send-message', (data) ->
    app.transport.send(data)

  app.layout = new zc.AppLayout
    el: $('body')

  app.layout.render()

  app.module 'conversation', ->
    @layout = new zc.ConversationLayout
    @layout.render()
    @app.layout.main.show(@layout)

    @history = new zc.History(app: @app)
    @layout.history.show(@history.createView())

    @compose = new zc.Compose(app: @app)
    @layout.compose.show(@compose.createView())
