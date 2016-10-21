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
      when 'jacket'    then [ 'bust', 'arm', 'topbelly', 'belly', 'length' ]
      when 'pants'     then [ 'waist', 'hip', 'thigh', 'length', 'cuff'    ]
      when 'shirt'     then [ 'neck', 'bust', 'arm'                        ]
      when 'waistcoat' then [ 'topbelly'                                   ]
      when 'coat'      then [ 'bust', 'arm'                                ]
      when 'onepiece'  then [ 'bust', 'waist', 'hip', 'arm', 'length'      ]
      when 'skirt'     then [ 'waist', 'hip', 'length'                     ]
      when 'blouse'    then [ 'bust', 'arm'                                ]
      when 'belt'      then [ 'length'                                     ]
      when 'shoes'     then [ 'foot'                                       ]
      when 'misc'      then [                                              ]
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

  $('#code').on 'keydown', (e) ->
    e.preventDefault() if e.which is 13

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

  $('#btn-quantity').click (e) ->
    $('#fds-quantity').toggleClass('hide')
