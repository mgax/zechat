class zc.Crypto

  constructor: (key) ->
    @key = key

  create_crypt: (callback) ->
    Crypt.make @key, json: false, (_, crypt) ->
      callback(crypt)

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
    priv_key = new RSAKey()
    priv_key.readPublicKeyFromPEMString(@key)
    decrypted = priv_key.encryptOAEP(data)
    callback(hex2b64(decrypted))

  decrypt: (data, callback) ->
    priv_key = new RSAKey()
    priv_key.readPrivateKeyFromPEMString(@key)
    decrypted = priv_key.decryptOAEP(b64tohex(data))
    callback(decrypted)
