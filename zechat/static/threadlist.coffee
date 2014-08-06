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
    @app.commands.setHandler 'open-thread', @openThread.bind(@)

  openThread: (peer) ->
    unless @collection.get(peer)?
      @collection.add(new zc.ThreadModel(fingerprint: peer))
    thread_model = @collection.get(peer)

    thread = new zc.Thread(app: @app, peer: peer)
    @app.commands.execute('show-main', thread.layout)
    thread.render()

  createView: ->
    new zc.ThreadlistView(collection: @collection)
