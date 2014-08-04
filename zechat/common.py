import os
import flask

def init_app(app):
    from flask.ext.assets import Environment, Bundle

    os.environ['COFFEE_NO_BARE'] = 'on'

    assets = Environment(app)

    assets.register('app.js', Bundle(
        'app.coffee',
        'core.coffee',
        'crypto.coffee',
        'identity.coffee',
        'conversation.coffee',
        filters='coffeescript',
        output='gen/app.js',
    ))

    assets.register('testsuite.js', Bundle(
        'test_app.coffee',
        'test_crypto.coffee',
        'test_conversation.coffee',
        filters='coffeescript',
        output='gen/testsuite.js',
    ))

    assets.register('app.css', Bundle(
        'app.less',
        filters='less',
        output='gen/app.css',
    ))

    app.register_blueprint(views)

    if app.config.get('TESTING_SERVER'):
        from werkzeug.wsgi import DispatcherMiddleware
        testing_app = create_testing_app(app.config.get('LISTEN_WEBSOCKET'))
        app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {
            '/testing': testing_app,
        })

views = flask.Blueprint('common', __name__)


@views.route('/_test')
def test_page():
    return flask.render_template('_test.html')


@views.route('/')
def app_page():
    transport_url = ''.join([
        'ws://',
        flask.url_for('.app_page', _external=True).lstrip('http://'),
        'ws/transport',
    ])
    return flask.render_template('app.html', transport_url=transport_url)


def create_testing_app(LISTEN_WEBSOCKET):
    from zechat import node
    app = flask.Flask(__name__)
    app.config['LISTEN_WEBSOCKET'] = LISTEN_WEBSOCKET
    node.init_app(app)
    return app
