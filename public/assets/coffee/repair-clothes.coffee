$.fn.editable.defaults.ajaxOptions =
  type: "PUT"
  dataType: 'json'

$ ->
  $('.repair-clothes-column').editable
    params: (params) ->
      params[params.name] = params.value
      params
