import pytest
import flask


app0 = flask.Flask(__name__)
app0.config.from_pyfile('../settings.py', silent=False)
db_uri = app0.config['TESTING_SQLALCHEMY_DATABASE_URI']
del app0


@pytest.fixture
def app():
    from zechat import models
    app = flask.Flask(__name__)
    app.testing = True
    app.config['SQLALCHEMY_DATABASE_URI'] = db_uri
    models.db.init_app(app)

    with app.app_context():
        models.db.drop_all()
        models.db.create_all()

    return app
