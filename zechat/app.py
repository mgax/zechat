import flask


DEFAULTS = {
    'CDNJS_URL': '//cdnjs.cloudflare.com/ajax/libs',
}


def create_app(**config):
    from zechat import models
    from zechat import node
    from zechat import common
    app = flask.Flask(__name__)
    app.config.update(DEFAULTS)
    app.config.update(config)
    app.config.from_pyfile('../settings.py', silent=False)
    app.jinja_env.globals['cdnjs'] = app.config['CDNJS_URL']
    models.db.init_app(app)
    node.init_app(app)
    common.init_app(app)
    return app
