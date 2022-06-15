'use strict';

$(function () {
  var dialog = $('div#browse-everything');
  var selected_files = new Map(); // { url: input element object }

  var initialize = function initialize(obj, options) {
    if ($('div#browse-everything').length === 0) {
      // bootstrap 4 needs at least the inner class="modal-dialog" div, or it gets really
      // confused and can't close the dialog.
      dialog = $('<div tabindex="-1" id="browse-everything" class="ev-browser modal fade" aria-live="polite" role="dialog" aria-labelledby="beModalLabel">' + '<div class="modal-dialog modal-lg" role="document"></div>' + '</div>').hide().appendTo('body');
    }

    dialog.modal({
      backdrop: 'static',
      show: false
    });
    var ctx = {
      opts: $.extend(true, {}, options),
      callbacks: {
        show: $.Callbacks(),
        done: $.Callbacks(),
        cancel: $.Callbacks(),
        fail: $.Callbacks()
      }
    };
    ctx.callback_proxy = {
      show: function show(func) {
        ctx.callbacks.show.add(func);return this;
      },
      done: function done(func) {
        ctx.callbacks.done.add(func);return this;
      },
      cancel: function cancel(func) {
        ctx.callbacks.cancel.add(func);return this;
      },
      fail: function fail(func) {
        ctx.callbacks.fail.add(func);return this;
      }
    };
    $(obj).data('ev-state', ctx);
    return ctx;
  };

  var toHiddenFields = function toHiddenFields(data) {
    var fields = $.param(data).split('&').map(function (t) {
      return t.replace(/\+/g, ' ').split('=', 2);
    });
    var elements = $(fields).map(function () {
      return $("<input type='hidden'/>").attr('name', decodeURIComponent(this[0])).val(decodeURIComponent(this[1]))[0];
    });
    return $(elements.toArray());
  };

  var indicateSelected = function indicateSelected() {
    return selected_files.forEach(function (value, key) {
      var row = $('*[data-ev-location=\'' + key + '\']');
      row.find('.ev-select-file').prop('checked', true);
      return row.addClass('ev-selected');
    });
  };

  var fileIsSelected = function fileIsSelected(row) {
    return selected_files.has(row.data('ev-location'));
  };

  var toggleFileSelect = function toggleFileSelect(row) {
    row.toggleClass('ev-selected');
    if (row.hasClass('ev-selected')) {
      selectFile(row);
    } else {
      unselectFile(row);
    }
    return updateFileCount();
  };

  var hidden_input_prototype = $("<input type='hidden' class='ev-url' name='selected_files[]'/>");
  var selectFile = function selectFile(row) {
    var file_location = row.data('ev-location');
    var hidden_input = hidden_input_prototype.clone().val(file_location);
    selected_files.set(file_location, hidden_input);
    if (!$(row).find('.ev-select-file').prop('checked')) {
      return $(row).find('.ev-select-file').prop('checked', true);
    }
  };

  var unselectFile = function unselectFile(row) {
    var file_location = row.data('ev-location');
    selected_files.delete(file_location);
    if ($(row).find('.ev-select-file').prop('checked')) {
      return $(row).find('.ev-select-file').prop('checked', false);
    }
  };

  var updateFileCount = function updateFileCount() {
    var count = selected_files.size;
    var files = count === 1 ? "file" : "files";
    return $('.ev-status').html(count + ' ' + files + ' selected');
  };

  var toggleBranchSelect = function toggleBranchSelect(row) {
    if (row.hasClass('collapsed')) {
      var node_id = row.find('td.ev-file-name a.ev-link').attr('href');
      return $('table#file-list').treetable('expandNode', node_id);
    }
  };

  var selectAll = function selectAll(rows) {
    return rows.each(function () {
      if ($(this).data('tt-branch')) {
        var box = $(this).find('#select_all')[0];
        $(box).prop('checked', true);
        $(box).prop('value', "1");
        return toggleBranchSelect($(this));
      } else {
        if (!fileIsSelected($(this))) {
          return toggleFileSelect($(this));
        }
      }
    });
  };

  var selectChildRows = function selectChildRows(row, action) {
    var returned_rows = $('table#file-list tr').each(function () {
      if ($(this).data('tt-parent-id')) {
        var re = RegExp($(row).data('tt-id'), 'i');
        if ($(this).data('tt-parent-id').match(re)) {
          if ($(this).data('tt-branch')) {
            var box = $(this).find('#select_all')[0];
            $(box).prop('value', action);
            if (action === "1") {
              $(box).prop("checked", true);
              var node_id = $(this).find('td.ev-file-name a.ev-link').attr('href');
              return $('table#file-list').treetable('expandNode', node_id);
            } else {
              return $(box).prop("checked", false);
            }
          } else {
            if (action === "1") {
              $(this).addClass('ev-selected');
              if (!fileIsSelected($(this))) {
                selectFile($(this));
              }
            } else {
              $(this).removeClass('ev-selected');
              unselectFile($(this));
            }
          }
        }
      }
    });
    updateFileCount();
    return returned_rows;
  };

  var tableSetup = function tableSetup(table) {
    table.treetable({
      expandable: true,
      onNodeCollapse: function onNodeCollapse() {
        var node = this;
        return table.treetable("unloadBranch", node);
      },
      onNodeExpand: function onNodeExpand() {
        var node = this;
        startWait();
        var size = $(node.row).find('td.ev-file-size').text().trim();
        var start = 1;
        var increment = 1;
        if (size.indexOf("MB") > -1) {
          start = 10;
          increment = 5;
        }
        if (size.indexOf("KB") > -1) {
          start = 50;
          increment = 10;
        }
        setProgress(start);
        var progressIntervalID = setInterval(function () {
          start = start + increment;
          if (start > 99) {
            start = 99;
          }
          return setProgress(start);
        }, 2000);
        return setTimeout(function () {
          return loadFiles(node, table, progressIntervalID);
        }, 10);
      }
    });
    $("#file-list tr:first").focus();
    return sizeColumns(table);
  };

  var sizeColumns = function sizeColumns(table) {
    var full_width = $('.ev-files').width();
    table.width(full_width);
    var set_size = function set_size(selector, pct) {
      return $(selector, table).width(full_width * pct).css('width', full_width * pct).css('max-width', full_width * pct);
    };
    set_size('.ev-file', 0.4);
    set_size('.ev-container', 0.4);
    set_size('.ev-size', 0.1);
    set_size('.ev-kind', 0.3);
    return set_size('.ev-date', 0.2);
  };

  var loadFiles = function loadFiles(node, table, progressIntervalID) {
    return $.ajax({
      async: true, // Must be false, otherwise loadBranch happens after showChildren?
      url: $('a.ev-link', node.row).attr('href'),
      data: {
        parent: node.row.data('tt-id'),
        accept: dialog.data('ev-state').opts.accept,
        context: dialog.data('ev-state').opts.context
      } }).done(function (html) {
      setProgress('100');
      clearInterval(progressIntervalID);
      var rows = $('tbody tr', $(html));
      table.treetable("loadBranch", node, rows);
      $(node).show();
      sizeColumns(table);
      indicateSelected();
      if ($(node.row).find('#select_all')[0].checked) {
        return selectAll(rows);
      }
    }).always(function () {
      clearInterval(progressIntervalID);
      return stopWait();
    });
  };

  var setProgress = function setProgress(done) {
    return $('.loading-text').text(done + '% complete');
  };

  var refreshFiles = function refreshFiles() {
    return $('.ev-providers select').change();
  };

  var startWait = function startWait() {
    $('.loading-progress').removeClass("hidden");
    $('body').css('cursor', 'wait');
    $("html").addClass("wait");
    $(".ev-browser").addClass("loading");
    return $('.ev-submit').attr('disabled', true);
  };

  var stopWait = function stopWait() {
    $('.loading-progress').addClass("hidden");
    $('body').css('cursor', 'default');
    $("html").removeClass("wait");
    $(".ev-browser").removeClass("loading");
    return $('.ev-submit').attr('disabled', false);
  };

  $(window).on('resize', function () {
    return sizeColumns($('table#file-list'));
  });

  $.fn.browseEverything = function (options) {
    var ctx = $(this).data('ev-state');

    // Try and load the options from the HTML data attributes
    if (ctx == null && options == null) {
      options = $(this).data();
    }

    if (options != null) {
      ctx = initialize(this[0], options);
    }

    $(this).click(function () {
      dialog.data('ev-state', ctx);
      return dialog.load(ctx.opts.route, function () {
        setTimeout(refreshFiles, 50);
        ctx.callbacks.show.fire();
        dialog.removeClass('fade')
          .removeClass('in')
          .addClass('show');

        return dialog.modal('show');
      });
    });

    if (ctx) {
      return ctx.callback_proxy;
    } else {
      return {
        show: function show() {
          return this;
        },
        done: function done() {
          return this;
        },
        cancel: function cancel() {
          return this;
        },
        fail: function fail() {
          return this;
        }
      };
    }
  };

  $.fn.browseEverything.toggleCheckbox = function (box) {
    if (box.value === "0") {
      return $(box).prop('value', "1");
    } else {
      return $(box).prop('value', "0");
    }
  };

  $(document).on('ev.refresh', function (event) {
    return refreshFiles();
  });

  $(document).on('click', 'button.ev-cancel', function (event) {
    event.preventDefault();
    dialog.data('ev-state').callbacks.cancel.fire();
    selected_files.clear();
    return $('.ev-browser').modal('hide');
  });

  $(document).on('click', 'button.ev-submit', function (event) {
    event.preventDefault();
    $(this).button('loading');
    startWait();
    $('form.ev-submit-form').append(Array.from(selected_files.values()));
    var main_form = $(this).closest('form');
    var resolver_url = main_form.data('resolver');
    var ctx = dialog.data('ev-state');
    $(main_form).find('input[name=context]').val(ctx.opts.context);
    return $.ajax(resolver_url, {
      type: 'POST',
      dataType: 'json',
      data: main_form.serialize()
    }).done(function (data) {
      if (ctx.opts.target != null) {
        var fields = toHiddenFields({ selected_files: data });
        $(ctx.opts.target).append(fields);
      }
      return ctx.callbacks.done.fire(data);
    }).fail(function (xhr, status, error) {
      return ctx.callbacks.fail.fire(status, error, xhr.responseText);
    }).always(function () {
      selected_files.clear();
      $('body').css('cursor', 'default');
      $('.ev-browser').modal('hide');
      return $('#browse-btn').focus();
    });
  });

  $(document).on('click', '.ev-files .ev-container a.ev-link', function (event) {
    event.stopPropagation();
    event.preventDefault();
    var row = $(this).closest('tr');
    var action = row.hasClass('expanded') ? 'collapseNode' : 'expandNode';
    var node_id = $(this).attr('href');
    return $('table#file-list').treetable(action, node_id);
  });

  $(document).on('change', '.ev-providers select', function (event) {
    event.preventDefault();
    startWait();
    return $.ajax({
      url: $(this).val(),
      data: {
        accept: dialog.data('ev-state').opts.accept,
        context: dialog.data('ev-state').opts.context
      } }).done(function (data) {
      $('.ev-files').html(data);
      indicateSelected();
      $('#provider_auth').focus();
      return tableSetup($('table#file-list'));
    }).fail(function (xhr, status, error) {
      if (xhr.responseText.indexOf("Refresh token has expired") > -1) {
        return $('.ev-files').html("Your sessison has expired please clear your cookies.");
      } else {
        return $('.ev-files').html(xhr.responseText);
      }
    }).always(function () {
      return stopWait();
    });
  });

  $(document).on('click', '.ev-providers a', function (event) {
    $('.ev-providers li').removeClass('ev-selected');
    return $(this).closest('li').addClass('ev-selected');
  });

  $(document).on('click', '.ev-file a', function (event) {
    event.preventDefault();
    var target = $(this).closest('*[data-ev-location]');
    return toggleFileSelect(target);
  });

  $(document).on('click', '.ev-auth', function (event) {
    event.preventDefault();
    var auth_win = window.open($(this).attr('href'));
    var check_func = function check_func() {
      if (auth_win.closed) {
        return $('.ev-providers .ev-selected a').click();
      } else {
        return window.setTimeout(check_func, 1000);
      }
    };
    return check_func();
  });

  $(document).on('change', 'input.ev-select-all', function (event) {
    event.stopPropagation();
    event.preventDefault();
    $.fn.browseEverything.toggleCheckbox(this);
    var action = this.value;
    var row = $(this).closest('tr');
    var node_id = row.find('td.ev-file-name a.ev-link').attr('href');
    if (row.hasClass('collapsed')) {
      return $('table#file-list').treetable('expandNode', node_id);
    } else {
      return selectChildRows(row, action);
    }
  });

  return $(document).on('change', 'input.ev-select-file', function (event) {
    event.stopPropagation();
    event.preventDefault();
    return toggleFileSelect($(this).closest('tr'));
  });
});

var auto_toggle = function auto_toggle() {
  var triggers = $('*[data-toggle=browse-everything]');
  if (typeof Rails !== 'undefined' && Rails !== null) {
    $.ajaxSetup({
      headers: { 'X-CSRF-TOKEN': (Rails || $.rails).csrfToken() || '' }
    });
  }

  return triggers.each(function () {
    var ctx = $(this).data('ev-state');
    if (ctx == null) {
      return $(this).browseEverything($(this).data());
    }
  });
};

if (typeof Turbolinks !== 'undefined' && Turbolinks !== null && Turbolinks.supported) {
  // Use turbolinks:load for Turbolinks 5, otherwise use the old way
  if (Turbolinks.BrowserAdapter) {
    $(document).on('turbolinks:load', function() {
      // make sure turbolinks:load AND jquery onReady have BOTH happened,
      // they could come in any order.
      $(auto_toggle);
    });
  } else {
    $(document).on('page:change', function() {
      $(auto_toggle);
    });
  }
} else {
  $(auto_toggle);
}
