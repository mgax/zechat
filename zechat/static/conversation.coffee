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


class zc.Conversation extends Backbone.Marionette.Controller

  initialize: ->
    @layout = new zc.ConversationLayout
    @history = new zc.History(app: @options.app)
    @compose = new zc.Compose(app: @options.app)

  render: ->
    @layout.render()
    @layout.history.show(@history.createView())
    @layout.compose.show(@compose.createView())


zc.modules.conversation = ->
  @app.commands.setHandler 'open-conversation', =>
    conversation = new zc.Conversation(app: @app)
    @app.commands.execute('show-main', conversation.layout)
    conversation.render()
