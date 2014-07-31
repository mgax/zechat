zc.format_pem = (key, title) ->
  rv = "-----BEGIN " + title + "-----\n"
  while key
    rv += key.slice(0, 64) + "\n"
    key = key.slice(64)
  rv += "-----END " + title + "-----\n"

  return rv


zc.generate_key = (size, callback) ->
  k = new RSAKey()
  k.generate(size, '10001')
  key = k.privateKeyToPkcs1PemString()
  _.defer(callback, zc.format_pem(key, "RSA PRIVATE KEY"))


zc.get_public_key = (private_key) ->
  key = new RSAKey()
  key.readPrivateKeyFromPEMString(private_key)
  public_key = key.publicKeyToX509PemString()
  return zc.format_pem(public_key, "PUBLIC KEY")


class zc.Crypto

  constructor: (key) ->
    @key = key

  create_crypt: (callback) ->
    Crypt.make @key, json: false, (_, crypt) ->
      callback(crypt)

  create_rsa: ->
    rv = new RSAKey()
    if @key.indexOf('BEGIN RSA PRIVATE KEY') > -1
      rv.readPrivateKeyFromPEMString(@key)
    else
      rv.readPublicKeyFromPEMString(@key)
    return rv

  sign: (data, callback) ->
    @create_crypt (crypt) ->
      crypt.sign data, (_, signed) ->
        callback(signed.signature)

  verify: (data, signature, callback) ->
    @create_crypt (crypt) ->
      options =
        data: window.btoa(data)
        signature: signature
        version: 1
      crypt.verify options, (_, verified) ->
        callback(verified == data)

  encrypt: (data, callback) ->
    decrypted = @create_rsa().encryptOAEP(data)
    callback(hex2b64(decrypted))

  decrypt: (data, callback) ->
    try
      decrypted = @create_rsa().decryptOAEP(b64tohex(data))
    catch e
      if e == "Hash mismatch"
        return callback(null)
      throw e
    callback(decrypted)

  fingerprint: (callback) ->
    key_base64 = @create_rsa().publicKeyToX509PemString()
    hash = rstrtohex(rstr_sha1(hextorstr(b64tohex(key_base64))))
    fingerprint = hash.slice(0, 32)
    callback(fingerprint)
