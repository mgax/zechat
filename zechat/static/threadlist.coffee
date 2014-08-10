class zc.ThreadlistItemView extends Backbone.Marionette.ItemView

  className: 'threadlist-item'
  template: 'threadlist_item.html'

  events:
    'click .threadlist-link': (evt) ->
      evt.preventDefault()
      @trigger('click', @model.get('fingerprint'))


class zc.ThreadlistView extends Backbone.Marionette.CollectionView

  className: 'threadlist'
  childView: zc.ThreadlistItemView


class zc.ThreadModel extends Backbone.Model

  idAttribute: 'fingerprint'

  initialize: ->
    @message_col = new Backbone.Collection()


class zc.Threadlist extends zc.Controller

  initialize: ->
    @peer_col = @options.peer_col
    @app.commands.setHandler 'open-thread', @openThread
    @app.reqres.setHandler 'peer', @get_peer

  get_peer: (fingerprint) =>
    unless @peer_col.get(fingerprint)?
      @peer_col.add(new zc.ThreadModel(fingerprint: fingerprint))
    return @peer_col.get(fingerprint)

  openThread: (fingerprint) =>
    thread = new zc.Thread(app: @app, peer: @get_peer(fingerprint))
    @app.commands.execute('show-main', thread.layout)
    thread.render()

  createView: ->
    view = new zc.ThreadlistView(collection: @peer_col)
    view.on 'childview:click', (view, fingerprint) =>
      @openThread(fingerprint)
    return view
