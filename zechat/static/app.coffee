zc = window.zc = {}

zc.modules = {}


zc.initialize = (options) ->
  app = zc.app = new Backbone.Marionette.Application

  Object.keys(zc.modules).forEach (name) ->
    app.module name, zc.modules[name]

  app.reqres.setHandler 'urls', -> options.urls
  app.reqres.setHandler 'root_el', -> $(options.el)

  setup_identity = zc.setup_identity(app)
  setup_identity.done (fingerprint) ->
    app.vent.trigger('start')
    app.commands.execute('open-conversation', fingerprint)

  _.defer ->
    if setup_identity.isPending()
      $(options.el).text('generating identity ...')
