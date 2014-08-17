import os
import flask
from pathlib import Path

DEFAULTS = {
    'CDNJS_URL': '//cdnjs.cloudflare.com/ajax/libs',
}


def init_app(app):
    from flask.ext.assets import Environment, Bundle

    os.environ['COFFEE_NO_BARE'] = 'on'

    assets = Environment(app)

    assets.register('app.js', Bundle(
        'utils.coffee',
        'core.coffee',
        'crypto.coffee',
        'network.coffee',
        'identity.coffee',
        'peers.coffee',
        'thread.coffee',
        filters='coffeescript',
        output='gen/app.js',
    ))

    assets.register('testsuite.js', Bundle(
        'test_utils.coffee',
        'test_crypto.coffee',
        'test_conversation.coffee',
        filters='coffeescript',
        output='gen/testsuite.js',
    ))

    assets.register('style.css', Bundle(
        'style.less',
        filters='less',
        output='gen/style.css',
    ))

    app.jinja_env.globals['cdnjs'] = app.config['CDNJS_URL']
    app.jinja_env.globals['get_template_list'] = get_template_list

    app.register_blueprint(views)

    config = app.config
    if config.get('TESTING_SERVER'):
        from werkzeug.wsgi import DispatcherMiddleware
        testing_app = create_testing_app(
            LISTEN_WEBSOCKET=config.get('LISTEN_WEBSOCKET'),
            SQLALCHEMY_DATABASE_URI=config['TESTING_SQLALCHEMY_DATABASE_URI'],
        )
        app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {
            '/testing': testing_app,
        })
        app.extensions['zc_testing_app'] = testing_app


def get_template_list():
    for item in (Path(__file__).parent / 'jstemplates').iterdir():
        with item.open('r', encoding='utf-8') as f:
            yield dict(id=item.name, src=f.read())


views = flask.Blueprint('common', __name__)


@views.route('/_test')
def test_page():
    testing_app = flask.current_app.extensions['zc_testing_app']
    base_url = get_base_url() + 'testing/'
    with testing_app.test_request_context(base_url=base_url):
        url_map = get_url_map()
        url_map['flush'] = flask.url_for('flush')

    return flask.render_template('_test.html', url_map=url_map)


def get_base_url():
    return flask.url_for('.app_page', _external=True)


def get_url_map():
    base_url = get_base_url().lstrip('http://')
    return {
        'transport': ''.join(['ws://', base_url, 'ws/transport']),
    }


@views.route('/')
def app_page(**options):
    return flask.render_template(
        'app.html',
        url_map=get_url_map(),
        options=options,
    )


@views.route('/create-account')
def createaccount_page():
    return app_page(create_account=True)


def create_testing_app(**config):
    from zechat import node
    from zechat import models

    app = flask.Flask(__name__)
    app.config.update(config)
    models.db.init_app(app)
    app.register_blueprint(views)
    node.init_app(app)

    @app.route('/_flush', methods=['POST'])
    def flush():
        models.db.drop_all()
        models.db.create_all()
        node.Node(app)  # create new websocket handler
        return 'ok'

    return app
