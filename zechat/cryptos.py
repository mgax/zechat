import hashlib
import time
import nacl.utils
from nacl.public import PrivateKey, PublicKey, Box
from nacl.encoding import Base64Encoder
from nacl.exceptions import CryptoError


class DecryptionError(Exception):
    """ Failed to decypt message. """


def secret_key(key):
    assert key[:3] == 'sk:'
    return PrivateKey(key[3:], Base64Encoder)


def public_key(key):
    assert key[:3] == 'pk:'
    return PublicKey(key[3:], Base64Encoder)


def random_key():
    return 'sk:' + PrivateKey.generate().encode(Base64Encoder)


class CurveCrypto(object):

    def __init__(self):
        self.last_nonce = nacl.utils.random(Box.NONCE_SIZE)

    def nonce(self):
        hash = hashlib.sha512(self.last_nonce + str(time.time()))
        new_nonce = hash.digest()
        self.last_nonce = new_nonce
        return new_nonce[:Box.NONCE_SIZE]

    def encrypt(self, message, sender, recipient_pub):
        box = Box(secret_key(sender), public_key(recipient_pub))
        encrypted = box.encrypt(message, self.nonce(), encoder=Base64Encoder)
        return 'msg:' + encrypted

    def decrypt(self, encrypted, sender_pub, recipient):
        box = Box(secret_key(recipient), public_key(sender_pub))
        if encrypted[:4] != 'msg:':
            raise DecryptionError

        try:
            return box.decrypt(Base64Encoder.decode(encrypted[4:]))
        except CryptoError:
            raise DecryptionError

    def challenge(self):
        return Base64Encoder.encode(self.nonce())

    def pubkey(self, private):
        return 'pk:' + secret_key(private).public_key.encode(Base64Encoder)
