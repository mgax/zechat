zc.format_pem = (key, title) ->
  rv = "-----BEGIN " + title + "-----\n"
  while key
    rv += key.slice(0, 64) + "\n"
    key = key.slice(64)
  rv += "-----END " + title + "-----\n"

  return rv


zc.generate_key = (size) ->
  unless size >= 1024
    throw "key size must be at least 1024 bits"

  k = new RSAKey()
  k.generate(size, '10001')
  key = k.privateKeyToPkcs1PemString()
  return Q(zc.format_pem(zc.pad_base64(key), "RSA PRIVATE KEY"))


zc.get_public_key = (private_key) ->
  key = new RSAKey()
  key.readPrivateKeyFromPEMString(private_key)
  public_key = key.publicKeyToX509PemString()
  return zc.format_pem(zc.pad_base64(public_key), "PUBLIC KEY")


class zc.Crypto

  constructor: (key) ->
    @key = key

  create_crypt: ->
    deferred = Q.defer()
    Crypt.make @key, json: false, (_, crypt) ->
      deferred.resolve(crypt)
    return deferred.promise

  create_rsa: ->
    rv = new RSAKey()
    if @key.indexOf('BEGIN RSA PRIVATE KEY') > -1
      rv.readPrivateKeyFromPEMString(@key)
    else
      rv.readPublicKeyFromPEMString(@key)
    return rv

  sign: (data) ->
    deferred = Q.defer()
    @create_crypt()
    .then (crypt) ->
      crypt.sign data, (_, signed) ->
        deferred.resolve(zc.pad_base64(signed.signature))
    return deferred.promise

  verify: (data, signature) ->
    deferred = Q.defer()
    @create_crypt()
    .then (crypt) ->
      options =
        data: window.btoa(data)
        signature: signature
        version: 1
      crypt.verify options, (_, verified) ->
        is_ok = (verified == data)
        deferred.resolve(is_ok)
    return deferred.promise

  encrypt: (data) ->
    encrypted = @create_rsa().encryptOAEP(data)
    return Q(hex2b64(encrypted))

  decrypt: (data) ->
    try
      decrypted = @create_rsa().decryptOAEP(b64tohex(data))
      return Q(decrypted)
    catch e
      if e == "Hash mismatch"
        return Q(null)
      return Q.reject(e)

  encrypt_message: (data) ->
    key = null
    enc_key = null
    iv = null
    cbc_mode = slowAES.modeOfOperation.CBC

    zc.random_bytes(AES_128_KEY_SIZE)

    .then (r) =>
      key = r
      zc.random_bytes(AES_BLOCK_SIZE)

    .then (r) =>
      iv = r
      @encrypt(zc.b64frombytes(key))

    .then (r) =>
      enc_key = r

      enc_bytes = slowAES.encrypt(get_char_codes(data), cbc_mode, key, iv)
      payload = {
        enc_key: enc_key
        iv: zc.b64frombytes(iv)
        enc_data: zc.b64frombytes(enc_bytes)
      }
      return zc.b64encode(JSON.stringify(payload))

  decrypt_message: (data) ->
    payload = JSON.parse(zc.b64decode(data))
    iv = zc.b64tobytes(payload.iv)
    enc_bytes = zc.b64tobytes(payload.enc_data)
    cbc_mode = slowAES.modeOfOperation.CBC

    @decrypt(payload.enc_key)

    .then (r) =>
      key = zc.b64tobytes(r)

      bytes = slowAES.decrypt(enc_bytes, cbc_mode, key, iv)
      data = String.fromCharCode.apply(String, bytes)
      return data

  fingerprint: ->
    key_base64 = @create_rsa().publicKeyToX509PemString()
    fingerprint = rstrtohex(rstr_sha1(hextorstr(b64tohex(key_base64))))
    return Q(fingerprint)


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
    return btoa(zc.nacl.decode_latin1(encrypted))

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


zc.curve = new zc.CurveCrypto()
