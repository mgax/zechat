class zc.AddContactView extends Backbone.Marionette.ItemView

  tagName: 'form'
  template: 'add_contact.html'

  ui:
    peer: '[name=peer]'

  events:
    'submit': (evt) ->
      evt.preventDefault()
      peer = @ui.peer.val()
      if peer
        this.trigger('add', peer)

  onShow: ->
    @ui.peer.focus()


class zc.AddContact extends zc.Controller

  createView: ->
    view = new zc.AddContactView()

    view.on 'add', (peer_key) =>
      peer = @app.request('peerlist').register(peer_key)
      @app.commands.execute('open-thread', peer.get('pubkey'))

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
      @transport.send(type: 'list', identity: @identity.pubkey())

    .then (resp) =>
      @transport.send(
        type: 'get'
        identity: @identity.pubkey()
        messages: resp.messages
      )

    .done (resp) =>
      for msg in resp.messages
        @on_message(msg)

      @trigger('ready')

  on_packet: (packet) =>
    if packet.type == 'message'
      if packet.recipient == @identity.pubkey()
        @on_message(packet)

  on_message: (packet) ->
    sender = packet.sender
    packed_message = zc.curve.decrypt(packet.data, sender, @identity.key())

    unless packed_message?
      @trigger('verification-failed', packed_data)
      return

    message = JSON.parse(zc.b64decode(packed_message))
    peer = @app.request('peer', sender)
    peer.message_col.add(message)

  send: (peer, message) ->
    packed_message = zc.b64encode(JSON.stringify(message))
    peer_pubkey = peer.get('pubkey')
    encrypted = zc.curve.encrypt(packed_message, @identity.key(), peer_pubkey)

    @transport.send(
      type: 'message'
      sender: @identity.pubkey()
      recipient: peer_pubkey
      data: encrypted
    )


class zc.PeerListItemView extends Backbone.Marionette.ItemView

  className: 'peerlist-item'
  template: 'peerlist_item.html'

  events:
    'click .peerlist-link': (evt) ->
      evt.preventDefault()
      @trigger('click', @model.get('pubkey'))


class zc.PeerListView extends Backbone.Marionette.CollectionView

  className: 'peerlist'
  childView: zc.PeerListItemView


class zc.PeerModel extends Backbone.Model

  idAttribute: 'pubkey'

  initialize: ->
    @message_col = new Backbone.Collection()


class zc.PeerList extends zc.Controller

  initialize: ->
    @peer_col = @options.peer_col
    @app.commands.setHandler 'open-thread', @openThread
    @app.reqres.setHandler 'peer', @get_peer

  register: (pubkey) =>
    return @get_peer(pubkey)

  get_peer: (pubkey) =>
    unless @peer_col.get(pubkey)?

      @peer_col.add(new zc.PeerModel(pubkey: pubkey))

    return @peer_col.get(pubkey)

  openThread: (pubkey) =>
    thread = new zc.Thread(app: @app, peer: @get_peer(pubkey))
    thread.show()

  createView: ->
    view = new zc.PeerListView(collection: @peer_col)
    view.on 'childview:click', (view, pubkey) =>
      @openThread(pubkey)
    return view
