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


describe 'conversation', ->

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

  FINGERPRINT = "afab363f857ad4cd8789c8bbb3941ae2"

  it 'should send a message and receive it back', (done) ->
    identity_json = JSON.stringify(key: PRIVATE_KEY)

    $app = $('<div>')
    app = zc.create_app(
      urls: zc.TESTING_URL_MAP
      el: $app[0]
      local_storage: new zc.MockLocalStorage(identity: identity_json)
    )

    zc.waitfor(-> zc.some($app.find('.conversation-compose')))
    .then ->
      $form = $app.find('.conversation-compose form')
      $form.find('[name=message]').val('hello world')
      $form.submit()

      get_messages = ->
        $history = $app.find('.conversation-history')
        messages = $history.find('.message-text').text()
        return messages if messages.length > 0

      return zc.waitfor(get_messages, 3000)
    .then (messages) ->
      expect(messages).toEqual("hello world")
    .catch (err) ->
      if err == 'timeout'
        expect('timed out').toBe(false)
        return
      throw(err)
    .finally ->
      zc.remove_handlers(app)
      done()
