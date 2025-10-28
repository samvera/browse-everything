'use strict';

/**
 * Wunderbaum adapter for converting HTML table rows to Wunderbaum nodes
 */
(function (window) {
  window.WunderbaumAdapter = window.WunderbaumAdapter || {};

  /**
   * Extract data from each table row element
   * @param {HTMLElement} row  table row element
   * @returns {Object} Node data object
   */
  function extractRowData(row) {
    var isContainer = row.dataset.ttBranch === 'true';
    var ttId = row.dataset.ttId || '';
    var parentId = row.dataset.ttParentId || '';
    var location = row.dataset.evLocation || '';

    // Extract cell data from markup
    var nameCell = row.querySelector('.ev-file-name');
    var sizeCell = row.querySelector('.ev-file-size');
    var kindCell = row.querySelector('.ev-file-kind');
    var dateCell = row.querySelector('.ev-file-date');

    var name = '';
    var link = null;

    // Retrieve and cleanup name of the file/folder
    if (nameCell) {
      var linkEl = nameCell.querySelector('a.ev-link');
      if (linkEl) {
        link = linkEl.getAttribute('href');
        name = linkEl.textContent.trim();
      } else {
        name = nameCell.textContent.trim();
      }
    }

    var sizeText = sizeCell ? sizeCell.textContent.trim() : '';
    var kindText = kindCell ? kindCell.textContent.trim() : '';
    var dateText = dateCell ? dateCell.textContent.trim() : '';

    return {
      key: ttId,
      title: name,
      folder: isContainer,
      // Load files in folders on demand
      lazy: isContainer,
      checkbox: true,
      link: link,
      // Column data for display
      size: sizeText,
      kind: kindText,
      date: dateText,
      // Additional data
      data: {
        location: location,
        parentId: parentId,
        size: sizeText,
        kind: kindText,
        date: dateText,
        row: row
      }
    };
  }

  /**
   * Get only top-level nodes (no hierarchy), for initial load where,
   * server returns only current level
   * @param {HTMLElement|String} tableOrHtml table element or HTML string
   * @returns {Array} flat array of nodes
   */
  function htmlToFlatNodes(tableOrHtml) {
    var table;

    if (typeof tableOrHtml === 'string') {
      var parser = new DOMParser();
      var doc = parser.parseFromString(tableOrHtml, 'text/html');
      table = doc.querySelector('table#file-list');
    } else {
      table = tableOrHtml;
    }

    if (!table) {
      return [];
    }

    var rows = table.querySelectorAll('tbody tr');
    var nodes = [];

    rows.forEach(function (row) {
      nodes.push(extractRowData(row));
    });

    return nodes;
  }

  // Export public API
  window.WunderbaumAdapter = {
    htmlToFlatNodes: htmlToFlatNodes,
  };

})(window);
