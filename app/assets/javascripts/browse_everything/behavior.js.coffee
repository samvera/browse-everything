$ ->
  dialog = $('div#browse-everything')

  initialize = (obj,options) ->
    if $('div#browse-everything').length == 0
      dialog = $('<div tabindex="-1" id="browse-everything" class="ev-browser modal fade" aria-live="polite" role="dialog" aria-labelledby="beModalLabel"></div>').hide().appendTo('body')

    dialog.modal
      backdrop: 'static'
      show:     false
    ctx =
      opts: $.extend(true, {}, options)
      callbacks:
        show: $.Callbacks()
        done: $.Callbacks()
        cancel: $.Callbacks()
        fail: $.Callbacks()
    ctx.callback_proxy =
      show:   (func) -> ctx.callbacks.show.add(func)   ; return this
      done:   (func) -> ctx.callbacks.done.add(func)   ; return this
      cancel: (func) -> ctx.callbacks.cancel.add(func) ; return this
      fail:   (func) -> ctx.callbacks.fail.add(func)   ; return this
    $(obj).data('ev-state',ctx)
    ctx

  toHiddenFields = (data) ->
    fields = $.param(data)
      .split('&')
      .map (t) -> t.replace(/\+/g,' ').split('=',2)
    elements = $(fields).map () ->
      $("<input type='hidden'/>")
        .attr('name',decodeURIComponent(this[0]))
        .val(decodeURIComponent(this[1]))[0].outerHTML
    $(elements.toArray().join("\n"))

  indicateSelected = () ->
    $('input.ev-url').each () ->
      $("*[data-ev-location='#{$(this).val()}']").addClass('ev-selected')

  fileIsSelected = (row) ->
    result = false
    $('input.ev-url').each () ->
      if this.value == $(row).data('ev-location')
        result = true
    return result

  toggleFileSelect = (row) ->
    row.toggleClass('ev-selected')
    if row.hasClass('ev-selected')
      selectFile(row)
    else
      unselectFile(row)
    updateFileCount()

  selectFile = (row) ->
    target_form = $('form.ev-submit-form')
    file_location = row.data('ev-location')
    hidden_input = $("<input type='hidden' class='ev-url' name='selected_files[]'/>").val(file_location)
    target_form.append(hidden_input)
    unless $(row).find('.ev-select-file').prop('checked')
      $(row).find('.ev-select-file').prop('checked', true)

  unselectFile = (row) ->
    target_form = $('form.ev-submit-form')
    file_location = row.data('ev-location')
    $("form.ev-submit-form input[value='#{file_location}']").remove()
    if $(row).find('.ev-select-file').prop('checked')
        $(row).find('.ev-select-file').prop('checked', false)

  updateFileCount = () ->
    count = $('input.ev-url').length
    files = if count == 1 then "file" else "files"
    $('.ev-status').html("#{count} #{files} selected")

  toggleBranchSelect = (row) ->
    if row.hasClass('collapsed')
      node_id = row.find('td.ev-file-name a.ev-link').attr('href')
      $('table#file-list').treetable('expandNode',node_id)

  selectAll = (rows) ->
    rows.each () ->
      if $(this).data('tt-branch')
        box = $(this).find('#select_all')[0]
        $(box).prop('checked', true)
        $(box).prop('value', "1")
        toggleBranchSelect($(this))
      else
        toggleFileSelect($(this)) unless fileIsSelected($(this))

  selectChildRows = (row, action) ->
    $('table#file-list tr').each () ->
      if $(this).data('tt-parent-id')
        re = RegExp($(row).data('tt-id'), 'i')
        if $(this).data('tt-parent-id').match(re)
          if $(this).data('tt-branch')
            box = $(this).find('#select_all')[0]
            $(box).prop('value', action)
            if action == "1"
              $(box).prop("checked", true)
              node_id = $(this).find('td.ev-file-name a.ev-link').attr('href')
              $('table#file-list').treetable('expandNode',node_id)
            else
              $(box).prop("checked", false)
          else
            if action == "1"
              $(this).addClass('ev-selected')
              selectFile($(this)) unless fileIsSelected($(this))
            else
              $(this).removeClass('ev-selected')
              unselectFile($(this))
            updateFileCount()

  tableSetup = (table) ->
    table.treetable
      expandable: true
      onNodeCollapse: ->
        node = this;
        table.treetable("unloadBranch", node)
      onNodeExpand: ->
        node = this
        startWait()
        size = $(node.row).find('td.ev-file-size').text().trim()
        start = 1
        increment = 1
        if (size.indexOf("MB") >-1)
          start = 10
          increment = 5
        if (size.indexOf("KB") >-1)
          start = 50
          increment = 10
        setProgress(start)
        progressIntervalID = setInterval (->
          start = start + increment
          if start > 99
            start = 99
          setProgress(start)
        ), 2000
        setTimeout (->
          loadFiles(node, table, progressIntervalID)
        ), 10
    $("#file-list tr:first").focus()
    sizeColumns(table)

  sizeColumns = (table) ->
    full_width = $('.ev-files').width()
    table.width(full_width)
    set_size = (selector, pct) ->
      $(selector, table).width(full_width * pct).css('width',full_width * pct).css('max-width',full_width * pct)
    set_size '.ev-file', 0.4
    set_size '.ev-container', 0.4
    set_size '.ev-size', 0.1
    set_size '.ev-kind', 0.3
    set_size '.ev-date', 0.2

  loadFiles = (node, table, progressIntervalID)->
    $.ajax
      async: true # Must be false, otherwise loadBranch happens after showChildren?
      url: $('a.ev-link',node.row).attr('href')
      data:
        parent: node.row.data('tt-id')
        accept: dialog.data('ev-state').opts.accept
        context: dialog.data('ev-state').opts.context
    .done (html) ->
      setProgress('100')
      clearInterval progressIntervalID
      rows = $('tbody tr',$(html))
      table.treetable("loadBranch", node, rows)
      $(node).show()
      sizeColumns(table)
      indicateSelected()
      if $(node.row).find('#select_all')[0].checked
        selectAll(rows)
    .always ->
        clearInterval progressIntervalID
        stopWait()

  setProgress = (done)->
    $('.loading-text').text(done+'% complete')

  refreshFiles = ->
    $('.ev-providers select').change()

  startWait = ->
    $('.loading-progress').removeClass("hidden")
    $('body').css('cursor','wait')
    $("html").addClass("wait")
    $(".ev-browser").addClass("loading")
    $('.ev-submit').attr('disabled', true)

  stopWait = ->
    $('.loading-progress').addClass("hidden")
    $('body').css('cursor','default')
    $("html").removeClass("wait")
    $(".ev-browser").removeClass("loading")
    $('.ev-submit').attr('disabled', false)

  $(window).on('resize', -> sizeColumns($('table#file-list')))

  $.fn.browseEverything = (options) ->
    ctx = $(this).data('ev-state')
    options = $(this).data() unless (ctx? or options?)
    if options?
      ctx = initialize(this[0], options)
      $(this).click () ->
        dialog.data('ev-state',ctx)
        dialog.load ctx.opts.route, () ->
          setTimeout refreshFiles, 500
          ctx.callbacks.show.fire()
          dialog.modal('show')

    if ctx
      ctx.callback_proxy
    else
      {
        show: -> this
        done: -> this
        cancel: -> this
        fail: -> this
      }

  $.fn.browseEverything.toggleCheckbox = (box) ->
    if box.value == "0"
      $(box).prop('value', "1")
    else
      $(box).prop('value', "0")

  $(document).on 'ev.refresh', (event) -> refreshFiles()

  $(document).on 'click', 'button.ev-cancel', (event) ->
    event.preventDefault()
    dialog.data('ev-state').callbacks.cancel.fire()
    $('.ev-browser').modal('hide')

  $(document).on 'click', 'button.ev-submit', (event) ->
    event.preventDefault()
    $(this).button('loading')
    startWait()
    main_form = $(this).closest('form')
    resolver_url = main_form.data('resolver')
    ctx = dialog.data('ev-state')
    $(main_form).find('input[name=context]').val(ctx.opts.context)
    $.ajax resolver_url,
      type: 'POST'
      dataType: 'json'
      data: main_form.serialize()
    .done (data) ->
      if ctx.opts.target?
        fields = toHiddenFields({selected_files: data})
        $(ctx.opts.target).append($(fields))
      ctx.callbacks.done.fire(data)
    .fail (xhr,status,error) ->
      ctx.callbacks.fail.fire(status, error, xhr.responseText)
    .always ->
      $('body').css('cursor','default')
      $('.ev-browser').modal('hide')
      $('#browse-btn').focus()

  $(document).on 'click', '.ev-files .ev-container a.ev-link', (event) ->
    event.stopPropagation()
    event.preventDefault()
    row = $(this).closest('tr')
    action = if row.hasClass('expanded') then 'collapseNode' else 'expandNode'
    node_id = $(this).attr('href')
    $('table#file-list').treetable(action,node_id)

  $(document).on 'change', '.ev-providers select', (event) ->
    event.preventDefault()
    startWait()
    $.ajax
      url: $(this).val(),
      data:
        accept: dialog.data('ev-state').opts.accept
        context: dialog.data('ev-state').opts.context
    .done (data) ->
      $('.ev-files').html(data)
      indicateSelected();
      $('#provider_auth').focus();
      tableSetup($('table#file-list'))
    .fail (xhr,status,error) ->
      if (xhr.responseText.indexOf("Refresh token has expired")>-1)
        $('.ev-files').html("Your sessison has expired please clear your cookies.")
      else
        $('.ev-files').html(xhr.responseText)
    .always ->
      stopWait()

  $(document).on 'click', '.ev-providers a', (event) ->
    $('.ev-providers li').removeClass('ev-selected')
    $(this).closest('li').addClass('ev-selected')

  $(document).on 'click', '.ev-file a', (event) ->
    event.preventDefault()
    target = $(this).closest('*[data-ev-location]')
    toggleFileSelect(target)

  $(document).on 'click', '.ev-auth', (event) ->
    event.preventDefault()
    auth_win = window.open($(this).attr('href'))
    check_func = ->
      if auth_win.closed
        $('.ev-providers .ev-selected a').click()
      else
        window.setTimeout check_func, 1000
    check_func()

  $(document).on 'change', 'input.ev-select-all', (event) ->
    event.stopPropagation()
    event.preventDefault()
    $.fn.browseEverything.toggleCheckbox(this)
    action = this.value
    row = $(this).closest('tr')
    node_id = row.find('td.ev-file-name a.ev-link').attr('href')
    if row.hasClass('collapsed')
      $('table#file-list').treetable('expandNode',node_id)
    else
      selectChildRows(row, action)

  $(document).on 'change', 'input.ev-select-file', (event) ->
    event.stopPropagation()
    event.preventDefault()
    toggleFileSelect($(this).closest('tr'))


auto_toggle = ->
  triggers = $('*[data-toggle=browse-everything]')
  triggers.each () ->
    ctx = $(this).data('ev-state')
    $(this).browseEverything($(this).data()) unless ctx?

if Turbolinks? && Turbolinks.supported
  # Use turbolinks:load for Turbolinks 5, otherwise use the old way
  if (Turbolinks.BrowserAdapter)
    $(document).on 'turbolinks:load', auto_toggle
  else
    $(document).on 'page:change', auto_toggle
else
  $(document).ready auto_toggle
