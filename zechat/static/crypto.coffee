zc.nacl = nacl_factory.instantiate()


class zc.CurveCrypto

  constructor: ->
    @last_nonce = zc.nacl.crypto_box_random_nonce()
    @NONCE_SIZE = @last_nonce.byteLength

  nonce: ->
    now = zc.nacl.encode_latin1(""+Date.now())
    hash = zc.nacl.crypto_hash(zc.u8cat(@last_nonce, now))
    new_nonce = hash.subarray(0, @NONCE_SIZE)
    @last_nonce = new_nonce
    return new_nonce

  encrypt: (message, sender_b64, recipient_pub_b64) ->
    sender = zc.b64tou8array(sender_b64)
    recipient_pub = zc.b64tou8array(recipient_pub_b64)
    nonce = @nonce()
    plain = zc.nacl.encode_utf8(message)
    ciphertext = zc.nacl.crypto_box(plain, nonce, recipient_pub, sender)
    encrypted = new Uint8Array(nonce.byteLength + ciphertext.byteLength)
    encrypted.set(nonce, 0)
    encrypted.set(ciphertext, nonce.byteLength)
    return zc.b64fromu8array(encrypted)

  decrypt: (encrypted_b64, sender_pub_b64, recipient_b64) ->
    encrypted = zc.b64tou8array(encrypted_b64)
    nonce = encrypted.subarray(0, @NONCE_SIZE)
    ciphertext = encrypted.subarray(@NONCE_SIZE)
    sender_pub = zc.b64tou8array(sender_pub_b64)
    recipient = zc.b64tou8array(recipient_b64)
    try
      plain = zc.nacl.crypto_box_open(ciphertext, nonce, sender_pub, recipient)
    catch e
      return null
    return zc.nacl.decode_utf8(plain)

  random_secret: ->
    secret = new Uint8Array(32)
    window.crypto.getRandomValues(secret)
    return zc.b64fromu8array(secret)

  derive_key: (secret_b64) ->
    secret = zc.b64tou8array(secret_b64)
    key = zc.nacl.crypto_box_keypair_from_seed(secret).boxSk
    return zc.b64fromu8array(key)

  derive_pubkey: (secret_b64) ->
    secret = zc.b64tou8array(secret_b64)
    pubkey = zc.nacl.crypto_box_keypair_from_seed(secret).boxPk
    return zc.b64fromu8array(pubkey)


zc.curve = new zc.CurveCrypto()
