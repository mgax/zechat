describe 'crypto', ->

  FIX = zc.fixtures

  it 'should sign and verify signature', (test_done) ->
    new zc.Crypto(FIX.PRIVATE_KEY).sign('foo')

    .then (signature) ->
      new zc.Crypto(FIX.PUBLIC_KEY).verify('foo', signature)

    .done (ok) ->
      expect(ok).toEqual(true)
      test_done()

  it 'should verify this particular signature', (test_done) ->
    new zc.Crypto(FIX.PUBLIC_KEY).verify('foo', FIX.SIGNATURE)

    .done (ok) ->
      expect(ok).toEqual(true)
      test_done()

  it 'should return false for a different signature', (test_done) ->
    new zc.Crypto(FIX.PRIVATE_KEY).sign('foo')

    .then (signature) ->
      new zc.Crypto(FIX.PUBLIC_KEY).verify('bar', signature)

    .done (ok) ->
      expect(ok).toEqual(false)
      test_done()

  it 'should return false for a malformed signature', (test_done) ->
    new zc.Crypto(FIX.PUBLIC_KEY).verify('foo', 'garbage signature')

    .done (ok) ->
      expect(ok).toEqual(false)
      test_done()

  it 'should encrypt and decrypt', (test_done) ->
    new zc.Crypto(FIX.PUBLIC_KEY).encrypt('foo')

    .then (encrypted) ->
      new zc.Crypto(FIX.PRIVATE_KEY).decrypt(encrypted)

    .done (out) ->
      expect(out).toEqual('foo')
      test_done()

  it 'should decrypt this particular message', (test_done) ->
    new zc.Crypto(FIX.PRIVATE_KEY).decrypt(FIX.ENCRYPTED)

    .done (out) ->
      expect(out).toEqual('foo')
      test_done()

  it 'should return null for malformed message', (test_done) ->
    new zc.Crypto(FIX.PRIVATE_KEY).decrypt('garbage message')

    .done (out) ->
      expect(out).toEqual(null)
      test_done()

  it 'should return null for message encrypted with other key', (test_done) ->
    zc.generate_key(1024)

    .then (other_key) ->
      other_public_key = zc.get_public_key(other_key)
      new zc.Crypto(other_public_key).encrypt('foo')

    .then (encrypted) ->
      new zc.Crypto(FIX.PRIVATE_KEY).decrypt(encrypted)

    .done (out) ->
      expect(out).toEqual(null)
      test_done()

  it 'should encrypt and decrypt using symmetric key', (test_done) ->
    message = ('[tenbytes]' for _ in [1..100]).join('')

    new zc.Crypto(FIX.PUBLIC_KEY).encrypt_message(message)

    .then (encrypted) ->
      new zc.Crypto(FIX.PRIVATE_KEY).decrypt_message(encrypted)

    .then (decrypted) ->
      expect(decrypted).toEqual(message)

    .done ->
      test_done()

  it 'should generate a usable key', (test_done) ->
    zc.generate_key(1024)

    .then (private_key) ->
      public_key = zc.get_public_key(private_key)

      new zc.Crypto(private_key).sign('foo')

      .then (signature) ->
        new zc.Crypto(public_key).verify('foo', signature)

      .then (ok) ->
        expect(ok).toEqual(true)

        new zc.Crypto(public_key).encrypt('foo')

      .then (encrypted) ->
        new zc.Crypto(private_key).decrypt(encrypted)

      .done (out) ->
        expect(out).toEqual('foo')
        test_done()

  it 'should calculate the fingerprint', (test_done) ->
    new zc.Crypto(FIX.PRIVATE_KEY_B).fingerprint()

    .then (private_fingerprint) ->
      expect(private_fingerprint).toEqual(FIX.FINGERPRINT_B)
      new zc.Crypto(FIX.PUBLIC_KEY).fingerprint()

    .done (public_fingerprint) ->
      expect(public_fingerprint).toEqual(FIX.FINGERPRINT)
      test_done()
