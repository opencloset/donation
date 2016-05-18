$ ->
  $('#btn-toggle-parcel').click (e) ->
    $('#form-parcel').removeClass('hide')

  $('#btn-comment').click (e) ->
    $('#form-comment').removeClass('hide')

  $('#btn-sms').click (e) ->
    $('#form-sms').removeClass('hide')

  $('.btn-cancel').click (e) ->
    $(@).closest('form').addClass('hide')

  $('a.status').click (e) ->
    e.preventDefault()
    status = $(@).children('span').data('status')
    $.ajax "#{location.href}",
      type: 'PUT'
      dataType: 'json'
      data: { status: status }
      success: (data, textStatus, jqXHR) ->
        location.reload()
      error: (jqXHR, textStatus, errorThrown) ->
      complete: (jqXHR, textStatus) ->

  $("#btn-user-add:not('disabled')").click (e) ->
    $this = $(@)
    $this.addClass('disabled')
    $.ajax "/users",
      type: 'POST'
      data: { form_id: location.pathname.split('/').pop() }
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        location.reload()
      error: (jqXHR, textStatus, errorThrown) ->
      complete: (jqXHR, textStatus) ->
        $this.removeClass('disabled')

  $('#form-sms').submit (e) ->
    e.preventDefault()
    $this = $(@)
    $.ajax $this.attr('action'),
      type: $this.attr('method')
      data: $this.serialize()
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        $.growl.notice({ title: 'Sent a SMS', message: "#{data.text}" })
      error: (jqXHR, textStatus, errorThrown) ->
        $.growl.error({ title: textStatus, message: "#{jqXHR.responseJSON.error}" })
      complete: (jqXHR, textStatus) ->
        $this.find('textarea').val('')
        $this.find('.btn-cancel').trigger('click')

  ## TODO: clothes-add.coffee 와 코드 중복
  $('.checkbox-suit').change ->
    code    = $(@).data('clothes-code')
    checked = $(@).prop('checked')
    return unless checked

    code_top = code_bottom = ''
    $('.checkbox-suit:checked').each (i, el) ->
      code     = $(el).data('clothes-code')
      category = $(el).data('category')
      switch category
        when 'jacket'
          code_top = code
        when 'pants', 'skirt'
          code_bottom = code
        else ''

    return unless code_top
    return unless code_bottom

    $.ajax '/suit',
      type: 'POST'
      data: { code_top: code_top, code_bottom: code_bottom }
      success: (data, textStatus, jqXHR) ->
        location.reload()
      error: (jqXHR, textStatus, errorThrown) ->
        json = JSON.parse(jqXHR.responseText)
        $.growl.error({ title: textStatus, message: json.error.str })
      complete: (jqXHR, textStatus) ->
