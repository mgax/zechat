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

  it 'should sign and verify signature', (done) ->

    data = 'foo'

    Crypt.make PRIVATE_KEY, (err, signer) ->
        signer.sign data, (err, signed) ->
            Crypt.make PUBLIC_KEY, (err, verifier) ->
                verifier.verify signed, (err, verified) ->
                    expect(verified).toEqual(data)
                    done()

  it 'should encrypt and decrypt', (done) ->

    data = 'foo'

    Crypt.make PUBLIC_KEY, (err, encrypter) ->
        encrypter.encrypt data, (err, encrypted) ->
            Crypt.make PRIVATE_KEY, (err, decrypter) ->
                decrypter.decrypt encrypted, (err, decrypted) ->
                    expect(decrypted).toEqual(data)
                    done()
