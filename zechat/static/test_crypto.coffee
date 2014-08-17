describe 'curve25519 public key crypto', ->

  FIX = zc.fixtures

  it 'should encrypt and decrypt', ->
    rv = zc.curve.decrypt(FIX.A_B_ENCRYPTED, FIX.A_PUBKEY, FIX.B_KEY)
    expect(rv).toEqual('foo')

    encrypted = zc.curve.encrypt('foo', FIX.A_KEY, FIX.B_PUBKEY)
    rv2 = zc.curve.decrypt(encrypted, FIX.A_PUBKEY, FIX.B_KEY)
    expect(rv2).toEqual('foo')

  it 'should return null for invalid messages', ->
    expect(zc.curve.decrypt(FIX.A_B_ENCRYPTED, FIX.A_PUBKEY, FIX.A_KEY)).toBe(null)
    expect(zc.curve.decrypt('msg:asdf', FIX.A_PUBKEY, FIX.B_KEY)).toBe(null)

  it 'should generate unique nonces', ->
    nonce_set = (zc.nacl.to_hex(zc.curve.nonce()) for n in [1..100])
    expect(_.uniq(nonce_set).length).toEqual(100)


describe 'curve25519 secret key crypto', ->

  FIX = zc.fixtures

  it 'should encrypt and decrypt', ->
    rv = zc.curve.secret_decrypt(FIX.SEC_ENCRYPTED, FIX.A_KEY)
    expect(rv).toEqual(FIX.SEC_PLAIN)

    enc = zc.curve.secret_encrypt('hello world', FIX.A_KEY)
    expect(zc.curve.secret_decrypt(enc, FIX.A_KEY)).toEqual('hello world')

  it 'should return null for invalid secret box', ->
    expect(zc.curve.secret_decrypt(FIX.SEC_ENCRYPTED, FIX.B_KEY)).toBe(null)
    expect(zc.curve.secret_decrypt('sec:asdf', FIX.A_KEY)).toBe(null)


describe 'scrypt', ->

  FIX = zc.fixtures

  it 'should hash this passphrase', ->
    expect(zc.scrypt(FIX.PASSWORD)).toEqual(FIX.HASHED)
