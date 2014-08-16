import uuid
import hashlib
from flask.ext.sqlalchemy import SQLAlchemy
from sqlalchemy.dialects.postgresql import UUID

db = SQLAlchemy()


def random_uuid():
    return str(uuid.uuid4())


class Message(db.Model):

    id = db.Column(UUID, primary_key=True, default=random_uuid)
    sender = db.Column(db.String, nullable=False, index=True)
    recipient = db.Column(db.String, nullable=False, index=True)
    hash = db.Column(db.String, nullable=False, index=True)
    payload = db.Column(db.String, nullable=False)


class Inbox(object):

    def __init__(self, identity):
        self.identity = identity

    def save(self, sender, payload):
        message = Message(
            sender=sender,
            recipient=self.identity,
            payload=payload,
            hash=hashlib.sha1(payload).hexdigest(),
        )
        db.session.add(message)
        db.session.commit()

    def get(self, hash):
        message = Message.query.filter_by(hash=hash).first()
        assert message and message.recipient == self.identity
        return (message.sender, message.payload)

    def hash_list(self):
        return [
            message.hash for message in
            Message.query.filter_by(recipient=self.identity)
        ]
