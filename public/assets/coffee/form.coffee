$ ->
  $('#btn-toggle-parcel').click (e) ->
    $(@).hide()
    $('#form-parcel').removeClass('hide')

  $('#btn-cancel').click (e) ->
    $('#form-parcel').addClass('hide')
    $('#btn-toggle-parcel').show()

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
