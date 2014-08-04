zc = window.zc = {}

zc.modules = {}


zc.create_app = (options) ->
  app = new Backbone.Marionette.Application

  app.reqres.setHandler 'urls', -> options.urls
  app.reqres.setHandler 'root_el', -> $(options.el)

  Object.keys(zc.modules).forEach (name) ->
    app.module name, zc.modules[name]

  setup_identity = zc.setup_identity(app)
  setup_identity.done (fingerprint) ->
    app.vent.trigger('start')
    app.commands.execute('open-conversation', fingerprint)

  _.defer ->
    if setup_identity.isPending()
      $(options.el).text('generating identity ...')

  return app


zc.remove_handlers = (app) ->
  app.commands.removeAllHandlers()
  app.reqres.removeAllHandlers()
  _.values(app.vent._events).forEach (event) ->
    app.vent.off(event.callback)
