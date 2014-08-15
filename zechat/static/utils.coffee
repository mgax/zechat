zc.utcnow_iso = ->
  (new Date()).toJSON()


zc.serialize_form = (el) ->
  pairs = $(el).serializeArray()
  return _.object(_.pluck(pairs, 'name'), _.pluck(pairs, 'value'))


zc.post_json = (url, data, callback) ->
  $.ajax(
    type: "POST"
    url: url
    data: JSON.stringify(data)
    contentType: "application/json"
    dataType: "json"
    success: callback
  )


zc.pad_base64 = (text) ->
  while text.length % 4 != 0
    text = text + '='
  return text


zc.random_bytes = (size) ->
  data = new Uint8Array(size)
  window.crypto.getRandomValues(data)
  return Q(data)


zc.b64encode = (text) ->
  return zc.pad_base64(utf8tob64(text))


zc.b64decode = (data) ->
  return b64toutf8(data)


zc.b64frombytes = (bytes) ->
  return window.btoa(String.fromCharCode.apply(String, bytes))


zc.b64tobytes = (data) ->
  return get_char_codes(window.atob(data))


zc.b64fromu8array = (arr) ->
  return btoa(zc.nacl.decode_latin1(arr))


zc.b64tou8array = (data) ->
  return new Uint8Array(zc.b64tobytes(data))


zc.u8cat = (a, b) ->
  rv = new Uint8Array(a.byteLength + b.byteLength)
  rv.set(a, 0)
  rv.set(b, a.byteLength)
  return rv


Handlebars.registerHelper 'format_time', (iso_time) ->
  time = d3.time.format.iso.parse(iso_time)
  return d3.time.format('%b-%-d %H:%M')(time)


Backbone.Marionette.TemplateCache.prototype.loadTemplate = (name) ->
  $('script[id="' + name + '"]').text()


Backbone.Marionette.TemplateCache.prototype.compileTemplate = (src) ->
  Handlebars.compile(src)
