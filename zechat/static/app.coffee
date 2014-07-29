zc = window.zc = {}

zc.modules = {}


zc.initialize = (options) ->
  app = zc.app = new Backbone.Marionette.Application

  Object.keys(zc.modules).forEach (name) ->
    app.module name, zc.modules[name]

  app.reqres.setHandler 'urls', -> options.urls
  app.reqres.setHandler 'root_el', -> $('body')
  app.vent.trigger('start')
  app.commands.execute('open-conversation')
