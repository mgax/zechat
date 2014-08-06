class zc.ThreadlistItemView extends Backbone.Marionette.ItemView

  className: 'threadlist-item'
  template: 'threadlist_item.html'


class zc.ThreadlistView extends Backbone.Marionette.CollectionView

  className: 'threadlist'
  childView: zc.ThreadlistItemView


class zc.ThreadModel extends Backbone.Model

  idAttribute: 'fingerprint'

  initialize: ->
    @message_col = new Backbone.Collection()


class zc.Threadlist extends zc.Controller

  initialize: ->
    @collection = @app.request('threadlist')
    @app.commands.setHandler 'open-thread', @openThread.bind(@)
    @app.reqres.setHandler 'thread', @getThread.bind(@)

  getThread: (fingerprint) ->
    unless @collection.get(fingerprint)?
      @collection.add(new zc.ThreadModel(fingerprint: fingerprint))
    return @collection.get(fingerprint)

  openThread: (peer) ->
    @getThread(peer)
    thread = new zc.Thread(app: @app, peer: peer)
    @app.commands.execute('show-main', thread.layout)
    thread.render()

  createView: ->
    new zc.ThreadlistView(collection: @collection)
