$ ->
  # Find the element for the Bootstrap Modal dialog
  dialog = $('div#browse-everything')

  # Define the (anonymous) constructor for the browse-everything behavior
  # @param obj
  # @param options
  initialize = (obj,options) ->
    # If the dialog could not be loaded, dynamically create it and append it to
    #   the DOM
    if $('div#browse-everything').length == 0
      dialog = $('<div tabindex="-1" id="browse-everything" class="ev-browser modal fade" aria-live="polite" role="dialog" aria-labelledby="beModalLabel"></div>').hide().appendTo('body')

    # Provide default options to the Modal plugin
    dialog.modal
      backdrop: 'static'
      show:     false

    # Initialize the ctx options Object
    # (This ensures that the ctx can pass functions for overriding event-driven
    #   behavior)
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

    # Set the current state on the DOM using the data-ev-state attribute
    $(obj).data('ev-state',ctx)
    ctx

  # Generates <input type="hidden"> elements using HTTP request parameters
  # @param data the HTTP request data (as a string)
  toHiddenFields = (data) ->
    fields = $.param(data)
      .split('&')
      .map (t) -> t.replace(/\+/g,' ').split('=',2)
    elements = $(fields).map () ->
      $("<input type='hidden'/>")
        .attr('name',decodeURIComponent(this[0]))
        .val(decodeURIComponent(this[1]))[0].outerHTML
    $(elements.toArray().join("\n"))

  # Updates the DOM by setting the "ev-selected" class on elements which have
  #   been selected (using the data-ev-location attribute)
  indicateSelected = () ->
    $('input.ev-url').each () ->
      $("*[data-ev-location='#{$(this).val()}']").addClass('ev-selected')

  # Determines whether or not at least child element of <input> has been
  #   selected within the <tr> rows of file entries
  # @param row the <tr> row element
  fileIsSelected = (row) ->
    result = false
    $('input.ev-url').each () ->
      if this.value == $(row).data('ev-location')
        result = true
    return result

  # For a given <tr> row element, toggle the Class and ensure that the checkboxes
  #   are appropriately updated
  # @param row the <tr> row element
  toggleFileSelect = (row) ->
    row.toggleClass('ev-selected')
    if row.hasClass('ev-selected')
      selectFile(row)
    else
      unselectFile(row)
    updateFileCount()

  # Given a selected <tr> row, ensure that the <input type="hidden"> elements
  #   are updated, as well as ensuring that the checkboxes are updated
  # Note that this dynamically creates the <input> elements and adds them to
  #   the DOM
  # @param row the <tr> row element
  selectFile = (row) ->
    target_form = $('form.ev-submit-form')
    file_location = row.data('ev-location')
    hidden_input = $("<input type='hidden' class='ev-url' name='selected_files[]'/>").val(file_location)
    target_form.append(hidden_input)
    unless $(row).find('.ev-select-file').prop('checked')
      $(row).find('.ev-select-file').prop('checked', true)

  # Given an unselected <tr> row, ensure that the <input type="hidden">
  #   elements are updated, as well as ensuring that the checkboxes are updated
  # Note that this retrieves the <input> elements and removes them from
  #   the DOM
  # @param row the <tr> row element
  unselectFile = (row) ->
    target_form = $('form.ev-submit-form')
    file_location = row.data('ev-location')
    $("form.ev-submit-form input[value='#{file_location}']").remove()
    if $(row).find('.ev-select-file').prop('checked')
        $(row).find('.ev-select-file').prop('checked', false)

  # Update the text within the .ev-status element after a file has been
  # selected
  updateFileCount = () ->
    count = $('input.ev-url').length
    files = if count == 1 then "file" else "files"
    $('.ev-status').html("#{count} #{files} selected")

  # Given a selected <tr> row, ensure trigger the expansion of the treetable
  #   node subtree (this models the browsing of directories)
  # Note that this is called after the tree itself has been updated with
  #   entries from the server
  # @param row the <tr> row element
  toggleBranchSelect = (row) ->
    if row.hasClass('collapsed')
      node_id = row.find('td.ev-file-name a.ev-link').attr('href')
      $('table#file-list').treetable('expandNode',node_id)

  # Given the set of all <tr> rows, ensure that each checkbox (for a file node)
  #   and branch/subtree (directory node) is selected, along with any child
  # nodes
  # @param rows the array of <tr> row elements
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

  # Initialize the jQuery treetable plugin given an existing <table> element
  # This handles the interaction of "expanding" nodes on the tree (in order to
  #   retrieve server-side generated View markup)
  # @param table the <table> element
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

  # This adjusts the width of the <table> columns <th> using the current width
  #   of the .ev-files element
  # @param table the <table> element
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

  # This retrieves files from the Rails endpoint using an AJAX request
  # @param node the treetable node for which children are retrieved
  # @param table the <table> element with the table of element nodes
  # @param progressIntervalID the ID used to update the progress of the
  #   response
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

  handleScroll = (event)->
    event.stopPropagation()
    event.preventDefault()

    table = $('#file-list')
    page = $('#file-list tfoot .ev-next-page').data('provider-contents-pages-next')

    scrolled_offset = $(this).scrollTop()
    height = $(this).innerHeight()
    scrolled_height = this.scrollHeight
    window_offset = Math.ceil(scrolled_offset + height, 1)

    return unless page? && window_offset >= scrolled_height

    provider_select = $('#provider-select')
    url = provider_select.val()
    table_body = table.find('tbody')
    last_row = table_body.find('tr:last')

    $.ajax
      url: url,
      data:
        accept: dialog.data('ev-state').opts.accept
        context: dialog.data('ev-state').opts.context
        page_token: page
    .done (data) ->
      new_table = $(data)
      new_rows = $(new_table).find('tbody tr')
      new_table_foot = $(new_table).find('tfoot')
      table.find('tfoot').replaceWith(new_table_foot)

      table.treetable("loadBranch", null, new_rows)

      last_row.focus()
      sizeColumns(table)
      indicateSelected()
    .fail (xhr,status,error) ->
      if (xhr.responseText.indexOf("Refresh token has expired") > -1)
        $('.ev-files').html("Your sessison has expired please clear your cookies.")
      else
        $('.ev-files').html(xhr.responseText)
    .always ->
      stopWait()

  ## Handlers for DOM events

  $(window).on('resize', -> sizeColumns($('table#file-list')))

  # Define the browseEverything jQuery plugin
  $.fn.browseEverything = (options) ->
    ctx = $(this).data('ev-state')

    # Unless options have been passed to the @data-ev-state attribute or
    #   initializer, default to all of the options within @data-* attributes
    options = $(this).data() unless (ctx? or options?)
    if options?
      # Reinitialize the ctx using the element passed to the initializer
      # (This is typically a <button> element)
      ctx = initialize(this[0], options)

      # Override the onClick event handler
      $(this).click () ->
        # Ensure that data-ev-state attribute is updated
        dialog.data('ev-state',ctx)

        # Using the options.opts.route to the Rails controller action, load the
        #   Bootstrap Modal with the server-generated markup
        dialog.load ctx.opts.route, () ->
          setTimeout refreshFiles, 500
          ctx.callbacks.show.fire()
          dialog.modal('show')

    # Provide a callback proxy for the options, or just define a set of methods
    #   which should be exposed to the jQuery plugin Object
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

  # Handle the event triggered by submitting the form with in the modal
  # Once the event has been triggered, <input> elements specifying the URLs for
  #   the file resources are appended to the DOM
  # @param event
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

  # Handle onClick events for links or containers for the file resource tree
  # Note: This handles both cases where a file/directory node is collapsed or
  #   expanded
  $(document).on 'click', '.ev-files .ev-container a.ev-link', (event) ->
    event.stopPropagation()
    event.preventDefault()
    row = $(this).closest('tr')
    action = if row.hasClass('expanded') then 'collapseNode' else 'expandNode'
    node_id = $(this).attr('href')
    $('table#file-list').treetable(action,node_id)

  # Handles the onChange event and refreshes the server-side HTML
  # Note: This is called when the <table> element is initially appended from
  #   the Rails View template
  $(document).on 'change', '.ev-providers select', (event) ->
    event.preventDefault()
    startWait()
    table_id = $(this).data('table-id')
    table = $(table_id)
    page = table.data('provider-contents-page-number')
    $.ajax
      url: $(this).val(),
      data:
        accept: dialog.data('ev-state').opts.accept
        context: dialog.data('ev-state').opts.context
        page: page
    .done (data) ->
      $('.ev-files').html(data)
      $('.ev-files').off 'scroll.browseEverything'
      $('.ev-files').on 'scroll.browseEverything', handleScroll
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
  if Rails?
    $.ajaxSetup({
        headers: { 'X-CSRF-TOKEN': (Rails || $.rails).csrfToken() || '' }
    });

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
