$ ->
  $('#btn-toggle-parcel').click (e) ->
    $('#form-parcel').removeClass('hide')

  $('#btn-comment').click (e) ->
    $('#form-comment').removeClass('hide')

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

  $('#btn-returning:not(.disabled)').click (e) ->
    $this = $(@)
    $this.addClass('disabled')
    phone = $this.data('phone')
    text = $this.attr('title')
    $.ajax "/api/sms",
      type: 'POST'
      data: { to: phone, text: text }
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        $.growl.notice({ message: "반송안내문자를 전송하였습니다" });
        $('.sms-help li:nth-child(3) i').removeClass('fa-envelope-o')
          .addClass('fa-envelope')

      mask = $('.sms-help').data('mask')
      $.ajax "#{location.href}",
        type: 'PUT'
        dataType: 'json'
        data: { sms_bitmask: mask | 2**1 }
        error: (jqXHR, textStatus, errorThrown) ->
          $.growl.error({ message: textStatus });

      error: (jqXHR, textStatus, errorThrown) ->
        error = jqXHR.responseJSON?.error
        error = textStatus unless error
        $.growl.error({ message: error });
      complete: (jqXHR, textStatus) ->
        $this.removeClass('disabled')
