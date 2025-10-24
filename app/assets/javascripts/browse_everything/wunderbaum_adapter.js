'use strict';

/**
 * Wunderbaum Adapter for browse-everything
 * Transforms HTML table rows to Wunderbaum tree node format
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

    // Extract cell data
    var nameCell = row.querySelector('.ev-file-name');
    var sizeCell = row.querySelector('.ev-file-size');
    var kindCell = row.querySelector('.ev-file-kind');
    var dateCell = row.querySelector('.ev-file-date');

    var name = '';
    var link = null;

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
      // Folders load children on demand
      lazy: isContainer,
      checkbox: true,
      // Folders cannot be selected (only files)
      unselectable: isContainer,
      // Use file icon for files, default folder icon for folders
      icon: isContainer ? false : 'bi bi-file-earmark',
      link: link,
      // Column data at top level for Wunderbaum grid
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
   * Build a hierarchical tree from flat row data
   * @param {Array} nodes array of flat node objects
   * @returns {Array} hierarchical tree structure
   */
  function buildTree(nodes) {
    var tree = [];
    var nodeMap = new Map();

    // Create map of all nodes
    nodes.forEach(function (node) {
      nodeMap.set(node.key, node);
      node.children = [];
    });

    // Build the hierarchy
    nodes.forEach(function (node) {
      var parentId = node.data.parentId;
      if (!parentId || parentId === '' || parentId === 'null' || parentId === 'undefined') {
        // Root level node
        tree.push(node);
      } else {
        // Add child to parent node
        var parent = nodeMap.get(parentId);
        if (parent) {
          if (!parent.children) {
            parent.children = [];
          }
          parent.children.push(node);
        } else {
          // When parent is not found, treat is as a root node
          tree.push(node);
        }
      }
    });

    // Clean up nodes without children
    nodes.forEach(function (node) {
      if (node.folder && node.children.length === 0) {
        // Files in folders are loaded lazily
        delete node.children;
      } else if (!node.folder) {
        // Files don't have children
        delete node.children;
      }
    });

    return tree;
  }

  /**
   * Convert HTML table to Wunderbaum-supported tree data structure
   * @param {HTMLElement|String} tableOrHtml table element or HTML string
   * @returns {Array} tree node array
   */
  function htmlToTreeData(tableOrHtml) {
    var table;

    if (typeof tableOrHtml === 'string') {
      // Parse HTML string
      var parser = new DOMParser();
      var doc = parser.parseFromString(tableOrHtml, 'text/html');
      table = doc.querySelector('table#file-list');
    } else {
      table = tableOrHtml;
    }

    if (!table) {
      console.warn('No table found in HTML');
      return [];
    }

    var rows = table.querySelectorAll('tbody tr');
    var nodes = [];

    // Extract data from each row
    rows.forEach(function (row) {
      nodes.push(extractRowData(row));
    });

    return buildTree(nodes);
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

  /**
   * Convert Wunderbaum node to hidden input element for form submission
   * @param {Object} node Wunderbaum node
   * @returns {HTMLElement} hidden input element
   */
  function nodeToHiddenInput(node) {
    var input = document.createElement('input');
    input.type = 'hidden';
    input.className = 'ev-url';
    input.name = 'selected_files[]';
    input.value = node.data.location;
    return input;
  }

  // Export public API
  window.WunderbaumAdapter = {
    htmlToTreeData: htmlToTreeData,
    htmlToFlatNodes: htmlToFlatNodes,
    extractRowData: extractRowData,
    buildTree: buildTree,
    nodeToHiddenInput: nodeToHiddenInput
  };

})(window);
