$ ->
  $('#btn-toggle-parcel').click (e) ->
    $(@).hide()
    $('#form-parcel').removeClass('hide')

  $('#btn-cancel').click (e) ->
    $('#form-parcel').addClass('hide')
    $('#btn-toggle-parcel').show()
