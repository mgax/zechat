import os
import flask
from flask.ext.assets import Environment, Bundle

os.environ['COFFEE_NO_BARE'] = 'on'

assets = Environment()

assets.register('app.js', Bundle(
    'app.coffee',
    filters='coffeescript',
    output='gen/app.js',
))

assets.register('testsuite.js', Bundle(
    'test_app.coffee',
    filters='coffeescript',
    output='gen/testsuite.js',
))

views = flask.Blueprint('common', __name__)


@views.route('/_test')
def test_page():
    return flask.render_template('_test.html')