$ ->
  $('.agree').click ->
    $(@).prev().prop('checked', true)
