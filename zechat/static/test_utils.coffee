zc.waitfor = (check, timeout=1000) ->
  t0 = _.now()
  deferred = Q.defer()

  poll = ->
    dt = _.now() - t0
    if dt > timeout
      clearInterval(interval)
      deferred.reject('timeout')
    else

    rv = check()
    if rv?
      clearInterval(interval)
      deferred.resolve(rv)

  interval = setInterval(poll, 50)

  return deferred.promise


zc.some = ($qs) ->
  return $qs if $qs.length > 0


class zc.MockLocalStorage

  constructor: (data) -> @_data = _.extend({}, data)

  getItem: (key) -> @_data[key]

  setItem: (key, value) -> @_data[key] = value


zc.fixtures = {

  PRIVATE_KEY:
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

  PUBLIC_KEY:
    """
    -----BEGIN PUBLIC KEY-----
    MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCdevmtfX+x4lwQSEZbpBhTd/aE
    rOeRDXNhDC6Ynl4ifpqU4dlPSwFKscv7VeMC5dpHc7P7t7KbMf+pT4PBCUyl+Nmz
    /JKsRYkhxKIczyLpSHRai7pUqi6W5JwKcCA7+cJUTGtiKQ/tveeHEb60UalP1+3D
    ieJvt1pRkXz23fXP2QIDAQAB
    -----END PUBLIC KEY-----
    """

  ENCRYPTED:
    """
    UWTjYts0rx3JuglN9DwgzJAcbDh1J36tqegPj8Rhyr5exfFwlhE+/WKEjhOlg+dK
    P4iJjLybJ8SSFH8FUQIjsA0DU/VuCBn9jdyhlw8JX3kE5jSpp4O3Es+ByoLd/AwF
    HjVC9WFWgszQSzs/l/7/z7ZonucLz/fp1WmijT59kDY=
    """

  SIGNATURE:
    """
    idOKmo9dRD6UyNWt1PD0Q0t6/CoSimbDZ0AeDU2ZOL9n781z9RQjiJgZiXjN4LD+
    vP+cp6+cvb/oFJz6Qd3jNGYxfjdqtMGwEm//TejZcS/Qt91O3yt4NoQi2EF7uvXL
    lhvY8830XYlCQ7ocH0xeWunlh6tbdBKF50M5/ZgZ1q4=
    """

  FINGERPRINT: "afab363f857ad4cd8789c8bbb3941ae2"

  PRIVATE_KEY_B:
    """
    -----BEGIN RSA PRIVATE KEY-----
    MIICXAIBAAKBgQDF+c2DSG3RtghIvsUoqIaEsrmVKAnOrQaJLHU5RQBvwNMxJXwZ
    ssuSDDmI1GhVlMaAcQIXFuVxTyGMLbzQLC4nSMFH6Pc6RLYoN/2E/RIJelCHO28e
    TarDxJweTLFshy+zcXm8xFtkHDkUc87ZkeXmjX1qndMxg7YlQcMMBPzJiwIDAQAB
    AoGBAIau+AItPxDhPueGaQjNBZ63HAv+DhX9nimqBiGs8KwWSVbxAmlVOqqkCGwu
    3MAEE7sDpoFgwT0BsXf1EbOpqsc6gqwUHSzIS8QIj9zg18FKuCpcgsoQxS6/5v3d
    lm+utwBR0oy5I8xppsHHKGvXqC0xOIwPAviFbDKAA9WF9D1ZAkEA6A+1w3rMv/gH
    vID8YhAw1d06dNicGou40HcIn7AgmWRwNtmAPahGFT13IJZgRq9b4XoWtG4Th8aV
    SzuUjwV3tQJBANpl9Xy81DJ55oLHeT31AECr+icJ299gBS1KBfUBirzuyAzgLKhS
    JtI50bbRQ6LGqat7AlWK2u27aldbj7ofhD8CQCxnNSReTuc8kl5jX+dzqaSCXDkX
    aWc67PYWkLPdg59WNJKKM5uYozBVPoIhw/JCg5Y1QjrsBRipys9GazqilTECQH3R
    14exUZ5y0/Xr7VFgYHDhow/yghVCQDlDOANajA8kkWO5koC2M19RqBvmm0yfnwgH
    qeSWRmJHYpBJU5gqqAkCQDO04K/agnaVYE49nhOF4iFayS2006U2Z83hRIE1fQsP
    r1fapTBzsGosdKg7sNBH8am/zPGZEMJia9qfoJiNmUs=
    -----END RSA PRIVATE KEY-----
    """

  FINGERPRINT_B: "f9df70f799f933fe997312012a7ed369"

}
