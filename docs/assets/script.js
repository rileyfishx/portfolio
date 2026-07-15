(function () {
  var root = document.documentElement;
  var saved = localStorage.getItem("theme");
  if (saved) root.setAttribute("data-theme", saved);

  document.querySelectorAll("[data-theme-toggle]").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var current = root.getAttribute("data-theme");
      var prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
      var isDark = current ? current === "dark" : prefersDark;
      var next = isDark ? "light" : "dark";
      root.setAttribute("data-theme", next);
      localStorage.setItem("theme", next);
    });
  });

  var KEYWORDS = ["SELECT","FROM","WHERE","JOIN","LEFT","RIGHT","INNER","OUTER","ON",
    "GROUP BY","GROUP","BY","ORDER","PARTITION","AS","CASE","WHEN","THEN","ELSE","END",
    "WITH","OVER","AND","OR","NOT","NULL","DESC","ASC","IN","BETWEEN","LIKE","USE",
    "DISTINCT","HAVING","UNION","LIMIT","INTO","VALUES","CREATE","TABLE","INSERT",
    "UPDATE","DELETE","EXISTS","IS"];
  var FUNCTIONS = ["RANK","COUNT","SUM","AVG","ROUND","COALESCE","MAX","MIN",
    "TIMESTAMPDIFF","YEAR","MONTH","MONTHNAME","CURDATE","CONCAT"];

  function escapeHtml(str) {
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  }

  function highlight(raw) {
    var tokenRe = /(--[^\n]*)|('[^']*')|(\b\d+(?:\.\d+)?\b)|(\b[A-Za-z_]+\b)/g;
    var out = "";
    var last = 0;
    var m;
    while ((m = tokenRe.exec(raw)) !== null) {
      out += escapeHtml(raw.slice(last, m.index));
      var token = m[0];
      if (m[1]) {
        out += '<span class="c">' + escapeHtml(token) + "</span>";
      } else if (m[2]) {
        out += '<span class="s">' + escapeHtml(token) + "</span>";
      } else if (m[3]) {
        out += '<span class="n">' + escapeHtml(token) + "</span>";
      } else {
        var upper = token.toUpperCase();
        if (KEYWORDS.indexOf(upper) !== -1) {
          out += '<span class="k">' + escapeHtml(token) + "</span>";
        } else if (FUNCTIONS.indexOf(upper) !== -1) {
          out += '<span class="f">' + escapeHtml(token) + "</span>";
        } else {
          out += escapeHtml(token);
        }
      }
      last = tokenRe.lastIndex;
    }
    out += escapeHtml(raw.slice(last));
    return out;
  }

  document.querySelectorAll("pre.sql").forEach(function (block) {
    block.innerHTML = highlight(block.textContent.replace(/^\n/, "").replace(/\n$/, ""));
  });

  var seriesColor = function (slot) {
    return getComputedStyle(root).getPropertyValue(slot === "s2" ? "--series-2" : "--series-1").trim();
  };
  // Reads the mark's own resolved fill so any series class (s1/s2, f1-f4,
  // above/below, or the default bubble hue) works without special-casing.
  var markColor = function (mark) {
    var fill = getComputedStyle(mark).fill;
    return fill && fill !== "none" ? fill : seriesColor("s1");
  };

  var chartMarks = document.querySelectorAll(
    ".viz-bar[data-value], .viz-dot[data-value], .viz-seg[data-value], .viz-bubble[data-value], .viz-lolli[data-value]"
  );
  var tooltip = null;
  if (chartMarks.length || document.querySelector(".viz-hit-col")) {
    tooltip = document.createElement("div");
    tooltip.className = "chart-tooltip";
    tooltip.setAttribute("role", "tooltip");
    document.body.appendChild(tooltip);
  }

  function positionTooltip(x, y) {
    tooltip.style.left = x + "px";
    tooltip.style.top = y + "px";
    tooltip.classList.add("visible");
  }
  function hideTooltip() {
    if (tooltip) tooltip.classList.remove("visible");
  }

  // Single-mark tooltip: bars and individually-focused dots.
  if (chartMarks.length) {
    function showMarkTooltip(mark, x, y) {
      tooltip.innerHTML = "";
      var row = document.createElement("div");
      row.className = "tt-row";
      var key = document.createElement("span");
      key.className = "tt-key";
      key.style.background = markColor(mark);
      var name = document.createElement("span");
      name.className = "tt-name";
      name.textContent = mark.getAttribute("data-label") || "";
      var val = document.createElement("span");
      val.className = "tt-value";
      val.textContent = mark.getAttribute("data-value") || "";
      row.appendChild(key);
      row.appendChild(name);
      row.appendChild(val);
      tooltip.appendChild(row);
      positionTooltip(x, y);
    }
    chartMarks.forEach(function (mark) {
      mark.addEventListener("pointerenter", function (e) { showMarkTooltip(mark, e.clientX, e.clientY); });
      mark.addEventListener("pointermove", function (e) { showMarkTooltip(mark, e.clientX, e.clientY); });
      mark.addEventListener("pointerleave", hideTooltip);
      mark.addEventListener("focus", function () {
        var r = mark.getBoundingClientRect();
        showMarkTooltip(mark, r.left + r.width / 2, r.top);
      });
      mark.addEventListener("blur", hideTooltip);
    });
  }

  // Crosshair + combined tooltip for line charts: hovering a month column
  // shows both series at once and snaps a vertical hairline to that month.
  document.querySelectorAll(".viz-svg-line").forEach(function (svg) {
    var crosshair = svg.querySelector(".viz-crosshair");
    var hitCols = svg.querySelectorAll(".viz-hit-col");
    var dots = svg.querySelectorAll(".viz-dot");
    if (!hitCols.length) return;

    function activateMonth(i, clientX, clientY) {
      var top = parseFloat(crosshair.getAttribute("data-top"));
      var bottom = parseFloat(crosshair.getAttribute("data-bottom"));
      var col = svg.querySelector('.viz-hit-col[data-month="' + i + '"]');
      var cx = parseFloat(col.getAttribute("x")) + parseFloat(col.getAttribute("width")) / 2;
      crosshair.setAttribute("x1", cx);
      crosshair.setAttribute("x2", cx);
      crosshair.setAttribute("y1", top);
      crosshair.setAttribute("y2", bottom);
      crosshair.classList.add("visible");

      dots.forEach(function (d) {
        d.classList.toggle("active", d.getAttribute("data-month") === String(i));
      });

      tooltip.innerHTML = "";
      var head = document.createElement("div");
      head.className = "tt-head";
      head.textContent = col.getAttribute("data-label") || "";
      tooltip.appendChild(head);
      [["s1", "Home", col.getAttribute("data-home")], ["s2", "Away", col.getAttribute("data-away")]].forEach(function (s) {
        var row = document.createElement("div");
        row.className = "tt-row";
        var key = document.createElement("span");
        key.className = "tt-key";
        key.style.background = seriesColor(s[0]);
        var name = document.createElement("span");
        name.className = "tt-name";
        name.textContent = s[1];
        var val = document.createElement("span");
        val.className = "tt-value";
        val.textContent = s[2];
        row.appendChild(key);
        row.appendChild(name);
        row.appendChild(val);
        tooltip.appendChild(row);
      });
      positionTooltip(clientX, clientY);
    }

    function deactivate() {
      crosshair.classList.remove("visible");
      dots.forEach(function (d) { d.classList.remove("active"); });
      hideTooltip();
    }

    hitCols.forEach(function (col) {
      var month = col.getAttribute("data-month");
      col.addEventListener("pointerenter", function (e) { activateMonth(month, e.clientX, e.clientY); });
      col.addEventListener("pointermove", function (e) { activateMonth(month, e.clientX, e.clientY); });
      col.addEventListener("pointerleave", deactivate);
    });
    svg.addEventListener("pointerleave", deactivate);
  });

  // Entrance animation: bars grow, lines draw in, dots fade — once, on first
  // scroll into view. Respects prefers-reduced-motion via the CSS gate.
  var charts = document.querySelectorAll(".chart-wrap");
  if (charts.length && "IntersectionObserver" in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("chart-in-view");
          io.unobserve(entry.target);
        }
      });
    }, { threshold: 0.2 });
    charts.forEach(function (c) { io.observe(c); });
  } else {
    charts.forEach(function (c) { c.classList.add("chart-in-view"); });
  }
})();
