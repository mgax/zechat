import flask


def create_app():
    from zechat import models
    from zechat.node import views
    app = flask.Flask(__name__)
    models.db.init_app(app)
    app.register_blueprint(views)
    return app


app = create_app()
