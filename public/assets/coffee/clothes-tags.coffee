$ ->
  $('#toggle-tags').click ->
    $('#table-tags').toggleClass('hide')

  $('#form-search').submit (e) ->
    e.preventDefault()
    $this = $(@)
    $q = $this.find('input[name=q]')
    code = $q.val().toUpperCase()
    action = $this.prop('action')
    action = action.replace(/:code/, code)

    $.ajax action,
      type: 'GET'
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        template = JST['clothes/code']
        html     = template(data)
        $('#clothes').append(html)
      error: (jqXHR, textStatus, errorThrown) ->
      complete: (jqXHR, textStatus) ->
        $q.val('')
