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

  $('.repair-clothes-column-alteration-at-editable').editable
    source: [
      {value: '밀라노', text: '밀라노'},
      {value: '단골', text: '단골'}
      {value: '미도', text: '미도'}
      {value: '기타', text: '기타'}
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

  $('.collapse.bottom').on 'show.bs.collapse', ->
    id   = $(@).prop('id')
    code = $(@).data('code')
    $.ajax "/clothes/#{code}/resize",
      type: 'GET'
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        $("##{id} .diff.hljs").html(data.diff.bottom)
        hljs.highlightBlock($("##{id} .diff.hljs").get(0))
        top_id = id.replace /bottom/, 'top'
        $("##{top_id} .diff.hljs").html(data.diff.top)
        hljs.highlightBlock($("##{top_id} .diff.hljs").get(0))
        $("##{top_id}").collapse('show')
      error: (jqXHR, textStatus, errorThrown) ->
      complete: (jqXHR, textStatus) ->

  $('.collapse.bottom').on 'hide.bs.collapse', ->
    id     = $(@).prop('id')
    top_id = id.replace /bottom/, 'top'
    $("##{top_id}").collapse('hide')
