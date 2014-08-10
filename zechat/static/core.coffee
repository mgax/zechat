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
    threadlist: '.app-threadlist'
    main: '.app-main'


class zc.HeaderView extends Backbone.Marionette.ItemView

  className: 'header-container tall'
  template: 'header.html'

  initialize: ->
    @model.on('change', @render.bind(@))

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
      myid = @app.request('identity-controller')
      @app.commands.execute('show-main', myid.createView())

    view.on 'click-add-contact', =>
      add_contact = new zc.AddContact(app: @app)
      @app.commands.execute('show-main', add_contact.createView())

    view.on 'click-connect', =>
      @app.commands.execute('reconnect')

    return view


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


class zc.Persist extends zc.Controller

  initialize: ->
    @key = @options.key
    @model = @options.model
    value = @app.request('local_storage').getItem(@key)
    if value
      @model.set(JSON.parse(value))
    @model.on('change', _.bind(@save, @))

  save: ->
    @app.request('local_storage').setItem(@key, JSON.stringify(@model))


zc.modules.core = ->
  @models =
    identity: new Backbone.Model
    threadlist: new Backbone.Collection

  @persist_identity = new zc.Persist
    app: @app
    key: 'identity'
    model: @models.identity

  zc.set_identity = (fingerprint) =>
    @models.identity.set('fingerprint', fingerprint)

  @app.reqres.setHandler 'identity', => @models.identity
  @app.reqres.setHandler 'threadlist', => @models.threadlist

  @transport = new zc.Transport(app: @app)
  @threadlist = new zc.Threadlist(app: @app)
  @identity = new zc.Identity(app: @app)

  @app.reqres.setHandler 'identity-controller', => @identity

  @app.commands.setHandler 'show-main', (view) =>
    @layout.main.show(view)

  @app.vent.on 'start', =>
    @layout = new zc.AppLayout(el: @app.request('root_el'))
    @layout.render()

    @header = new zc.Header(app: @app)
    @layout.header.show(@header.createView())
    @layout.threadlist.show(@threadlist.createView())

  @app.vent.on 'connect', =>
    fingerprint = @app.request('identity').get('fingerprint')
    @app.request('send-packet', {type: 'list', identity: fingerprint})

    .then (resp) =>
      @app.request('send-packet',
        {type: 'get', identity: fingerprint, messages: resp.messages})

    .done (resp) =>
      for msg in resp.messages
        @app.vent.trigger('message', msg.message)
