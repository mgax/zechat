class zc.ThreadLayout extends Backbone.Marionette.LayoutView

  className: 'thread-container tall'

  template: 'thread.html'

  regions:
    history: '.thread-history'
    compose: '.thread-compose'


class zc.MessageView extends Backbone.Marionette.ItemView

  template: 'message.html'


class zc.HistoryView extends Backbone.Marionette.CollectionView

  childView: zc.MessageView


class zc.History extends zc.Controller

  createView: ->
    return new zc.HistoryView
      collection: @options.collection


class zc.ComposeView extends Backbone.Marionette.ItemView

  tagName: 'form'

  template: 'compose.html'

  ui:
    message: '[name=message]'

  events:
    'submit': (evt) ->
      evt.preventDefault()
      message = @ui.message.val()
      @ui.message.val("")
      if message
        this.trigger('send', message)


class zc.Compose extends zc.Controller

  createView: ->
    view = new zc.ComposeView
    view.on('send', @send)
    return view

  send: (text) =>
    message = {
      text: text
      time: zc.utcnow_iso()
      sender: @app.request('identity').get('fingerprint')
    }
    @app.request('client').send(@options.peer.get('fingerprint'), message)


class zc.Thread extends zc.Controller

  initialize: ->
    @peer = @options.peer
    @layout = new zc.ThreadLayout
    @history = new zc.History(app: @app, collection: @peer.message_col)
    @compose = new zc.Compose(app: @app, peer: @peer)

  render: ->
    @layout.render()
    @layout.history.show(@history.createView())
    @layout.compose.show(@compose.createView())
