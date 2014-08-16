import hashlib
import time
import nacl.utils
from nacl.public import PrivateKey, PublicKey, Box
from nacl.encoding import Base64Encoder
from nacl.exceptions import CryptoError


class DecryptionError(Exception):
    """ Failed to decypt message. """


class CurveCrypto(object):

    def __init__(self):
        self.last_nonce = nacl.utils.random(Box.NONCE_SIZE)

    def nonce(self):
        hash = hashlib.sha512(self.last_nonce + str(time.time()))
        new_nonce = hash.digest()[:Box.NONCE_SIZE]
        self.last_nonce = new_nonce
        return new_nonce

    def encrypt(self, message, sender, recipient_pub):
        box = Box(
            PrivateKey(sender, Base64Encoder),
            PublicKey(recipient_pub, Base64Encoder),
        )
        return box.encrypt(message, self.nonce(), encoder=Base64Encoder)

    def decrypt(self, encrypted, sender_pub, recipient):
        box = Box(
            PrivateKey(recipient, Base64Encoder),
            PublicKey(sender_pub, Base64Encoder),
        )
        try:
            return box.decrypt(encrypted, encoder=Base64Encoder)
        except CryptoError:
            raise DecryptionError

    def pubkey(self, private):
        private_key = PrivateKey(private, Base64Encoder)
        return private_key.public_key.encode(Base64Encoder)
