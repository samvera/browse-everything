$(document).on 'page:change' ->
  context = {}
  active = null
  dialog = $('div#browse-everything')

  initialize = (obj,options) ->
    if $('div#browse-everything').length == 0
      dialog = $('<div id="browse-everything" class="ev-browser modal fade"></div>').hide().appendTo('body')
    dialog.modal({ backdrop: 'static', show: false });
    context[obj] = 
      opts: $.extend(true, {}, options)
      callbacks:
        done: $.Callbacks()
        cancel: $.Callbacks()
        fail: $.Callbacks()
    ctx = context[obj]
    ctx.callback_proxy = 
      done:   (func) -> ctx.callbacks.done.add(func)   ; return this
      cancel: (func) -> ctx.callbacks.cancel.add(func) ; return this
      fail:   (func) -> ctx.callbacks.fail.add(func)   ; return this
    ctx

  toHiddenFields = (data) ->
    fields = $.param(data)
      .split('&')
      .map (t) -> t.split('=',2)
    elements = $(fields).map () ->
      "<input type='hidden' name='#{decodeURIComponent(this[0])}' value='#{decodeURIComponent(this[1])}'/>"
    $(elements.toArray().join("\n"))

  $.fn.browseEverything = (options) ->
    if options?
      initialize(this[0], options)
      $(this).click () ->
        active = context[this]
        dialog.load active.opts.route, () -> dialog.modal('show')
    context[this[0]].callback_proxy

  triggers = $('*[data-toggle=browse-everything]')
  triggers.each () -> $(this).browseEverything($(this).data())

  $(document).on 'click', 'button.ev-cancel', (event) ->
    event.preventDefault()
    active.callbacks.cancel.fire()
    $('.ev-browser').modal('hide')

  $(document).on 'click', 'button.ev-submit', (event) ->
    event.preventDefault()
    $(this).button('loading')
    $('body').css('cursor','wait')
    main_form = $(this).closest('form')
    resolver_url = main_form.data('resolver')
    $.ajax resolver_url,
      type: 'POST'
      dataType: 'json'
      data: main_form.serialize()
    .done (data) ->
      if active.opts.target?
        fields = toHiddenFields({selected_files: data})
        $(active.opts.target).append($(fields))
      active.callbacks.done.fire(data)
    .fail (xhr,status,error) ->
      active.callbacks.fail.fire(status, error, xhr.responseText)
    .always ->
      $('body').css('cursor','default')
      $('.ev-browser').modal('hide')

  $(document).on 'click', '.ev-container a', (event) ->
    event.preventDefault()
    $('body').css('cursor','wait')
    $.ajax($(this).attr('href'))
    .done (data) ->
      $('.ev-files').html(data)
      $('input.ev-url').each () ->
        $("*[data-ev-location='#{$(this).val()}']").addClass('ev-selected')
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
      hidden_input = $("<input type='hidden' class='ev-url' name='selected_files[]' value='#{file_location}'>")
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

$ ->
  $(document).trigger 'page:change'