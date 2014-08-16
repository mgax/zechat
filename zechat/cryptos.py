from base64 import b64encode, b64decode
import hashlib
import time
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_OAEP
from Crypto.Hash import SHA256
from Crypto.Signature import PKCS1_PSS
import nacl.utils
from nacl.public import PrivateKey, PublicKey, Box
from nacl.encoding import Base64Encoder
from nacl.exceptions import CryptoError


class Crypto(object):

    def __init__(self, key):
        self.key = RSA.importKey(key)

    def _cipher(self):
        return PKCS1_OAEP.new(self.key)

    def _signer(self):
        return PKCS1_PSS.new(self.key)

    def encrypt(self, data):
        return b64encode(self._cipher().encrypt(data))

    def decrypt(self, data_b64):
        return self._cipher().decrypt(b64decode(data_b64))

    def sign(self, data):
        return b64encode(self._signer().sign(SHA256.new(data)))

    def verify(self, data, signature_b64):
        signature = b64decode(signature_b64)
        return self._signer().verify(SHA256.new(data), signature)

    def fingerprint(self):
        data = self.key.publickey().exportKey('DER')
        return hashlib.sha1(data).hexdigest()

    def public_key(self):
        return self.key.publickey().exportKey() + '\n'


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
