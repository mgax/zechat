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
    decrypted = @create_rsa().decryptOAEP(b64tohex(data))
    callback(decrypted)
