from base64 import b64encode, b64decode
import hashlib
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_OAEP
from Crypto.Hash import SHA256
from Crypto.Signature import PKCS1_PSS


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
