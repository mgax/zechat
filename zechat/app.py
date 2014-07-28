import flask


def create_app():
    from zechat import models
    from zechat.node import views as node_views, websocket
    from zechat.common import views as common_views, assets
    app = flask.Flask(__name__)
    models.db.init_app(app)
    assets.init_app(app)
    websocket.init_app(app)
    app.register_blueprint(node_views)
    app.register_blueprint(common_views)
    return app


app = create_app()
