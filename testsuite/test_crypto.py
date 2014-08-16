import pytest

A_KEY = 'VrIuRMeVZkmqlS9Sa9VRritZ1eVmnyJcZZFKJUkdnvk='
A_PUBKEY = 'B8dnDDjozeRUBsMFlPiWL4HR6kLEa9WyVRga4Q/CoXY='

B_KEY = 'NuwWzeSWynTxvBfNxi1z5UwG7AtKwwQYpW0GlDde4Fs='
B_PUBKEY = 'YCBnGbI2GbfWjmJl22o4IH3sIACU8Sv58fcxfDQojhI='

A_B_ENCRYPTED = 'zc+OgEhoQm3Yu8vqsFcuvzc0FJuQ2au4+wrxt8hGkss1jDAFXEMRoRU6+g=='


@pytest.fixture(scope='module')
def curve():
    from zechat.cryptos import CurveCrypto
    return CurveCrypto()


def test_encryption(curve):
    assert curve.decrypt(A_B_ENCRYPTED, A_PUBKEY, B_KEY) == 'foo'

    encrypted = curve.encrypt('foo', A_KEY, B_PUBKEY)
    assert curve.decrypt(encrypted, A_PUBKEY, B_KEY) == 'foo'


def test_decryption_errors(curve):
    from zechat.cryptos import DecryptionError

    with pytest.raises(DecryptionError):
        assert curve.decrypt(A_B_ENCRYPTED, A_PUBKEY, A_KEY)

    with pytest.raises(DecryptionError):
        assert curve.decrypt('asdf'*20, A_PUBKEY, B_KEY)


def test_nonces_are_different(curve):
    nonce_set = set()
    for _ in range(100):
        nonce_set.add(curve.nonce())
    assert len(nonce_set) == 100
