$ ->
  $('.agree').click ->
    $(@).prev().prop('checked', true)

  $('#btn-info-detail').click ->
    $('#info-detail').toggleClass('hidden')
