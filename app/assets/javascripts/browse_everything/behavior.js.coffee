$ ->
  $('*[data-toggle=browse-everything]').click () ->
      dialog = $('div#browse-everything')
      if dialog.length == 0
        dialog = $('<div id="browse-everything" class="modal hide fade"></div>').appendTo('body')
      dialog.load $(this).data('route'), () ->
        dialog.modal()

  $(document).on 'click', 'button.ev-cancel', (event) ->
    event.preventDefault();
    $(this).closest('.modal').modal('hide')

  $(document).on 'click', '.ev-container a', (event) ->
    event.preventDefault()
    $('.ev-files').load $(this).attr('href'), ->
      $('input.ev-url').each () ->
        $("*[data-ev-location='#{$(this).val()}']").addClass('ev-selected')

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
