import uuid
from flask.ext.sqlalchemy import SQLAlchemy
from sqlalchemy.dialects.postgresql import UUID

db = SQLAlchemy()


def random_uuid():
    return str(uuid.uuid4())


class Identity(db.Model):

    id = db.Column(UUID, primary_key=True, default=random_uuid)
    fingerprint = db.Column(db.String, nullable=False, unique=True, index=True)
    public_key = db.Column(db.String, nullable=False)


class Message(db.Model):

    id = db.Column(UUID, primary_key=True, default=random_uuid)
    recipient = db.Column(db.String, nullable=False, index=True)
    hash = db.Column(db.String, nullable=False, index=True)
    payload = db.Column(db.String, nullable=False)
