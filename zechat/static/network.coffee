class zc.Transport extends zc.Controller

  initialize: (options) ->
    @model = new Backbone.Model(state: 'closed')
    @queue = []
    @app.vent.on('start', _.bind(@connect, @))
    @app.commands.setHandler 'send-packet', _.bind(@send, @)
    @app.commands.setHandler 'reconnect', =>
      if @model.get('state') == 'closed'
        @connect()
    @app.reqres.setHandler 'transport-state', => @model

  connect: ->
    transport_url = @app.request('urls')['transport']
    @ws = new WebSocket(transport_url)
    @ws.onmessage = @on_receive.bind(@)
    @ws.onopen = @on_open.bind(@)
    @ws.onclose = @on_close.bind(@)
    @model.set(state: 'connecting')
    @send(
      type: 'authenticate'
      identity: @app.request('identity').get('fingerprint')
    )

  on_open: ->
    @model.set(state: 'open')
    current_queue = @queue
    @queue = []
    current_queue.forEach (msg) =>
      @send(msg)

  on_close: ->
    console.log 'CLOSED'
    @model.set(state: 'closed')

  on_receive: (evt) ->
    msg = JSON.parse(evt.data)
    identity = @app.request('identity')
    my_fingerprint = identity.get('fingerprint')
    if msg.type == 'message' and msg.recipient == my_fingerprint
      @app.vent.trigger('message', msg.message)

  send: (msg) ->
    if @ws.readyState == WebSocket.OPEN
      @ws.send(JSON.stringify(msg))
    else
      @queue.push(msg)


class zc.Receiver extends zc.Controller

  initialize: ->
    @app.vent.on('message', _.bind(@on_message, @))

  on_message: (data) ->
    thread = @app.request('thread', data.sender)
    thread.message_col.add(data)
