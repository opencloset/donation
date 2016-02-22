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
