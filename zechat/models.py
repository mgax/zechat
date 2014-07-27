from flask.ext.sqlalchemy import SQLAlchemy

db = SQLAlchemy()


class Message(db.Model):

    id = db.Column(db.Integer, primary_key=True)
    recipient = db.Column(db.String, nullable=False)
    data = db.Column(db.String, nullable=False)
