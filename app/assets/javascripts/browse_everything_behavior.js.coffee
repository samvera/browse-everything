$ ->
  $(document).on 'click', '.ev-browser a', (event) ->
    event.preventDefault()
    $('.ev-files').load($(this).attr('href'))