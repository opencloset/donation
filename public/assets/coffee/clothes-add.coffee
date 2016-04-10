$ ->
  $('#category-toggle input').hide()
  $('#form-clothes button').hide()
  $('[data-toggle="tooltip"]').tooltip { placement: 'right' }

  $('.js-category').click ->
    $('.js-category').removeClass('active')
    $('#category-toggle input').hide()
    $('#form-clothes button').show()
    $(@).addClass('active')
    category = $(@).data('category')
    $('#category').val(category)
    types = switch category
      when 'jacket'    then [ 'bust', 'arm', 'topbelly', 'belly'         ]
      when 'pants'     then [ 'waist', 'hip', 'thigh', 'length'          ]
      when 'shirt'     then [ 'neck', 'bust', 'arm'                      ]
      when 'waistcoat' then [ 'topbelly'                                 ]
      when 'coat'      then [ 'bust', 'arm'                              ]
      when 'onepiece'  then [ 'bust', 'waist', 'hip', 'arm', 'length'    ]
      when 'skirt'     then [ 'waist', 'hip', 'length'                   ]
      when 'blouse'    then [ 'bust', 'arm'                              ]
      when 'belt'      then [ 'length'                                   ]
      when 'shoes'     then [ 'foot'                                     ]
      else []
    $("##{type}").show() for type in types

  $('.label-category').click ->
    color = $(@).data('color')
    $('.label-category').removeClass('active')
    $(@).addClass('active')
    $("#color").val(color)

  $('.btn-discard').click (e) ->
    e.preventDefault()
    $('#status-id').val($(@).data('status-id'))
    $('#discard').val('1')
    $(@).closest('form').submit()

  $('#btn-sms-send').click ->
    $form = $('#form-sms')
    action = $form.attr('action')
    method = $form.attr('method')
    $.ajax action,
      type: method
      data: $form.serialize()
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        $donationForm = $('#donation-form')
        unless $donationForm
          $.growl.notice({ title: 'Sent a SMS', message: "#{data.text}" })
          return

        id = $donationForm.data('form-id')
        $.ajax "/forms/#{id}",
          type: 'PUT'
          dataType: 'json'
          data: { status: 'registered' }
          success: (data, textStatus, jqXHR) ->
            location.reload()
          error: (jqXHR, textStatus, errorThrown) ->
            console.log textStatus
          complete: (jqXHR, textStatus) ->

      error: (jqXHR, textStatus, errorThrown) ->
        $.growl.error({ title: textStatus, message: "#{jqXHR.responseJSON.error}" })
      complete: (jqXHR, textStatus) ->
        $form.get(0).reset()
