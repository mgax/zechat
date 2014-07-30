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
    @create_crypt (crypt) ->
      crypt.encrypt data, (_, encrypted) ->
        callback(encrypted)

  decrypt: (encrypted, callback) ->
    @create_crypt (crypt) ->
      crypt.decrypt encrypted, (_, decrypted) ->
          callback(decrypted)
