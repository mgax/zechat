import uuid
import hashlib
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


class Inbox(object):

    def __init__(self, identity):
        self.identity = identity

    def save(self, message_data):
        message = Message(
            payload=message_data,
            hash=hashlib.sha1(message_data).hexdigest(),
            recipient=self.identity,
        )
        db.session.add(message)
        db.session.commit()

    def get(self, message_hash):
        message = Message.query.filter_by(hash=message_hash).first()
        assert message and message.recipient == self.identity
        return message.payload

    def hash_list(self):
        return [
            message.hash for message in
            Message.query.filter_by(recipient=self.identity)
        ]
