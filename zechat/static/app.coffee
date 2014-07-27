zc = window.zc = {}


class zc.Peer

  constructor: (options) ->
    @fingerprint = options.fingerprint


class zc.Identity

  constructor: (options) ->
    @server = options.server

  send: (options) ->
    @server.send(
      text: options.text
      recipient: options.recipient.fingerprint
    )
