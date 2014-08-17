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


zc.waitevent = (obj, name) ->
  deferred = Q.defer()
  obj.once('ready', -> deferred.resolve(arguments))
  return deferred.promise


zc.some = ($qs) ->
  return $qs if $qs.length > 0


class zc.MockLocalStorage

  constructor: (data) -> @_data = _.extend({}, data)

  getItem: (key) -> @_data[key]

  setItem: (key, value) -> @_data[key] = value


zc.fixtures = {

  A_KEY: 'sk:VrIuRMeVZkmqlS9Sa9VRritZ1eVmnyJcZZFKJUkdnvk='
  A_PUBKEY: 'pk:B8dnDDjozeRUBsMFlPiWL4HR6kLEa9WyVRga4Q/CoXY='

  B_KEY: 'sk:NuwWzeSWynTxvBfNxi1z5UwG7AtKwwQYpW0GlDde4Fs='
  B_PUBKEY: 'pk:YCBnGbI2GbfWjmJl22o4IH3sIACU8Sv58fcxfDQojhI='

  A_B_ENCRYPTED: 'msg:zc+OgEhoQm3Yu8vqsFcuvzc0FJuQ2au4+wrxt8hGkss1jDAFXEMRoRU6+g=='

  PASSWORD: 'hello world'
  HASHED: 'sk:LRSKXz3q8Pfv3s2TMyiowXj2C5YjJ2+9WMFU4MeEk9o='

}


zc.create_testing_app = (options={}) ->
  _.defaults(options, {
    urls: zc.TESTING_URL_MAP
    el: $('<div>')[0]
  })

  app = null

  return (
    zc.create_app(options)

    .then (new_app) ->
      app = new_app
      zc.waitevent(app.request('client'), 'ready')

    .then ->
      return app
  )
