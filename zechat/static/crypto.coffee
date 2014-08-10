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
