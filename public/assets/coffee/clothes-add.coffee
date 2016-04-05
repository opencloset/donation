$ ->
  $('#category-toggle input').hide()
  $('#form-clothes button').hide()


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
    $.ajax "/clothes/code?category=#{category}",
      type: 'GET'
      success: (data, textStatus, jqXHR) ->
        $('#code').prop('placeholder', data.code)
      error: (jqXHR, textStatus, errorThrown) ->
        console.log textStatus

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
