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
      {value: 1, text: '치수변경'},
      {value: 2, text: '수선완료'}
    ]
    params: (params) ->
      params[params.name] = params.value
      params
    success: (res, newValue) ->
      v    = parseInt(newValue)
      $tr  = $(@).closest('tr')
      $btn = $tr.find('td:last .btn-resize')
      boolean = if v then true else false
      $btn.prop('disabled', boolean)

      return unless v is 2

      $input = $tr.find('input[name="pickup_date"]')
      $input.val(res.pickup_date).removeClass('empty')

  $('.repair-clothes-column-alteration-at-editable').editable
    success: -> location.reload()
    source: [
      {value: '밀라노', text: '밀라노'},
      {value: '단골', text: '단골'}
      {value: '자체수선', text: '자체수선'}
      {value: '구서방네', text: '구서방네'}
      {value: '라이벌', text: '라이벌'}
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

  $('.btn-preview').click (e) ->
    $this    = $(@)
    $tr      = $(@).closest('tr')
    code     = $this.data('code')
    $options = $this.closest('td').find('.options')

    $top            = $tr.children('.top')
    $bottom         = $tr.children('.bottom')
    $preview_top    = $top.children('.preview')
    $preview_bottom = $bottom.children('.preview')

    unless $options.hasClass('hidden')
      $preview_top.toggleClass('hidden')
      $preview_bottom.toggleClass('hidden')
      $options.toggleClass('hidden')
      return

    $form  = $options.children('form')
    params = $form.serialize()

    $.ajax "#{$form.prop('action')}?#{params}",
      type: 'GET'
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        if data.diff.top
          $hljs = $preview_top.find('.hljs')
          $hljs.html(data.diff.top)
          hljs.highlightBlock($hljs.get(0))

          $desc = $preview_top.children('.desc').empty()
          _.each data.messages.top, (el) ->
            if /수선/.test(el)
              $desc.append("<li class=\"ignore-item\">#{el}</li>")
            else
              $desc.append("<li>#{el}</li>")

        if data.diff.bottom
          $hljs = $preview_bottom.find('.hljs')
          $hljs.html(data.diff.bottom)
          hljs.highlightBlock($hljs.get(0))

          $desc = $preview_bottom.children('.desc').empty()
          _.each data.messages.bottom, (el) ->
            if /수선/.test(el)
              $desc.append("<li class=\"ignore-item\">#{el}</li>")
            else
              $desc.append("<li>#{el}</li>")

      error: (jqXHR, textStatus, errorThrown) ->
        console.log textStatus and alert 'error'
      complete: (jqXHR, textStatus) ->
        $preview_top.toggleClass('hidden')
        $preview_bottom.toggleClass('hidden')
        $options.toggleClass('hidden')

  $('table').on 'click', '.btn-refresh', (e) ->
    $(@).closest('td').children('.btn-preview').trigger('click').trigger('click')

  $('.btn-resize').click ->
    $this = $(@)
    $form = $this.closest('td').find('form')
    code  = $this.data('code')

    params = $form.serialize()

    ignore = $this.closest('tr').find('.ignore-item.ignore')
    _.each ignore, (el) ->
      params = "#{params}&ignore=#{$(el).text().substring(5)}"

    $.ajax "/clothes/#{code}/suggestion",
      type: 'PUT'
      dataType: 'json'
      data: params
      success: (data, textStatus, jqXHR) ->
        $this.closest('tr').find('td:first a').editable('setValue', data.repair.done)
        $this.prev().trigger('click').trigger('click')
        $this.prop('disabled', true)
      error: (jqXHR, textStatus, errorThrown) ->
        console.log textStatus and alert 'error'
      complete: (jqXHR, textStatus) ->

  $('.btn-reset-row').click ->
    code = $(@).data('code')
    $.ajax "/clothes/repair/#{code}",
      type: 'PUT'
      dataType: 'json'
      data: { done: 3 }
      success: (data, textStatus, jqXHR) ->
        location.reload()
      error: (jqXHR, textStatus, errorThrown) ->
        console.log textStatus and alert 'error'
      complete: (jqXHR, textStatus) ->

  $('.table').on 'click', '.ignore-item', (e) ->
    ignore = $(@).hasClass('ignore')
    text = $(@).text()
    if ignore
      $(@).html("#{text}")
    else
      $(@).html("<s>#{text}</s>")

    $(@).toggleClass('ignore')
