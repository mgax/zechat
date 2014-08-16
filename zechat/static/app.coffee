zc.create_app = (options) ->
  app_deferred = Q.defer()

  channel = options.channel or 'global'
  Backbone.Wreqr.radio.channel(channel).reset()
  app = new Backbone.Marionette.Application(channelName: channel)

  app.el = options.el
  app.$el = $(app.el)

  app.reqres.setHandler 'urls', -> options.urls
  app.reqres.setHandler 'root_el', -> app.$el
  app.reqres.setHandler 'local_storage', ->
    return options.local_storage or window.localStorage

  Object.keys(zc.modules).forEach (name) ->
    app.module name, zc.modules[name]

  setup_identity = zc.setup_identity(app)

  .then (fingerprint) ->
    app.vent.trigger('start')

    if options.talk_to_self
      pubkey = app.request('identity-controller').pubkey()
      peer = app.request('peerlist').register(pubkey)
      app.commands.execute('open-thread', peer)

  _.defer ->
    if setup_identity.isPending()
      $(options.el).text('generating identity ...')

  setup_identity.done ->
    app_deferred.resolve(app)

  return app_deferred.promise
