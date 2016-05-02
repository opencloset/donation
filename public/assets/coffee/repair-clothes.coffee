$.fn.editable.defaults.mode = 'inline'
$.fn.editable.defaults.emptytext = '비어있음'
$.fn.editable.defaults.ajaxOptions =
  type: "PUT"
  dataType: 'json'

$ ->
  $('.repair-clothes-column-editable').editable
    params: (params) ->
      params[params.name] = params.value
      params

  $('.repair-clothes-column-done-editable').editable
    source: [
      {value: 0, text: ''},
      {value: 1, text: '수선완료'}
    ]
    params: (params) ->
      params[params.name] = params.value
      params

  $('.datepicker').datepicker
    todayHighlight: true
    autoclose:      true
    language:       'kr'
    orientation:    'bottom'
    format:         'yyyy-mm-dd'
  .on 'changeDate', (e) ->
    $this = $(@)
    name  = $this.prop('name')
    url   = $this.data('url')
    ymd   = e.currentTarget.value

    data       = {}
    data[name] = ymd

    $.ajax url,
      type: 'PUT'
      data: data
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        $this.removeClass('empty')

        # highlight when saving
        highlight = '#FFFF80'
        bgColor = $this.css('background-color')
        $this.css('background-color', highlight)
        setTimeout ->
          $this.css('background-color', bgColor)
          $this.addClass('editable-bg-transition')
          setTimeout ->
            $this.removeClass('editable-bg-transition')
          , 1700
        , 10
      error: (jqXHR, textStatus, errorThrown) ->
      complete: (jqXHR, textStatus) ->
