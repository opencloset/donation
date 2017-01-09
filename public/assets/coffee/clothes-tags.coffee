$ ->
  $('#toggle-tags').click ->
    $('#list-tags').toggleClass('hide')

  $('#btn-checkall').click ->
    $('#clothes :checkbox').each ->
      return true if $(@).prop('disabled')
      $(@).prop('checked', true)

  $('#btn-uncheckall').click ->
    $('#clothes :checkbox').each ->
      return true if $(@).prop('disabled')
      $(@).prop('checked', false)

  $('#form-search').submit (e) ->
    e.preventDefault()
    $this = $(@)
    $q = $this.find('input[name=q]')
    code = $q.val().toUpperCase()
    $q.val('')

    return if $("#clothes li[data-code=#{code}]").length

    action = $this.prop('action')
    action = action.replace(/:code/, code)

    $.ajax action,
      type: 'GET'
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        data.n   = $('#clothes > li').length + 1
        template = JST['clothes/code']
        html     = template(data)
        $('#clothes').append(html)
      error: (jqXHR, textStatus, errorThrown) ->
      complete: (jqXHR, textStatus) ->

  $('#list-dropdown-status li > a').click (e) ->
    e.preventDefault()

    codes = []
    $('#clothes input:checked').each (i, el) ->
      codes.push $(el).val()
    codes = _.uniq(codes)
    return unless codes.length

    status_id = $(@).data('status-id')

    $.ajax '/clothes',
      type: 'PUT'
      dataType: 'json'
      data: $.param({ code: codes, status_id: status_id }, true)
      success: (data, textStatus, jqXHR) ->
        $.growl.notice({ title: "#{data.code.length}개 의류의 상태가 #{data.status.name}(으)로 변경되었습니다.", message: "#{data.code.join(', ')}" })
        $('#clothes ul.list-inline').each (i, el) ->
          $ul = $(el)
          return true unless $ul.find('input:checked').length
          $ul.find('span.label > small').html(data.status.name)
      error: (jqXHR, textStatus, errorThrown) ->
      complete: (jqXHR, textStatus) ->

  $('#list-dropdown-add-tags li > a').click (e) ->
    e.preventDefault()

    codes = []
    $('#clothes input:checked').each (i, el) ->
      codes.push $(el).val()
    codes = _.uniq(codes)
    return unless codes.length

    tag_id = $(@).data('tag-id')

    $.ajax '/clothes/tags',
      type: 'POST'
      dataType: 'json'
      data: $.param({ code: codes, tag_id: tag_id }, true)
      success: (data, textStatus, jqXHR) ->
        $.growl.notice({ title: "#{data.code.length}개의 의류에 #{data.tag.name} 태그가 추가되었습니다.", message: "#{data.code.join(', ')}" })
        $('#clothes ul.list-inline').each (i, el) ->
          $ul = $(el)
          return true unless $ul.find('input:checked').length
          return true if $ul.find("span.label-tag[data-tag-id=#{tag_id}]").length
          template = JST['clothes/list-item-tag']
          html     = template(data)
          $ul.append(html)
      error: (jqXHR, textStatus, errorThrown) ->
      complete: (jqXHR, textStatus) ->

  $('#list-dropdown-remove-tags li > a').click (e) ->
    e.preventDefault()

    codes = []
    $('#clothes input:checked').each (i, el) ->
      codes.push $(el).val()
    codes = _.uniq(codes)
    return unless codes.length

    tag_id = $(@).data('tag-id')

    $.ajax '/clothes/tags',
      type: 'DELETE'
      dataType: 'json'
      data: $.param({ code: codes, tag_id: tag_id }, true)
      success: (data, textStatus, jqXHR) ->
        $.growl.notice({ title: "#{data.code.length}개의 의류에 #{data.tag.name} 태그가 제거되었습니다.", message: "#{data.code.join(', ')}" })
        $('#clothes ul.list-inline').each (i, el) ->
          $ul = $(el)
          return true unless $ul.find('input:checked').length
          $span = $ul.find("span.label-tag[data-tag-id=#{tag_id}]")
          return true unless $span.length
          $span.parent().remove()
      error: (jqXHR, textStatus, errorThrown) ->
      complete: (jqXHR, textStatus) ->
