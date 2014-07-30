describe 'crypto', ->

  PRIVATE_KEY =
    """
    -----BEGIN RSA PRIVATE KEY-----
    MIICXQIBAAKBgQCdevmtfX+x4lwQSEZbpBhTd/aErOeRDXNhDC6Ynl4ifpqU4dlP
    SwFKscv7VeMC5dpHc7P7t7KbMf+pT4PBCUyl+Nmz/JKsRYkhxKIczyLpSHRai7pU
    qi6W5JwKcCA7+cJUTGtiKQ/tveeHEb60UalP1+3DieJvt1pRkXz23fXP2QIDAQAB
    AoGADvNz7OKzUuIYt3sFIwIrRRFomCQKQB00zQvpCJhQe5nldykSBpMqZjsHEK+Q
    w9+qn4n+lnFURaOzkBF6gsMtQZZvllwbs9MeChOWNXURISMDyMetGwJ2vuM+/DfI
    OAfW+GUcdd570+XpKX04srMadYXY12+eEdhop1kIjF51adkCQQC8C6R6R6JxgOCF
    hL2zGAkVc8VESDspYvhk715HpWZBK4phUPLTRMOkspV58pfM/VIwgnCREVgDXTIn
    6fH4fda3AkEA1mO1/c5Ko1KtTpLBJScClwcClKMdjY9pF/77sx5Ej7uP5sn/oW3q
    avVG6Rc+gvp37B2CL85RHvGHr1v+G3V97wJBAKJDyaJavioDc7rDWI56ZxxD0i2h
    xqtn47/1bf2VFC+YSsi++UqlQ82S7LlWRPd2gL2rUUddF/2PJgCbN1md/PECQQDR
    9CJFZaJYod4RZcz7CmIR746Ka9fES167Xj22o3y3WhLKDKZovBDnID+Kg/X3JT0O
    IbPeB2oQKK8df7SxxXVHAkBMRFOoMEFvl+hXBzdZcrQNnebskzmyt1RMMBs+gplW
    /S9tofKjsb9R92z49rr2WcG59NcYD4278I9/Ktiq9zkh
    -----END RSA PRIVATE KEY-----
    """

  PUBLIC_KEY =
    """
    -----BEGIN PUBLIC KEY-----
    MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCdevmtfX+x4lwQSEZbpBhTd/aE
    rOeRDXNhDC6Ynl4ifpqU4dlPSwFKscv7VeMC5dpHc7P7t7KbMf+pT4PBCUyl+Nmz
    /JKsRYkhxKIczyLpSHRai7pUqi6W5JwKcCA7+cJUTGtiKQ/tveeHEb60UalP1+3D
    ieJvt1pRkXz23fXP2QIDAQAB
    -----END PUBLIC KEY-----
    """

  SIGNATURE =
    """
    idOKmo9dRD6UyNWt1PD0Q0t6/CoSimbDZ0AeDU2ZOL9n781z9RQjiJgZiXjN4LD+
    vP+cp6+cvb/oFJz6Qd3jNGYxfjdqtMGwEm//TejZcS/Qt91O3yt4NoQi2EF7uvXL
    lhvY8830XYlCQ7ocH0xeWunlh6tbdBKF50M5/ZgZ1q4=
    """

  it 'should sign and verify signature', (done) ->

    data = 'foo'

    new zc.Crypto(PRIVATE_KEY).sign 'foo', (signature) ->
      new zc.Crypto(PUBLIC_KEY).verify 'foo', signature, (ok) ->
        expect(ok).toEqual(true)
        done()

  it 'should verify this particular signature', (done) ->
    new zc.Crypto(PUBLIC_KEY).verify 'foo', SIGNATURE, (ok) ->
      expect(ok).toEqual(true)
      done()

  it 'should encrypt and decrypt', (done) ->

    data = 'foo'

    new zc.Crypto(PUBLIC_KEY).encrypt 'foo', (encrypted) ->
      new zc.Crypto(PRIVATE_KEY).decrypt encrypted, (out) ->
        expect(out).toEqual(data)
        done()
