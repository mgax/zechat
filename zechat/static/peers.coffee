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
        @app.request('peerlist').register(resp.public_key)

        .then (peer) =>
          @app.commands.execute('open-thread', peer.get('fingerprint'))

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
        @on_message(msg.data)

      @trigger('ready')

  on_packet: (packet) =>
    if packet.type == 'message'
      if packet.recipient == @identity.fingerprint()
        @on_message(packet.data)

  on_message: (packed_data) ->
    data = JSON.parse(zc.b64decode(packed_data))
    message = null
    sender = new zc.Crypto(data.sender_key)

    @identity.crypto().decrypt_message(data.message)

    .then (packed_data) =>
      message = JSON.parse(zc.b64decode(packed_data))
      sender.verify(data.message, data.signature)

    .then (ok) =>
      unless ok
        @trigger('verification-failed', packed_data)
        return

      sender.fingerprint()

      .then (sender_fingerprint) =>
        peer = @app.request('peer', sender_fingerprint, sender.key)
        peer.message_col.add(message)

    .done()

  send: (peer, contents) ->
    packed_message = zc.b64encode(JSON.stringify(contents))

    @identity.crypto().sign(packed_message)

    .then (signature) =>
      data = {
        message: packed_message
        sender_key: @identity.public_key()
        signature: signature
      }
      packed_data = zc.b64encode(JSON.stringify(data))
      new zc.Crypto(peer.get('public_key')).encrypt_message(packed_data)

    .then (encrypted_data) =>
      @transport.send(
        type: 'message'
        recipient: peer.get('fingerprint')
        data: encrypted_data
      )

    .done()


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

  register: (public_key) =>
    rv = new zc.Crypto(public_key).fingerprint()

    .then (fingerprint) =>
      return @get_peer(fingerprint, public_key)

    return rv

  get_peer: (fingerprint, public_key) =>
    unless @peer_col.get(fingerprint)?
      unless public_key?
        throw("Can't create peer without a public key")

      @peer_col.add(new zc.PeerModel(
        fingerprint: fingerprint
        public_key: public_key
      ))

    return @peer_col.get(fingerprint)

  openThread: (fingerprint) =>
    thread = new zc.Thread(app: @app, peer: @get_peer(fingerprint))
    thread.show()

  createView: ->
    view = new zc.PeerListView(collection: @peer_col)
    view.on 'childview:click', (view, fingerprint) =>
      @openThread(fingerprint)
    return view
