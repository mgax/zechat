from flask.ext.sqlalchemy import SQLAlchemy

db = SQLAlchemy()


class Identity(db.Model):

    id = db.Column(db.Integer, primary_key=True)
    fingerprint = db.Column(db.String, nullable=False, unique=True, index=True)
    public_key = db.Column(db.String, nullable=False)


class Message(db.Model):

    id = db.Column(db.Integer, primary_key=True)
    recipient = db.Column(db.String, nullable=False, index=True)
    hash = db.Column(db.String, nullable=False, index=True)
    payload = db.Column(db.String, nullable=False)
