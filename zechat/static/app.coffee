zc = window.zc = {}


zc.initialize = (options) ->
  app = zc.app = new Backbone.Marionette.Application

  zc.initialize_core(app)
  zc.initialize_conversation(app)

  @app.reqres.setHandler 'urls', -> options.urls
  @app.reqres.setHandler 'root_el', -> $('body')
  @app.vent.trigger('start')
