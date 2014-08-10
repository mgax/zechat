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


class zc.Thread extends zc.Controller

  initialize: ->
    @peer = @options.peer

  createHistoryView: ->
    return new zc.HistoryView(collection: @peer.message_col)

  createComposeView: ->
    view = new zc.ComposeView()
    view.on('send', @send)
    return view

  send: (text) =>
    message = {
      text: text
      time: zc.utcnow_iso()
      sender: @app.request('identity').get('fingerprint')
    }
    @app.request('client').send(@peer, message)

  show: ->
    layout = new zc.ThreadLayout()
    @app.commands.execute('show-main', layout)
    layout.render()
    layout.history.show(@createHistoryView())
    layout.compose.show(@createComposeView())
