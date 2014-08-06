import flask


def create_app(**config):
    from zechat import models
    from zechat import node
    from zechat import common
    app = flask.Flask(__name__)
    app.config.update(common.DEFAULTS)
    app.config.update(config)
    app.config.from_pyfile('../settings.py', silent=False)
    models.db.init_app(app)
    node.init_app(app)
    common.init_app(app)
    return app


def create_manager(app):
    from flask.ext.script import Manager
    from flask.ext.migrate import Migrate, MigrateCommand
    from zechat.models import db

    migrate = Migrate(app, db)

    manager = Manager(app)
    manager.add_command('db', MigrateCommand)
    return manager
