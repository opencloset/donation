$ ->
  $('.btn-copy-to-clipboard').click ->
    $this = $(@)
    text  = $this.prev().text().trim()

    textarea = document.createElement("textarea")
    textarea.style.position = 'fixed'
    textarea.style.top = 0
    textarea.style.left = 0
    textarea.value = text

    document.body.appendChild(textarea)

    textarea.select()

    bool = false
    msg  = 'copy failed'
    try
      bool = document.execCommand('copy')
      msg  = 'copied' if bool
    catch error
      console.log "copy failed: #{error}"
    finally
      document.body.removeChild(textarea)
      $this.tooltip
        placement: 'right'
        title: msg
      .on 'hidden.bs.tooltip', ->
        $this.tooltip('destroy')
      .tooltip('show')
