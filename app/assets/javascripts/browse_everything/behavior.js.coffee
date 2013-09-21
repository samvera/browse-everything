$(document).ready ->
  opts = {}
  promise = null

  initialize = (options) ->
    opts = $.extend(true, {}, options)
    unless opts.datatype?
      opts.datatype = if opts.target then 'html' else 'json'

  $.fn.browseEverything = (options) ->
    initialize(options)

    dialog = $('div#browse-everything')
    if dialog.length == 0
      dialog = $('<div id="browse-everything" class="ev-browser modal hide fade"></div>').appendTo('body')
    dialog.load opts.route, () ->
      dialog.modal()
    promise = $.Deferred()
    return promise

  $('*[data-toggle=browse-everything]').click () ->
      $(this).browseEverything($(this).data())

  $(document).on 'click', 'button.ev-cancel', (event) ->
    event.preventDefault()
    $('.ev-browser').trigger('cancel')
    $('.ev-browser').modal('hide')

  $(document).on 'click', 'button.ev-submit', (event) ->
    event.preventDefault()
    $(this).button('loading')
    $('body').css('cursor','wait')
    main_form = $(this).closest('form')
    resolver_url = main_form.data('resolver')
    $.ajax resolver_url,
      type: 'POST'
      dataType: opts.datatype
      data: main_form.serialize()
    .done (data) ->
      if opts.target?
        $(opts.target).append($(data))
      promise.resolve(data)
    .fail (xhr,status,error) ->
      promise.reject(status, error, xhr.responseText)
    .always ->
      $('body').css('cursor','default')
      $('.ev-browser').modal('hide')
      promise.notify()

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
