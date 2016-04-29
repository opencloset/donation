$.fn.editable.defaults.mode = 'inline'
$.fn.editable.defaults.emptytext = '비어있음'
$.fn.editable.defaults.ajaxOptions =
  type: "PUT"
  dataType: 'json'

$ ->
  $('.repair-clothes-column').editable
    params: (params) ->
      params[params.name] = params.value
      params

  $('.repair-clothes-column-done').editable
    source: [
      {value: 0, text: ''},
      {value: 1, text: '수선완료'}
    ]
    params: (params) ->
      params[params.name] = params.value
      params
