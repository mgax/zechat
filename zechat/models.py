import uuid
import hashlib
import base64
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


class Account(db.Model):

    id = db.Column(UUID, primary_key=True, default=random_uuid)
    pubkey = db.Column(db.String, nullable=False, unique=True, index=True)
    state = db.Column(db.String, nullable=False)


def hash(message):
    assert message[:4] == 'msg:'
    data = base64.b64decode(message[4:])
    return 'mh:' + hashlib.sha512(data).hexdigest()[:32]


class Inbox(object):

    def __init__(self, identity):
        self.identity = identity

    def save(self, sender, payload):
        message = Message(
            sender=sender,
            recipient=self.identity,
            payload=payload,
            hash=hash(payload),
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
