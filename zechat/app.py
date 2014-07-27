import flask


def create_app():
    from zechat import models
    from zechat.node import views as node_views
    from zechat.common import views as common_views
    app = flask.Flask(__name__)
    models.db.init_app(app)
    app.register_blueprint(node_views)
    app.register_blueprint(common_views)
    return app


app = create_app()
