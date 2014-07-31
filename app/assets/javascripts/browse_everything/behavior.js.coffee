$ ->
  dialog = $('div#browse-everything')

  initialize = (obj,options) ->
    if $('div#browse-everything').length == 0
      dialog = $('<div id="browse-everything" class="ev-browser modal fade"></div>').hide().appendTo('body')
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
    $(obj).data('context',ctx)
    ctx

  toHiddenFields = (data) ->
    fields = $.param(data)
      .split('&')
      .map (t) -> t.split('=',2)
    elements = $(fields).map () ->
      $("<input type='hidden'/>")
        .attr('name',decodeURIComponent(this[0]))
        .val(decodeURIComponent(this[1]))[0].outerHTML
    $(elements.toArray().join("\n"))

  indicateSelected = () ->
    $('input.ev-url').each () ->
      $("*[data-ev-location='#{$(this).val()}']").addClass('ev-selected')

  tableSetup = (table) ->
    table.treetable
      expandable: true
      onNodeCollapse: ->
        node = this;
        table.treetable("unloadBranch", node)
      onNodeExpand: ->
        node = this
        $('body').css('cursor','wait')
        $.ajax
          async: false # Must be false, otherwise loadBranch happens after showChildren?
          url: $('a.ev-link',node.row).attr('href')
          data:
            accept: dialog.data('context').opts.accept
            context: dialog.data('context').opts.context
        .done (html) ->
          rows = $('tbody tr',$(html))
          table.treetable("loadBranch", node, rows)
          sizeColumns(table)
          indicateSelected()
        .always ->
          $('body').css('cursor','default')
    sizeColumns(table)
    
  sizeColumns = (table) ->
    full_width = $('.ev-files').width()
    table.width(full_width)
    set_size = (selector, pct) ->
      $(selector, table).width(full_width * pct).css('width',full_width * pct).css('max-width',full_width * pct)
    set_size '.ev-file', 0.4
    set_size '.ev-size', 0.1
    set_size '.ev-kind', 0.3
    set_size '.ev-date', 0.2

  $(window).on('resize', -> sizeColumns($('table#file-list')))

  $.fn.browseEverything = (options) ->
    ctx = $(this).data('context')
    if options?
      ctx = initialize(this[0], options)
      $(this).click () ->
        dialog.data('context',ctx)
        dialog.load ctx.opts.route, () -> 
          action = -> $('.ev-providers select').change()
          setTimeout action, 500
          ctx.callbacks.show.fire()
          dialog.modal('show')
    ctx.callback_proxy

  $(document).on 'click', 'button.ev-cancel', (event) ->
    event.preventDefault()
    dialog.data('context').callbacks.cancel.fire()
    $('.ev-browser').modal('hide')

  $(document).on 'click', 'button.ev-submit', (event) ->
    event.preventDefault()
    $(this).button('loading')
    $('body').css('cursor','wait')
    main_form = $(this).closest('form')
    resolver_url = main_form.data('resolver')
    ctx = dialog.data('context')
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

  $(document).on 'click', '.ev-files table tr', (event) ->
    $('a.ev-link',this).click() unless event.target.nodeName == 'A'
    
  $(document).on 'click', '.ev-files .ev-container a.ev-link', (event) ->
    event.stopPropagation()
    event.preventDefault()
    row = $(this).closest('tr')
    action = if row.hasClass('expanded') then 'collapseNode' else 'expandNode'
    node_id = $(this).attr('href')
    $('table#file-list').treetable(action,node_id)

  $(document).on 'change', '.ev-providers select', (event) ->
    event.preventDefault()
    $('body').css('cursor','wait')
    $.ajax 
      url: $(this).val(),
      data:
        accept: dialog.data('context').opts.accept
        context: dialog.data('context').opts.context
    .done (data) ->
      $('.ev-files').html(data)
      indicateSelected();
      tableSetup($('table#file-list'))
    .fail (xhr,status,error) ->
      $('.ev-files').html(xhr.responseText)
    .always ->
      $('body').css('cursor','default')

  $(document).on 'click', '.ev-providers a', (event) ->
    $('.ev-providers li').removeClass('ev-selected')
    $(this).closest('li').addClass('ev-selected')

  $(document).on 'click', '.ev-file a', (event) ->
    event.preventDefault()
    target = $(this).closest('*[data-ev-location]')
    target_form = $('form.ev-submit-form')
    file_location = target.data('ev-location')
    target.toggleClass('ev-selected')
    if target.hasClass('ev-selected')
      hidden_input = $("<input type='hidden' class='ev-url' name='selected_files[]'/>").val(file_location)
      target_form.append(hidden_input)
    else
      $("form.ev-submit-form input[value='#{file_location}']").remove()

    count = $('input.ev-url').length
    files = if count == 1 then "file" else "files"
    $('.ev-status').html("#{count} #{files} selected")

  $(document).on 'click', '.ev-auth', (event) ->
    event.preventDefault()
    auth_win = window.open($(this).attr('href'))
    check_func = ->
      if auth_win.closed
        $('.ev-providers .ev-selected a').click()
      else
        window.setTimeout check_func, 1000
    check_func()

auto_toggle = ->
  triggers = $('*[data-toggle=browse-everything]')
  triggers.each () -> $(this).browseEverything($(this).data())

if Turbolinks?
  $(document).on 'page:change', auto_toggle
else
  $(document).ready auto_toggle
