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

  PING_INTERVAL: 45  # seconds
  BACKOFF_INCREMENT: 1  # seconds
  ATTEMPT_CUTOFF: 6  # wait at most 2^6 (64) seconds

  initialize: (options) ->
    @in_flight = new zc.InFlight(app: @app)
    @model = new Backbone.Model(state: 'closed')
    @deferred = Q.defer()
    @app.vent.on('start', @connect)
    @app.commands.setHandler('reconnect', @connect)
    @app.reqres.setHandler 'transport-state', => @model
    setInterval(@ping, @PING_INTERVAL * 1000)

  connect: =>
    if @model.get('state') != 'open'
      @model.set(attempt: 0)
      if @model.get('state') != 'connecting'
        clearTimeout(@backoff_timeout)
        @attempt_connection()

    return @deferred.promise

  attempt_connection: =>
    @model.set(state: 'connecting')
    transport_url = @app.request('urls')['transport']
    @ws = new WebSocket(transport_url)
    @ws.onmessage = @on_receive

    @ws.onopen = () =>
      @model.set(state: 'open', attempt: 0)
      @trigger('open')
      @deferred.resolve(@)

    @ws.onclose = () =>
      if @model.get('state') == 'open'
        @deferred = Q.defer()
        @in_flight.flush()

      @model.set(state: 'backoff')
      attempt = Math.min(@model.get('attempt'), @ATTEMPT_CUTOFF)
      @model.set(attempt: attempt + 1)
      delay = @BACKOFF_INCREMENT * Math.pow(2, attempt) * 1000
      @backoff_timeout = setTimeout(@attempt_connection, delay)

  ping: =>
    if @model.get('state') == 'open'
      @send(type: 'ping')

  on_receive: (evt) =>
    packet = JSON.parse(evt.data)
    unless @in_flight.reply(packet)
      @trigger('packet', packet)

  send: (msg) ->
    if @model.get('state') == 'open'
      promise = @in_flight.wrap(msg)
      @ws.send(JSON.stringify(msg))
      return promise
    else
      return Q.reject('disconnected')
