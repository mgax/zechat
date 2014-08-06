class zc.Threads extends zc.Controller

  initialize: ->
    @app.commands.setHandler 'open-conversation', @openConversation.bind(@)

  openConversation: (peer) ->
    conversation = new zc.Conversation(app: @app, peer: peer)
    @app.commands.execute('show-main', conversation.layout)
    conversation.render()
