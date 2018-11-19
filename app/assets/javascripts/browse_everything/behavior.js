/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
$(function() {
  let dialog = $('div#browse-everything');

  const initialize = function(obj,options) {
    if ($('div#browse-everything').length === 0) {
      dialog = $('<div tabindex="-1" id="browse-everything" class="ev-browser modal fade" aria-live="polite" role="dialog" aria-labelledby="beModalLabel"></div>').hide().appendTo('body');
    }

    dialog.modal({
      backdrop: 'static',
      show:     false
    });
    const ctx = {
      opts: $.extend(true, {}, options),
      callbacks: {
        show: $.Callbacks(),
        done: $.Callbacks(),
        cancel: $.Callbacks(),
        fail: $.Callbacks()
      }
    };
    ctx.callback_proxy = {
      show(func) { ctx.callbacks.show.add(func);    return this; },
      done(func) { ctx.callbacks.done.add(func);    return this; },
      cancel(func) { ctx.callbacks.cancel.add(func);  return this; },
      fail(func) { ctx.callbacks.fail.add(func);    return this; }
    };
    $(obj).data('ev-state',ctx);
    return ctx;
  };

  const toHiddenFields = function(data) {
    const fields = $.param(data)
      .split('&')
      .map(t => t.replace(/\+/g,' ').split('=',2));
    const elements = $(fields).map(function() {
      return $("<input type='hidden'/>")
        .attr('name',decodeURIComponent(this[0]))
        .val(decodeURIComponent(this[1]))[0].outerHTML;
    });
    return $(elements.toArray().join("\n"));
  };

  const indicateSelected = () =>
    $('input.ev-url').each(function() {
      return $(`*[data-ev-location='${$(this).val()}']`).addClass('ev-selected');
    })
  ;

  const fileIsSelected = function(row) {
    let result = false;
    $('input.ev-url').each(function() {
      if (this.value === $(row).data('ev-location')) {
        return result = true;
      }
    });
    return result;
  };

  const toggleFileSelect = function(row) {
    row.toggleClass('ev-selected');
    if (row.hasClass('ev-selected')) {
      selectFile(row);
    } else {
      unselectFile(row);
    }
    return updateFileCount();
  };

  var selectFile = function(row) {
    const target_form = $('form.ev-submit-form');
    const file_location = row.data('ev-location');
    const hidden_input = $("<input type='hidden' class='ev-url' name='selected_files[]'/>").val(file_location);
    target_form.append(hidden_input);
    if (!$(row).find('.ev-select-file').prop('checked')) {
      return $(row).find('.ev-select-file').prop('checked', true);
    }
  };

  var unselectFile = function(row) {
    const target_form = $('form.ev-submit-form');
    const file_location = row.data('ev-location');
    $(`form.ev-submit-form input[value='${file_location}']`).remove();
    if ($(row).find('.ev-select-file').prop('checked')) {
        return $(row).find('.ev-select-file').prop('checked', false);
      }
  };

  var updateFileCount = function() {
    const count = $('input.ev-url').length;
    const files = count === 1 ? "file" : "files";
    return $('.ev-status').html(`${count} ${files} selected`);
  };

  const toggleBranchSelect = function(row) {
    if (row.hasClass('collapsed')) {
      const node_id = row.find('td.ev-file-name a.ev-link').attr('href');
      return $('table#file-list').treetable('expandNode',node_id);
    }
  };

  const selectAll = rows =>
    rows.each(function() {
      if ($(this).data('tt-branch')) {
        const box = $(this).find('#select_all')[0];
        $(box).prop('checked', true);
        $(box).prop('value', "1");
        return toggleBranchSelect($(this));
      } else {
        if (!fileIsSelected($(this))) { return toggleFileSelect($(this)); }
      }
    })
  ;

  const selectChildRows = (row, action) =>
    $('table#file-list tr').each(function() {
      if ($(this).data('tt-parent-id')) {
        const re = RegExp($(row).data('tt-id'), 'i');
        if ($(this).data('tt-parent-id').match(re)) {
          if ($(this).data('tt-branch')) {
            const box = $(this).find('#select_all')[0];
            $(box).prop('value', action);
            if (action === "1") {
              $(box).prop("checked", true);
              const node_id = $(this).find('td.ev-file-name a.ev-link').attr('href');
              return $('table#file-list').treetable('expandNode',node_id);
            } else {
              return $(box).prop("checked", false);
            }
          } else {
            if (action === "1") {
              $(this).addClass('ev-selected');
              if (!fileIsSelected($(this))) { selectFile($(this)); }
            } else {
              $(this).removeClass('ev-selected');
              unselectFile($(this));
            }
            return updateFileCount();
          }
        }
      }
    })
  ;

  const tableSetup = function(table) {
    table.treetable({
      expandable: true,
      onNodeCollapse() {
        const node = this;
        return table.treetable("unloadBranch", node);
      },
      onNodeExpand() {
        const node = this;
        startWait();
        const size = $(node.row).find('td.ev-file-size').text().trim();
        let start = 1;
        let increment = 1;
        if (size.indexOf("MB") >-1) {
          start = 10;
          increment = 5;
        }
        if (size.indexOf("KB") >-1) {
          start = 50;
          increment = 10;
        }
        setProgress(start);
        const progressIntervalID = setInterval((function() {
          start = start + increment;
          if (start > 99) {
            start = 99;
          }
          return setProgress(start);
        }), 2000);
        return setTimeout((() => loadFiles(node, table, progressIntervalID)), 10);
      }
    });
    $("#file-list tr:first").focus();
    return sizeColumns(table);
  };

  var sizeColumns = function(table) {
    const full_width = $('.ev-files').width();
    table.width(full_width);
    const set_size = (selector, pct) => $(selector, table).width(full_width * pct).css('width',full_width * pct).css('max-width',full_width * pct);
    set_size('.ev-file', 0.4);
    set_size('.ev-container', 0.4);
    set_size('.ev-size', 0.1);
    set_size('.ev-kind', 0.3);
    return set_size('.ev-date', 0.2);
  };

  var loadFiles = (node, table, progressIntervalID)=>
    $.ajax({
      async: true, // Must be false, otherwise loadBranch happens after showChildren?
      url: $('a.ev-link',node.row).attr('href'),
      data: {
        parent: node.row.data('tt-id'),
        accept: dialog.data('ev-state').opts.accept,
        context: dialog.data('ev-state').opts.context
      }}).done(function(html) {
      setProgress('100');
      clearInterval(progressIntervalID);
      const rows = $('tbody tr',$(html));
      table.treetable("loadBranch", node, rows);
      $(node).show();
      sizeColumns(table);
      indicateSelected();
      if ($(node.row).find('#select_all')[0].checked) {
        return selectAll(rows);
      }}).always(function() {
        clearInterval(progressIntervalID);
        return stopWait();
    })
  ;

  var setProgress = done=> $('.loading-text').text(done+'% complete');

  const refreshFiles = () => $('.ev-providers select').change();

  var startWait = function() {
    $('.loading-progress').removeClass("hidden");
    $('body').css('cursor','wait');
    $("html").addClass("wait");
    $(".ev-browser").addClass("loading");
    return $('.ev-submit').attr('disabled', true);
  };

  var stopWait = function() {
    $('.loading-progress').addClass("hidden");
    $('body').css('cursor','default');
    $("html").removeClass("wait");
    $(".ev-browser").removeClass("loading");
    return $('.ev-submit').attr('disabled', false);
  };

  $(window).on('resize', () => sizeColumns($('table#file-list')));

  $.fn.browseEverything = function(options) {
    let ctx = $(this).data('ev-state');
    if ((ctx == null) && (options == null)) { options = $(this).data(); }
    if (options != null) {
      ctx = initialize(this[0], options);
      $(this).click(function() {
        dialog.data('ev-state',ctx);
        return dialog.load(ctx.opts.route, function() {
          setTimeout(refreshFiles, 500);
          ctx.callbacks.show.fire();
          return dialog.modal('show');
        });
      });
    }

    if (ctx) {
      return ctx.callback_proxy;
    } else {
      return {
        show() { return this; },
        done() { return this; },
        cancel() { return this; },
        fail() { return this; }
      };
    }
  };

  $.fn.browseEverything.toggleCheckbox = function(box) {
    if (box.value === "0") {
      return $(box).prop('value', "1");
    } else {
      return $(box).prop('value', "0");
    }
  };

  $(document).on('ev.refresh', event => refreshFiles());

  $(document).on('click', 'button.ev-cancel', function(event) {
    event.preventDefault();
    dialog.data('ev-state').callbacks.cancel.fire();
    return $('.ev-browser').modal('hide');
  });

  $(document).on('click', 'button.ev-submit', function(event) {
    event.preventDefault();
    $(this).button('loading');
    startWait();
    const main_form = $(this).closest('form');
    const resolver_url = main_form.data('resolver');
    const ctx = dialog.data('ev-state');
    $(main_form).find('input[name=context]').val(ctx.opts.context);
    return $.ajax(resolver_url, {
      type: 'POST',
      dataType: 'json',
      data: main_form.serialize()
    }).done(function(data) {
      if (ctx.opts.target != null) {
        const fields = toHiddenFields({selected_files: data});
        $(ctx.opts.target).append($(fields));
      }
      return ctx.callbacks.done.fire(data);}).fail((xhr,status,error) => ctx.callbacks.fail.fire(status, error, xhr.responseText)).always(function() {
      $('body').css('cursor','default');
      $('.ev-browser').modal('hide');
      return $('#browse-btn').focus();
    });
  });

  $(document).on('click', '.ev-files .ev-container a.ev-link', function(event) {
    event.stopPropagation();
    event.preventDefault();
    const row = $(this).closest('tr');
    const action = row.hasClass('expanded') ? 'collapseNode' : 'expandNode';
    const node_id = $(this).attr('href');
    return $('table#file-list').treetable(action,node_id);
  });

  $(document).on('change', '.ev-providers select', function(event) {
    event.preventDefault();
    startWait();
    return $.ajax({
      url: $(this).val(),
      data: {
        accept: dialog.data('ev-state').opts.accept,
        context: dialog.data('ev-state').opts.context
      }}).done(function(data) {
      $('.ev-files').html(data);
      indicateSelected();
      $('#provider_auth').focus();
      return tableSetup($('table#file-list'));}).fail(function(xhr,status,error) {
      if (xhr.responseText.indexOf("Refresh token has expired")>-1) {
        return $('.ev-files').html("Your sessison has expired please clear your cookies.");
      } else {
        return $('.ev-files').html(xhr.responseText);
      }}).always(() => stopWait());
  });

  $(document).on('click', '.ev-providers a', function(event) {
    $('.ev-providers li').removeClass('ev-selected');
    return $(this).closest('li').addClass('ev-selected');
  });

  $(document).on('click', '.ev-file a', function(event) {
    event.preventDefault();
    const target = $(this).closest('*[data-ev-location]');
    return toggleFileSelect(target);
  });

  $(document).on('click', '.ev-auth', function(event) {
    event.preventDefault();
    const auth_win = window.open($(this).attr('href'));
    var check_func = function() {
      if (auth_win.closed) {
        return $('.ev-providers .ev-selected a').click();
      } else {
        return window.setTimeout(check_func, 1000);
      }
    };
    return check_func();
  });

  $(document).on('change', 'input.ev-select-all', function(event) {
    event.stopPropagation();
    event.preventDefault();
    $.fn.browseEverything.toggleCheckbox(this);
    const action = this.value;
    const row = $(this).closest('tr');
    const node_id = row.find('td.ev-file-name a.ev-link').attr('href');
    if (row.hasClass('collapsed')) {
      return $('table#file-list').treetable('expandNode',node_id);
    } else {
      return selectChildRows(row, action);
    }
  });

  return $(document).on('change', 'input.ev-select-file', function(event) {
    event.stopPropagation();
    event.preventDefault();
    return toggleFileSelect($(this).closest('tr'));
  });
});


const auto_toggle = function() {
  const triggers = $('*[data-toggle=browse-everything]');
  if (typeof Rails !== 'undefined' && Rails !== null) {
    $.ajaxSetup({
        headers: { 'X-CSRF-TOKEN': (Rails || $.rails).csrfToken() || '' }
    });
  }

  return triggers.each(function() {
    const ctx = $(this).data('ev-state');
    if (ctx == null) { return $(this).browseEverything($(this).data()); }
  });
};

if ((typeof Turbolinks !== 'undefined' && Turbolinks !== null) && Turbolinks.supported) {
  // Use turbolinks:load for Turbolinks 5, otherwise use the old way
  if (Turbolinks.BrowserAdapter) {
    $(document).on('turbolinks:load', auto_toggle);
  } else {
    $(document).on('page:change', auto_toggle);
  }
} else {
  $(document).ready(auto_toggle);
}
