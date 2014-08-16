class zc.Controller extends Backbone.Marionette.Controller

  constructor: (options) ->
    @app = options.app
    super(options)


class zc.BlankView extends Backbone.Marionette.ItemView

  template: -> ''


class zc.AppLayout extends Backbone.Marionette.LayoutView

  template: 'app_layout.html'

  regions:
    header: '.app-header'
    peerlist: '.app-peerlist'
    main: '.app-main'


class zc.HeaderView extends Backbone.Marionette.ItemView

  className: 'header-container tall'
  template: 'header.html'

  initialize: ->
    @model.on('change', => @render())

  serializeData: ->
    state = @model.get('state')
    if state == 'closed'
      return cls: 'btn-danger header-btn-connect', text: "✘"
    if state == 'connecting'
      return cls: 'btn-warning', disabled: true, text: "…"
    if state == 'open'
      return cls: 'btn-success', disabled: true, text: "✔"

  events:
    'click .header-btn-myid': (evt) ->
      evt.preventDefault()
      @trigger('click-myid')

    'click .header-btn-add-contact': (evt) ->
      evt.preventDefault()
      @trigger('click-add-contact')

    'click .header-btn-connect': (evt) ->
      evt.preventDefault()
      @trigger('click-connect')


class zc.Header extends zc.Controller

  createView: ->
    view = new zc.HeaderView(model: @app.request('transport-state'))

    view.on 'click-myid', =>
      myid = @app.request('identity')
      @app.commands.execute('show-main', myid.createView())

    view.on 'click-add-contact', =>
      add_contact = new zc.AddContact(app: @app)
      @app.commands.execute('show-main', add_contact.createView())

    view.on 'click-connect', =>
      @app.commands.execute('reconnect')

    return view


zc.core_module = ->
  @models =
    identity: new Backbone.Model
    peer_col: new Backbone.Collection

  @transport = new zc.Transport(app: @app)
  @peerlist = new zc.PeerList(app: @app, peer_col: @models.peer_col)
  @identity = new zc.Identity(app: @app, model: @models.identity)
  @client = new zc.Client(
    app: @app
    transport: @transport
    identity: @identity
  )

  @client.on 'verification-failed', (data) =>
    console.log("message verification failed", data)

  @app.reqres.setHandler 'identity', => @identity
  @app.reqres.setHandler 'client', => @client
  @app.reqres.setHandler 'peerlist', => @peerlist

  @app.commands.setHandler 'show-main', (view) =>
    @layout.main.show(view)

  @layout = new zc.AppLayout(el: @app.request('root_el'))
  @layout.render()

  @app.vent.on 'start', =>
    @header = new zc.Header(app: @app)
    @layout.header.show(@header.createView())
    @layout.peerlist.show(@peerlist.createView())


zc.create_app = (options) ->
  app_deferred = Q.defer()

  channel = options.channel or 'global'
  Backbone.Wreqr.radio.channel(channel).reset()
  app = new Backbone.Marionette.Application(channelName: channel)

  app.el = options.el
  app.$el = $(app.el)

  app.reqres.setHandler 'urls', -> options.urls
  app.reqres.setHandler 'root_el', -> app.$el

  app.module('core', zc.core_module)

  Q().then ->
    if options.secret?
      app.request('identity').model.set('secret', options.secret)

    else
      zc.setup_identity(app)

  .then ->
    app.vent.trigger('start')

    if options.talk_to_self
      pubkey = app.request('identity').pubkey()
      peer = app.request('peerlist').register(pubkey)
      app.commands.execute('open-thread', peer)

  .done ->
    app_deferred.resolve(app)

  return app_deferred.promise
