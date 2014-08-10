class zc.InFlight extends zc.Controller

  initialize: ->
    @serial = 0
    @pending = {}

  wrap: (packet) ->
    packet._serial = (@serial += 1)
    deferred = Q.defer()
    @pending[packet._serial] = deferred
    return deferred.promise

  reply: (packet) ->
    return false unless packet._reply
    deferred = @pending[packet._reply]
    return false unless deferred
    delete @pending[packet._reply]
    deferred.resolve(packet)
    return true

  flush: ->
    _.forEach @pending, (deferred) ->
      deferred.reject('disconnected')
    @pending = {}


class zc.Transport extends zc.Controller

  initialize: (options) ->
    @in_flight = new zc.InFlight(app: @app)
    @model = new Backbone.Model(state: 'closed')
    @app.vent.on('start', _.bind(@connect, @))
    @app.commands.setHandler 'reconnect', =>
      if @model.get('state') == 'closed'
        @connect()
    @app.reqres.setHandler 'transport-state', => @model

  connect: ->
    deferred = Q.defer()
    transport_url = @app.request('urls')['transport']
    @ws = new WebSocket(transport_url)
    @ws.onmessage = @on_receive.bind(@)
    @ws.onopen = () =>
      @on_open()
      deferred.resolve(@)
    @ws.onclose = @on_close.bind(@)
    @model.set(state: 'connecting')
    return deferred.promise

  on_open: ->
    @model.set(state: 'open')
    @trigger('open')

  on_close: ->
    @model.set(state: 'closed')
    @in_flight.flush()

  on_receive: (evt) ->
    packet = JSON.parse(evt.data)
    unless @in_flight.reply(packet)
      @trigger('packet', packet)

  send: (msg) ->
    if @ws and @ws.readyState == WebSocket.OPEN
      promise = @in_flight.wrap(msg)
      @ws.send(JSON.stringify(msg))
      return promise
    else
      return Q.reject('disconnected')
