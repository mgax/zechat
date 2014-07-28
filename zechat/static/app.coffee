zc = window.zc = {}


class zc.Peer

  constructor: (options) ->
    @fingerprint = options.fingerprint


class zc.Identity

  constructor: (options) ->
    @server = options.server

  send: (options) ->
    @server.send(
      text: options.text
      recipient: options.recipient.fingerprint
    )


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


class zc.ComposeView extends Backbone.Marionette.ItemView

  tagName: 'form'

  template: '#compose-html'


class zc.Compose extends Backbone.Marionette.Controller

  createView: ->
    return new zc.ComposeView


zc.initialize = (options) ->
  zc.app = new Backbone.Marionette.Application

  zc.app.layout = new zc.AppLayout
    el: $('body')

  zc.app.layout.render()

  zc.app.module 'conversation', ->
    @layout = new zc.ConversationLayout
    @layout.render()
    zc.app.layout.main.show(@layout)

    @compose = new zc.Compose
      app: @app
    @layout.compose.show(@compose.createView())
