$ ->
  $('#category-toggle input').hide()
  $('#form-clothes button').hide()
  $('.js-category').click ->
    $('.js-category').removeClass('active')
    $('#category-toggle input').hide()
    $('#form-clothes button').show()
    $(@).addClass('active')
    category = $(@).data('category')
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
    for type in types
      $("##{type}").show()

  $('.label-category').click ->
    color = $(@).data('color')
    $('.label-category').removeClass('active')
    $(@).addClass('active')
    $("#color").val(color)
