class zc.AddContactView extends Backbone.Marionette.ItemView

  tagName: 'form'
  template: 'add_contact.html'

  ui:
    url: '[name=url]'

  events:
    'submit': (evt) ->
      evt.preventDefault()
      url = @ui.url.val()
      if url
        this.trigger('add', url)

  onShow: ->
    @ui.url.focus()


class zc.AddContact extends zc.Controller

  createView: ->
    view = new zc.AddContactView()

    view.on 'add', (url) =>
      Q($.get(url)).done (resp) =>
        @app.commands.execute('open-thread', resp.fingerprint)

    return view


class zc.Client extends zc.Controller

  initialize: ->
    @identity = @options.identity
    @transport = @options.transport
    @transport.on('open', @on_open)
    @transport.on('packet', @on_packet)

  on_open: (open) =>
    @identity.authenticate(@transport)

    .then =>
      @transport.send(type: 'list', identity: @identity.fingerprint())

    .then (resp) =>
      @transport.send(
        type: 'get'
        identity: @identity.fingerprint()
        messages: resp.messages
      )

    .done (resp) =>
      for msg in resp.messages
        @on_message(msg.message)

      @trigger('ready')

  on_packet: (packet) =>
    if packet.type == 'message'
      if packet.recipient == @identity.fingerprint()
        @on_message(packet.message)

  on_message: (data) ->
    message = JSON.parse(zc.b64decode(data))
    peer = @app.request('peer', message.sender)
    peer.message_col.add(message)

  send: (recipient, message) ->
    @transport.send(
      type: 'message'
      recipient: recipient
      message: zc.b64encode(JSON.stringify(message))
    )


class zc.PeerListItemView extends Backbone.Marionette.ItemView

  className: 'peerlist-item'
  template: 'peerlist_item.html'

  events:
    'click .peerlist-link': (evt) ->
      evt.preventDefault()
      @trigger('click', @model.get('fingerprint'))


class zc.PeerListView extends Backbone.Marionette.CollectionView

  className: 'peerlist'
  childView: zc.PeerListItemView


class zc.PeerModel extends Backbone.Model

  idAttribute: 'fingerprint'

  initialize: ->
    @message_col = new Backbone.Collection()


class zc.PeerList extends zc.Controller

  initialize: ->
    @peer_col = @options.peer_col
    @app.commands.setHandler 'open-thread', @openThread
    @app.reqres.setHandler 'peer', @get_peer

  get_peer: (fingerprint) =>
    unless @peer_col.get(fingerprint)?
      @peer_col.add(new zc.PeerModel(fingerprint: fingerprint))
    return @peer_col.get(fingerprint)

  openThread: (fingerprint) =>
    thread = new zc.Thread(app: @app, peer: @get_peer(fingerprint))
    thread.show()

  createView: ->
    view = new zc.PeerListView(collection: @peer_col)
    view.on 'childview:click', (view, fingerprint) =>
      @openThread(fingerprint)
    return view
