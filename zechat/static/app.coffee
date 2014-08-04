zc = window.zc = {}

zc.modules = {}


zc.create_app = (options) ->
  app_deferred = Q.defer()

  app = new Backbone.Marionette.Application()

  app.reqres.setHandler 'urls', -> options.urls
  app.reqres.setHandler 'root_el', -> $(options.el)
  app.reqres.setHandler 'local_storage', ->
    return options.local_storage or window.localStorage

  Object.keys(zc.modules).forEach (name) ->
    app.module name, zc.modules[name]

  setup_identity = zc.setup_identity(app)
  setup_identity.done (fingerprint) ->
    app.vent.trigger('start')
    app.commands.execute('open-conversation', fingerprint)
    app_deferred.resolve(app)

  _.defer ->
    if setup_identity.isPending()
      $(options.el).text('generating identity ...')

  return app_deferred.promise


zc.remove_handlers = (app) ->
  Backbone.Wreqr.radio.channel('global').reset()
