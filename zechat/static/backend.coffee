class zc.Backend extends zc.Controller

  initialize: ->
    @urls = @app.request('urls').backend

  auth: ->
    zc.post_json(@urls.challenge, {})

    .then (ch) =>
      identity = @app.request('identity')
      server_pubkey = ch.pubkey
      confirmation = zc.curve.encrypt(ch.challenge, identity.key(), server_pubkey)
      return {
          pubkey: identity.pubkey()
          signature: ch.signature
          confirmation: confirmation
      }

  save: (state) ->
    @auth()

    .then (auth) =>
      zc.post_json(@urls.save, _.extend({state: state}, auth))

    .then (resp) =>
      unless resp.ok?
        throw "failed to save state"


  load: ->
    @auth()

    .then (auth) =>
      zc.post_json(@urls.load, auth)

    .then (resp) =>
      return resp.state
