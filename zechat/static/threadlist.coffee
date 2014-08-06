class zc.ThreadlistItemView extends Backbone.Marionette.ItemView

  className: 'threadlist-item'
  template: 'threadlist_item.html'


class zc.ThreadlistView extends Backbone.Marionette.CollectionView

  className: 'threadlist'
  childView: zc.ThreadlistItemView


class zc.ThreadModel extends Backbone.Model

  idAttribute: 'fingerprint'


class zc.Threadlist extends zc.Controller

  initialize: ->
    @collection = @app.request('threadlist')
    @app.commands.setHandler 'open-conversation', @openConversation.bind(@)

  openConversation: (peer) ->
    unless @collection.get(peer)?
      @collection.add(new zc.ThreadModel(fingerprint: peer))
    conversation_model = @collection.get(peer)

    conversation = new zc.Conversation(app: @app, peer: peer)
    @app.commands.execute('show-main', conversation.layout)
    conversation.render()

  createView: ->
    new zc.ThreadlistView(collection: @collection)
