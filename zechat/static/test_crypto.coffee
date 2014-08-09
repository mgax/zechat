describe 'crypto', ->

  FIX = zc.fixtures

  it 'should sign and verify signature', (done) ->
    new zc.Crypto(FIX.PRIVATE_KEY).sign 'foo', (signature) ->
      new zc.Crypto(FIX.PUBLIC_KEY).verify 'foo', signature, (ok) ->
        expect(ok).toEqual(true)
        done()

  it 'should verify this particular signature', (done) ->
    new zc.Crypto(FIX.PUBLIC_KEY).verify 'foo', FIX.SIGNATURE, (ok) ->
      expect(ok).toEqual(true)
      done()

  it 'should return false for a different signature', (done) ->
    new zc.Crypto(FIX.PRIVATE_KEY).sign 'foo', (signature) ->
      new zc.Crypto(FIX.PUBLIC_KEY).verify 'bar', signature, (ok) ->
        expect(ok).toEqual(false)
        done()

  it 'should return false for a malformed signature', (done) ->
    new zc.Crypto(FIX.PUBLIC_KEY).verify 'foo', 'garbage signature', (ok) ->
      expect(ok).toEqual(false)
      done()

  it 'should encrypt and decrypt', (done) ->
    new zc.Crypto(FIX.PUBLIC_KEY).encrypt 'foo', (encrypted) ->
      new zc.Crypto(FIX.PRIVATE_KEY).decrypt encrypted, (out) ->
        expect(out).toEqual('foo')
        done()

  it 'should decrypt this particular message', (done) ->
    new zc.Crypto(FIX.PRIVATE_KEY).decrypt FIX.ENCRYPTED, (out) ->
      expect(out).toEqual('foo')
      done()

  it 'should return null for malformed message', (done) ->
    new zc.Crypto(FIX.PRIVATE_KEY).decrypt 'garbage message', (out) ->
      expect(out).toEqual(null)
      done()

  it 'should return null for message encrypted with other key', (done) ->
    zc.generate_key 1024, (other_key) ->
      other_public_key = zc.get_public_key(other_key)
      new zc.Crypto(other_public_key).encrypt 'foo', (encrypted) ->
        new zc.Crypto(FIX.PRIVATE_KEY).decrypt encrypted, (out) ->
          expect(out).toEqual(null)
          done()

  it 'should generate a usable key', (done) ->
    zc.generate_key 1024, (private_key) ->
      public_key = zc.get_public_key(private_key)

      new zc.Crypto(private_key).sign 'foo', (signature) ->
        new zc.Crypto(public_key).verify 'foo', signature, (ok) ->
          expect(ok).toEqual(true)

          new zc.Crypto(public_key).encrypt 'foo', (encrypted) ->
            new zc.Crypto(private_key).decrypt encrypted, (out) ->
              expect(out).toEqual('foo')
              done()

  it 'should calculate the fingerprint', (done) ->
    new zc.Crypto(FIX.PRIVATE_KEY_B).fingerprint (private_fingerprint) ->
      expect(private_fingerprint).toEqual(FIX.FINGERPRINT_B)

      new zc.Crypto(FIX.PUBLIC_KEY).fingerprint (public_fingerprint) ->
        expect(public_fingerprint).toEqual(FIX.FINGERPRINT)
        done()
