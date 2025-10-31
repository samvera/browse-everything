'use strict';

document.addEventListener('DOMContentLoaded', function () {
  var dialog = document.querySelector('div#browse-everything');
  var selected_files = new Map(); // { url: input element object }
  var wunderbaumInstance = null; // Global Wunderbaum tree instance

  /** START: Helper functions for jQuery methods */
  // Helper: Custom Callbacks implementation (replaces $.Callbacks)
  function Callbacks() {
    var list = [];
    return {
      add: function (fn) {
        list.push(fn);
      },
      fire: function () {
        var args = arguments;
        list.forEach(function (fn) {
          fn.apply(null, args);
        });
      }
    };
  }

  // Helper: Serialize form data (replaces $.param)
  function param(obj) {
    var str = [];
    for (var p in obj) {
      if (obj.hasOwnProperty(p)) {
        var value = obj[p];
        // Skip undefined, null, and empty string values
        if (value !== undefined && value !== null && value !== '') {
          str.push(encodeURIComponent(p) + '=' + encodeURIComponent(value));
        }
      }
    }
    return str.join('&');
  }

  // Helper: Get/set element data (replaces $.data)
  var dataStore = new WeakMap();
  function getData(el, key) {
    var data = dataStore.get(el) || {};
    return key ? data[key] : data;
  }
  function setData(el, key, value) {
    var data = dataStore.get(el) || {};
    data[key] = value;
    dataStore.set(el, data);
  }

  // Helper: Event delegation (replaces $(document).on)
  function delegate(element, eventType, selector, handler) {
    element.addEventListener(eventType, function (event) {
      var target = event.target.closest(selector);
      if (target) {
        handler.call(target, event);
      }
    });
  }

  // Helper: AJAX wrapper using fetch (replaces $.ajax)
  function ajax(url, options) {
    options = options || {};
    var config = {
      method: options.type || options.method || 'GET',
      headers: options.headers || {}
    };

    // Add X-Requested-With header for Rails to detect AJAX requests
    config.headers['X-Requested-With'] = 'XMLHttpRequest';

    // Add CSRF token
    var csrfToken = document.querySelector('[name="csrf-token"]');
    if (csrfToken) {
      config.headers['X-CSRF-TOKEN'] = csrfToken.content;
    }

    var responseType = options.dataType || 'text';

    // Set Accept header based on dataType
    if (responseType === 'json') {
      config.headers['Accept'] = 'application/json';
    } else {
      config.headers['Accept'] = 'text/html, */*';
    }

    // Handle data
    if (options.data) {
      if (config.method === 'GET') {
        var queryString = typeof options.data === 'string' ? options.data : param(options.data);
        url += (url.indexOf('?') === -1 ? '?' : '&') + queryString;
      } else {
        if (typeof options.data === 'string') {
          config.body = options.data;
          config.headers['Content-Type'] = 'application/x-www-form-urlencoded';
        } else if (options.data instanceof FormData) {
          config.body = options.data;
        } else {
          config.body = param(options.data);
          config.headers['Content-Type'] = 'application/x-www-form-urlencoded';
        }
      }
    }

    return fetch(url, config).then(function (response) {
      if (!response.ok) {
        return Promise.reject({
          status: response.status,
          statusText: response.statusText,
          responseText: ''
        });
      }
      if (responseType === 'json') {
        return response.json();
      }
      return response.text();
    }).then(function (data) {
      return Promise.resolve(data);
    }).catch(function (error) {
      if (error.responseText === undefined && error.message) {
        error.responseText = error.message;
      }
      return Promise.reject(error);
    });
  }
  /** END: Helper functions for jQuery methods */

  var initialize = function initialize(obj, options) {
    if (document.querySelectorAll('div#browse-everything').length === 0) {
      // bootstrap 4 needs at least the inner class="modal-dialog" div
      dialog = document.createElement('div');
      dialog.setAttribute('tabindex', '-1');
      dialog.id = 'browse-everything';
      dialog.className = 'ev-browser modal fade';
      dialog.setAttribute('aria-live', 'polite');
      dialog.setAttribute('role', 'dialog');
      dialog.setAttribute('aria-labelledby', 'beModalLabel');
      dialog.innerHTML = '<div class="modal-dialog modal-lg" role="document"></div>';
      dialog.style.display = 'none';
      document.body.appendChild(dialog);
    }

    // Initialize Bootstrap modal
    if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
      setData(dialog, 'bootstrap-modal', new bootstrap.Modal(dialog, {
        backdrop: 'static',
        show: false
      }));
    }

    var mergedOptions = { ...(options || {}) };
    if (!mergedOptions.accept) {
      mergedOptions.accept = '';
    }
    if (!mergedOptions.context) {
      mergedOptions.context = '';
    }

    var ctx = {
      opts: mergedOptions,
      callbacks: {
        show: Callbacks(),
        done: Callbacks(),
        cancel: Callbacks(),
        fail: Callbacks()
      }
    };
    ctx.callback_proxy = {
      show: function show(func) {
        ctx.callbacks.show.add(func);
        return this;
      },
      done: function done(func) {
        ctx.callbacks.done.add(func);
        return this;
      },
      cancel: function cancel(func) {
        ctx.callbacks.cancel.add(func);
        return this;
      },
      fail: function fail(func) {
        ctx.callbacks.fail.add(func);
        return this;
      }
    };
    // Store the context object on the DOM element obj with the key 'ev-state'
    setData(obj, 'ev-state', ctx);
    return ctx;
  };

  /**
   * Convert selected file data to hidden input fields for form submission
   * @param {Object} data selected file data
   * @returns {Array<Object>}
   */
  var toHiddenFields = function toHiddenFields(data) {
    var fields = param(data).split('&').map(function (t) {
      return t.replace(/\+/g, ' ').split('=', 2);
    });
    return fields.map(function (field) {
      var input = document.createElement('input');
      input.type = 'hidden';
      input.name = decodeURIComponent(field[0]);
      input.value = decodeURIComponent(field[1]);
      return input;
    });
  };

  /**
   * Update the file count display in the status element
   */
  var updateFileCount = function updateFileCount() {
    var count = selected_files.size;
    var files = count === 1 ? 'file' : 'files';
    var statusEl = document.querySelector('.ev-status');
    if (statusEl) {
      statusEl.innerHTML = count + ' ' + files + ' selected';
    }
  };

  // Flag to indicate if we're doing a batch selection operation
  var isBatchSelecting = false;

  /**
   * Recursively expand all folders starting from a node
   * @param {Object} node the starting Wunderbaum node
   * @returns {Promise} resolves when all folders are expanded
   */
  var expandAllFoldersRecursively = async function expandAllFoldersRecursively(node) {
    // If this is a folder and not expanded, expand it first
    if (node.data.folder && !node.expanded) {
      await node.setExpanded(true, { loadLazy: true });
    }

    // If this node has children, recursively expand them
    if (node.children && node.children.length > 0) {
      // Expand all child folders in sequence
      for (var i = 0; i < node.children.length; i++) {
        var child = node.children[i];
        if (child.data.folder) {
          await expandAllFoldersRecursively(child);
        }
      }
    }
  };

  /**
   * Select/unselect all files and folders in a folder node
   * @param {Object} folder Wunderbaum folder node
   * @param {Boolean} isSelected - true to select, false to unselect
   */
  var selectAllFilesInFolder = function selectAllFilesInNode(folder, isSelected = true) {
    // Collect all descendants (both files and folders)
    var nodesToSelect = [];

    folder.visit(function (descendant) {
      nodesToSelect.push(descendant);
    });

    // Nothing to select
    if (nodesToSelect.length === 0) return;

    // Select all files/folders at once, preventing focus/scroll
    nodesToSelect.forEach(function (n) {
      // Use noEvents option to prevent triggering scroll events
      n.setSelected(isSelected, { noEvents: true });
    });
  };

  /**
   * Sync Wunderbaum selection state with selected_files Map
   */
  var updateWunderbaumSelection = function updateWunderbaumSelection() {
    if (!wunderbaumInstance) return;

    // Clear current selection
    selected_files.clear();

    // Get all selected nodes from Wunderbaum
    var selectedNodes = wunderbaumInstance.getSelectedNodes();

    selectedNodes.forEach(function (node) {
      // Only track file selections, not folders
      if (!node.data.folder) {
        var location = node.data.data.location;
        if (location) {
          var hidden_input = document.createElement('input');
          hidden_input.type = 'hidden';
          hidden_input.className = 'ev-url';
          hidden_input.name = 'selected_files[]';
          hidden_input.value = location;
          selected_files.set(location, hidden_input);
        }
      }
    });
    updateFileCount();
  };

  /**
   * Table setup using Wunderbaum
   * @param {HTMLElement|String} tableOrHtml 
   * @returns {Object|Null} Wunderbaum instance or null on error
   */
  var tableSetup = function tableSetup(tableOrHtml) {
    // Convert HTML table to Wunderbaum tree data
    var treeData = window.WunderbaumAdapter.htmlToFlatNodes(tableOrHtml);

    // Get or create container for Wunderbaum
    var container = document.querySelector('#file-list');
    if (!container) {
      var filesContainer = document.querySelector('.ev-files');
      if (filesContainer) {
        // Replace table with div container
        var table = filesContainer.querySelector('table#file-list');
        if (table) {
          var newDiv = document.createElement('div');
          newDiv.id = 'file-list';
          newDiv.style.minHeight = '300px'; // Ensure it's visible
          newDiv.style.width = '100%';
          table.parentNode.replaceChild(newDiv, table);
          container = newDiv;
        }
      }
    }

    if (!container) {
      console.error('Could not find or create #file-list container');
      return null;
    }

    // Destroy existing instance if present
    if (wunderbaumInstance) {
      try {
        wunderbaumInstance.destroy();
      } catch (e) {
        // Chrome throws NoModificationAllowedError if element is detached.
        // This is safe to ignore as the instance recreated in next step.
        console.warn('Wunderbaum destroy warning (ignore):', e.message);
      }
      wunderbaumInstance = null;
    }

    // Initialize Wunderbaum
    try {
      wunderbaumInstance = new mar10.Wunderbaum({
        id: 'browse-everything-tree',
        element: container,
        source: treeData,
        selectMode: 'hier',
        checkbox: true,
        // Turn off logging
        debugLevel: 0,
        // Don't auto-expand on load
        minExpandLevel: 0,
        columnsMenu: false,
        // Enable icons and use Bootstrap Icons
        icon: true,
        iconMap: 'bootstrap',
        columns: [
          { id: '*', title: 'Name', width: '*' },
          { id: 'size', title: 'Size', width: '100px' },
          { id: 'kind', title: 'Kind', width: '*' },
          { id: 'date', title: 'Modified', width: '150px' }
        ],
        // Display the number of selected files in the badge of a collapsed folder
        iconBadge: (e) => {
          const node = e.node;
          // Do nothing if the node is a file
          if (!node.children || node.expanded) return;

          // Get all selected children
          const selectedDescendants = node.getSelectedNodes(false);

          // Filter the selected children to only include files
          const selectedFiles = selectedDescendants.filter(childNode => {
            return !childNode.data.folder;
          });

          const count = selectedFiles.length;
          // Don't show a badge if nothing is selected
          if (count === 0) return; else return { badge: count };
        },
        render: function (e) {
          var node = e.node;
          // Render columns from additional data in custom structure from wunderbaum_adapter.js
          if (e.renderColInfosById) {
            var sizeCol = e.renderColInfosById['size'];
            if (sizeCol && sizeCol.elem) sizeCol.elem.textContent = node.data.size || '';
            var kindCol = e.renderColInfosById['kind'];
            if (kindCol && kindCol.elem) kindCol.elem.textContent = node.data.kind || '';
            var dateCol = e.renderColInfosById['date'];
            if (dateCol && dateCol.elem) dateCol.elem.textContent = node.data.date || '';
          }
        },
        // Handle lazy loading of folder contents
        lazyLoad: async function (e) {
          var node = e.node;

          // Only show wait state if we're NOT in a batch selection operation
          var waitForLoading = !isBatchSelecting;
          var progressIntervalID;

          if (waitForLoading) {
            startWait();
            // Update progress text periodically
            progressIntervalID = setInterval(function () {
              var current = parseInt(document.querySelector('.loading-text')?.textContent || '0');
              if (!isNaN(current)) setProgress(Math.min(current + 10, 90).toString());
            }, 200);
          }

          try {
            try {
              const html = await ajax(node.data.link || node.key, {
                method: 'GET',
                data: { parent: node.key }
              });

              if (waitForLoading) clearInterval(progressIntervalID);

              // Convert HTML response to child nodes
              var childNodes = window.WunderbaumAdapter.htmlToFlatNodes(html);

              // Only update selection if not in batch mode
              if (!isBatchSelecting) {
                updateWunderbaumSelection();
              }

              return childNodes;
            } catch (error) {
              console.error('Error loading folder contents:', error);
              return [];
            }
          } finally {
            if (waitForLoading) {
              clearInterval(progressIntervalID);
              stopWait();
            }
          }
        },
        select: async function (e) {
          // If already in batch selection mode, ignore this event to prevent re-entry
          if (isBatchSelecting) return;

          // For folders, expand all nested folders first, then select all files
          if (e.node.data.folder) {
            isBatchSelecting = true;
            startWait();

            try {
              // Only when selecting, expand all nested folders first.
              // This ensures all children are loaded before selecting files.
              if (e.flag) {
                setProgress('Loading folders...');

                // Recursively expand this folder and all its subfolders
                await expandAllFoldersRecursively(e.node);

                // Wait for all DOM updates and tree mutations to complete
                await new Promise(resolve => setTimeout(resolve, 100));
              }

              // Select/unselect all files in this folder
              selectAllFilesInFolder(e.node, e.flag);

              updateWunderbaumSelection();
            } finally {
              // Always hide loading indicator when done
              stopWait();
              isBatchSelecting = false;
            }
          } else {
            // For single file selection, just update the count
            updateWunderbaumSelection();
          }
        },
      });

      return wunderbaumInstance;
    } catch (error) {
      console.error('Error initializing Wunderbaum:', error);
      return null;
    }
  };

  var setProgress = function setProgress(done) {
    var progressText = document.querySelector('.loading-text');
    if (progressText) {
      progressText.textContent = done;
    }
  };

  var refreshFiles = function refreshFiles() {
    var select = document.querySelector('.ev-providers select');
    if (select) {
      var event = new Event('change', { bubbles: true });
      select.dispatchEvent(event);
    }
  };

  var startWait = function startWait() {
    var progress = document.querySelector('.loading-progress');
    if (progress) progress.classList.remove('hidden');
    document.body.style.cursor = 'wait';
    document.documentElement.classList.add('wait');
    var browser = document.querySelector('.ev-browser');
    if (browser) browser.classList.add('loading');
    // Also add loading class to the file list table/wunderbaum
    var fileList = document.querySelector('#file-list');
    if (fileList) fileList.classList.add('loading');
    var submitBtn = document.querySelector('.ev-submit');
    if (submitBtn) submitBtn.setAttribute('disabled', 'true');
  };

  var stopWait = function stopWait() {
    var progress = document.querySelector('.loading-progress');
    if (progress) progress.classList.add('hidden');
    document.body.style.cursor = 'default';
    document.documentElement.classList.remove('wait');
    var browser = document.querySelector('.ev-browser');
    if (browser) browser.classList.remove('loading');
    // Also remove loading class from the file list
    var fileList = document.querySelector('#file-list');
    if (fileList) fileList.classList.remove('loading');
    var submitBtn = document.querySelector('.ev-submit');
    if (submitBtn) submitBtn.removeAttribute('disabled');
  };

  // browse-everything plugin initialization
  function initBrowseEverything(element, options) {
    var ctx = getData(element, 'ev-state');

    // Try and load the options from the HTML data attributes
    if (ctx == null && options == null) {
      options = {};
      for (var attr in element.dataset) {
        if (element.dataset.hasOwnProperty(attr)) {
          options[attr] = element.dataset[attr];
        }
      }
    }

    if (options != null) {
      ctx = initialize(element, options);
    }

    element.addEventListener('click', function () {
      setData(dialog, 'ev-state', ctx);

      // Load dialog content using ajax helper (includes X-Requested-With header)
      ajax(ctx.opts.route, { method: 'GET' })
        .then(function (html) {
          dialog.innerHTML = html;

          // Initialize Wunderbaum on initial table if present
          var initialTable = dialog.querySelector('table#file-list');
          if (initialTable) {
            tableSetup(initialTable);
          }

          setTimeout(refreshFiles, 50);
          ctx.callbacks.show.fire();
          dialog.classList.remove('fade');
          dialog.classList.remove('in');
          dialog.classList.add('show');

          // Show Bootstrap modal
          var modal = getData(dialog, 'bootstrap-modal');
          if (modal && modal.show) {
            modal.show();
          } else {
            dialog.style.display = 'block';
          }
        })
        .catch(function (error) {
          console.error('Error loading browse dialog:', error);
        });
    });

    return ctx ? ctx.callback_proxy : {
      show: function () { return this; },
      done: function () { return this; },
      cancel: function () { return this; },
      fail: function () { return this; }
    };
  }

  // Export initBrowseEverything globally for programmatic use
  window.initBrowseEverything = initBrowseEverything;

  // Handle ev.refresh event
  document.addEventListener('ev.refresh', function () {
    refreshFiles();
  });

  // Handle Cancel button click event
  delegate(document, 'click', 'button.ev-cancel', function (event) {
    event.preventDefault();
    var ctx = getData(dialog, 'ev-state');
    if (ctx) ctx.callbacks.cancel.fire();
    selected_files.clear();
    var modal = getData(dialog, 'bootstrap-modal');
    if (modal && modal.hide) {
      modal.hide();
    } else if (dialog) {
      dialog.style.display = 'none';
    }
  });

  // Handle Submit button click event
  delegate(document, 'click', 'button.ev-submit', function (event) {
    event.preventDefault();
    var button = this;

    // Show loading state
    if (button.dataset.loading) {
      button.textContent = button.dataset.loading;
    }
    button.setAttribute('disabled', 'true');
    startWait();

    // Append selected files to form
    var form = document.querySelector('form.ev-submit-form');
    if (form) {
      selected_files.forEach(function (input) {
        form.appendChild(input.cloneNode());
      });
    }

    var main_form = button.closest('form');
    var resolver_url = main_form.dataset.resolver;
    var ctx = getData(dialog, 'ev-state');
    var contextInput = main_form.querySelector('input[name=context]');
    if (contextInput && ctx) {
      contextInput.value = ctx.opts.context;
    }

    // Serialize form
    var formData = new FormData(main_form);

    ajax(resolver_url, {
      type: 'POST',
      dataType: 'json',
      data: formData
    }).then(function (data) {
      // Update file submission status
      var filesStatus = document.getElementById('status');
      if (filesStatus) {
        filesStatus.innerHTML = data?.length.toString() + ' items selected';
      }
      if (ctx && ctx.opts.target != null) {
        var fields = toHiddenFields({ selected_files: data });
        var target = document.querySelector(ctx.opts.target);
        if (target) {
          fields.forEach(function (field) {
            target.appendChild(field);
          });
        }
      }
      if (ctx) ctx.callbacks.done.fire(data);
    }).catch(function (error) {
      if (ctx) ctx.callbacks.fail.fire(error.status, error.statusText, error.responseText);
    }).finally(function () {
      selected_files.clear();
      document.body.style.cursor = 'default';
      var modal = getData(dialog, 'bootstrap-modal');
      if (modal && modal.hide) {
        modal.hide();
      } else if (dialog) {
        dialog.style.display = 'none';
      }
      var browseBtn = document.querySelector('#browse-btn');
      if (browseBtn) browseBtn.focus();
    });
  });

  // Handle Provider selection change event
  delegate(document, 'change', '.ev-providers select', function (event) {
    event.preventDefault();
    startWait();
    var ctx = getData(dialog, 'ev-state');

    ajax(this.value, {
      data: {
        accept: ctx ? ctx.opts.accept : undefined,
        context: ctx ? ctx.opts.context : undefined
      }
    }).then(function (data) {
      var filesContainer = document.querySelector('.ev-files');
      if (filesContainer) {
        filesContainer.innerHTML = data;
      }
      var authEl = document.querySelector('#provider_auth');
      if (authEl) authEl.focus();
      var table = document.querySelector('table#file-list');
      if (table) tableSetup(table);
    }).catch(function (error) {
      var filesContainer = document.querySelector('.ev-files');
      if (filesContainer) {
        if (error.responseText && error.responseText.indexOf('Refresh token has expired') > -1) {
          filesContainer.innerHTML = 'Your session has expired please clear your cookies.';
        } else {
          filesContainer.innerHTML = error.responseText || 'An error occurred';
        }
      }
    }).finally(function () {
      stopWait();
    });
  });

  // Handle Provider link click event
  delegate(document, 'click', '.ev-providers a', function () {
    var allProviders = document.querySelectorAll('.ev-providers li');
    allProviders.forEach(function (li) {
      li.classList.remove('ev-selected');
    });
    var li = this.closest('li');
    if (li) li.classList.add('ev-selected');
  });

  // Handle Auth link click event
  delegate(document, 'click', '.ev-auth', function (event) {
    event.preventDefault();
    var auth_win = window.open(this.getAttribute('href'));
    var check_func = function check_func() {
      if (auth_win.closed) {
        var selectedLink = document.querySelector('.ev-providers .ev-selected a');
        if (selectedLink) selectedLink.click();
      } else {
        window.setTimeout(check_func, 1000);
      }
    };
    check_func();
  });

  // Auto-initialize triggers for the browse-everything dialog
  var auto_toggle = function auto_toggle() {
    var triggers = document.querySelectorAll('*[data-toggle=browse-everything]');

    triggers.forEach(function (trigger) {
      var ctx = getData(trigger, 'ev-state');
      if (ctx == null) {
        // Initialize with data attributes
        var options = {};
        for (var attr in trigger.dataset) {
          if (trigger.dataset.hasOwnProperty(attr)) {
            options[attr] = trigger.dataset[attr];
          }
        }
        initBrowseEverything(trigger, options);
      }
    });
  };

  // Handle Turbolinks
  if (typeof Turbolinks !== 'undefined' && Turbolinks !== null && Turbolinks.supported) {
    if (Turbolinks.BrowserAdapter) {
      document.addEventListener('turbolinks:load', auto_toggle);
    } else {
      document.addEventListener('page:change', auto_toggle);
    }
  } else {
    auto_toggle();
  }
});
