/**
 * Client-side search — loads /prorok/search-index.json, no backend needed.
 * Expects an <input id="search-input"> and <div id="search-results"> on the page.
 * If they don't exist, does nothing (safe to include on all pages).
 *
 * Features:
 *  - Ctrl+K / ⌘K to focus (like GitHub docs)
 *  - Arrow keys to navigate results
 *  - Enter to open selected result
 *  - Escape to close
 */
(function () {
  var input = document.getElementById('search-input');
  var resultsBox = document.getElementById('search-results');
  if (!input || !resultsBox) return;

  var index = null;
  var debounceTimer = null;
  var selectedIdx = -1;

  function loadIndex(cb) {
    if (index !== null) { cb(); return; }
    var xhr = new XMLHttpRequest();
    xhr.open('GET', '/prorok/search-index.json', true);
    xhr.onload = function () {
      try { index = JSON.parse(xhr.responseText); } catch (e) { index = []; }
      cb();
    };
    xhr.onerror = function () { index = []; cb(); };
    xhr.send();
  }

  function normalize(str) {
    return str.toLowerCase().replace(/ё/g, 'е').replace(/[^a-zа-я0-9\s]/g, '');
  }

  function search(query) {
    if (!index || !query.trim()) return [];
    var terms = normalize(query).split(/\s+/).filter(Boolean);
    if (terms.length === 0) return [];

    return index
      .map(function (entry) {
        var haystack = normalize((entry.title || '') + ' ' + (entry.desc || '') + ' ' + (entry.content || ''));
        var score = 0;
        var titleNorm = normalize(entry.title || '');
        var descNorm = normalize(entry.desc || '');

        for (var i = 0; i < terms.length; i++) {
          var t = terms[i];
          if (titleNorm.indexOf(t) !== -1) score += 10;
          if (descNorm.indexOf(t) !== -1) score += 5;
          if (haystack.indexOf(t) !== -1) score += 1;
        }
        return { entry: entry, score: score };
      })
      .filter(function (r) { return r.score > 0; })
      .sort(function (a, b) { return b.score - a.score; })
      .slice(0, 12)
      .map(function (r) { return r.entry; });
  }

  function render(results, query) {
    if (!query.trim()) {
      resultsBox.innerHTML = '';
      resultsBox.style.display = 'none';
      selectedIdx = -1;
      return;
    }
    if (results.length === 0) {
      resultsBox.innerHTML = '<p style="padding:12px;color:#888;">Ничего не найдено</p>';
      resultsBox.style.display = 'block';
      selectedIdx = -1;
      return;
    }
    var html = '<ul style="list-style:none;margin:0;padding:0;">';
    for (var i = 0; i < results.length; i++) {
      var r = results[i];
      html += '<li style="border-bottom:1px solid #222;">'
            + '<a href="' + r.url + '" style="display:block;padding:10px 14px;color:#d4c5a0;text-decoration:none;font-size:0.95rem;">'
            + '<strong>' + escHtml(r.title) + '</strong>'
            + '<br><span style="color:#888;font-size:0.82rem;">' + escHtml(r.desc) + '</span>'
            + '</a></li>';
    }
    html += '</ul>';
    resultsBox.innerHTML = html;
    resultsBox.style.display = 'block';
    selectedIdx = -1;
  }

  function updateSelection() {
    var links = resultsBox.querySelectorAll('a');
    for (var i = 0; i < links.length; i++) {
      links[i].style.background = (i === selectedIdx) ? '#1a1a2e' : '';
    }
    if (selectedIdx >= 0 && links[selectedIdx]) {
      links[selectedIdx].scrollIntoView({ block: 'nearest' });
    }
  }

  function escHtml(s) {
    var d = document.createElement('div');
    d.textContent = s;
    return d.innerHTML;
  }

  input.addEventListener('input', function () {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(function () {
      var q = input.value;
      loadIndex(function () {
        render(search(q), q);
      });
    }, 200);
  });

  input.addEventListener('focus', function () {
    if (input.value.trim()) {
      loadIndex(function () {
        render(search(input.value), input.value);
      });
    }
  });

  // Arrow-key navigation + Enter to open
  input.addEventListener('keydown', function (e) {
    var links = resultsBox.querySelectorAll('a');
    if (resultsBox.style.display !== 'block' || links.length === 0) return;
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      selectedIdx = Math.min(selectedIdx + 1, links.length - 1);
      updateSelection();
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      selectedIdx = Math.max(selectedIdx - 1, 0);
      updateSelection();
    } else if (e.key === 'Enter' && selectedIdx >= 0) {
      e.preventDefault();
      window.location.href = links[selectedIdx].getAttribute('href');
    }
  });

  document.addEventListener('click', function (e) {
    if (!resultsBox.contains(e.target) && e.target !== input) {
      resultsBox.style.display = 'none';
    }
  });

  // Ctrl+K / ⌘K to focus search (like GitHub docs)
  document.addEventListener('keydown', function (e) {
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
      e.preventDefault();
      input.focus();
      input.select();
    }
    // Escape to close results
    if (e.key === 'Escape') {
      resultsBox.style.display = 'none';
      input.blur();
    }
  });

  // Show keyboard hint in placeholder
  var isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0;
  var shortcut = isMac ? '\u2318K' : 'Ctrl+K';
  input.setAttribute('placeholder', 'Поиск по статьям... (' + shortcut + ')');
})();
      updateSelection();
    } else if (e.key === 'Enter' && selectedIdx >= 0) {
      e.preventDefault();
      links[selectedIdx].click();
      window.location.href = links[selectedIdx].getAttribute('href');
    }
  });
  
  // Ctrl+K / \u2318K to focus search (like GitHub docs)
  document.addEventListener('keydown', function (e) {
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
      e.preventDefault();
      input.focus();
      input.select();
    }
    // Escape to close results
    if (e.key === 'Escape') {
      resultsBox.style.display = 'none';
      input.blur();
    }
  });

  // Show keyboard hint in placeholder
  var isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0;
  var shortcut = isMac ? '\u2318K' : 'Ctrl+K';
  input.setAttribute('placeholder', 'Поиск по статьям... (' + shortcut + ')');
})();
