import flask

views = flask.Blueprint('common', __name__)


@views.route('/_test')
def test_page():
    return flask.render_template('_test.html')
