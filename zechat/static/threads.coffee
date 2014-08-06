class zc.ThreadsItemView extends Backbone.Marionette.ItemView

  className: 'threads-item'
  template: 'threads_item.html'


class zc.ThreadsView extends Backbone.Marionette.CollectionView

  className: 'threads'
  childView: zc.ThreadsItemView


class zc.ThreadModel extends Backbone.Model

  idAttribute: 'fingerprint'


class zc.Threads extends zc.Controller

  initialize: ->
    @collection = @app.request('threads')
    @app.commands.setHandler 'open-conversation', @openConversation.bind(@)

  openConversation: (peer) ->
    unless @collection.get(peer)?
      @collection.add(new zc.ThreadModel(fingerprint: peer))
    conversation_model = @collection.get(peer)

    conversation = new zc.Conversation(app: @app, peer: peer)
    @app.commands.execute('show-main', conversation.layout)
    conversation.render()

  createView: ->
    new zc.ThreadsView(collection: @collection)
