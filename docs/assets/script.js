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

  var chartMarks = document.querySelectorAll(".viz-bar[data-value], .viz-dot[data-value]");
  if (chartMarks.length) {
    var tooltip = document.createElement("div");
    tooltip.className = "chart-tooltip";
    tooltip.setAttribute("role", "tooltip");
    var ttKey = document.createElement("span");
    ttKey.className = "tt-key";
    ttKey.style.cssText = "display:inline-block;width:8px;height:8px;border-radius:2px;margin-right:7px;";
    var ttLabel = document.createElement("span");
    ttLabel.className = "tt-label";
    var ttValue = document.createElement("span");
    ttValue.className = "tt-value";
    tooltip.appendChild(ttKey);
    tooltip.appendChild(ttLabel);
    tooltip.appendChild(document.createTextNode(" "));
    tooltip.appendChild(ttValue);
    document.body.appendChild(tooltip);

    function showTooltip(mark, x, y) {
      var isS2 = mark.classList.contains("s2");
      ttKey.style.background = isS2
        ? getComputedStyle(root).getPropertyValue("--series-2")
        : getComputedStyle(root).getPropertyValue("--series-1");
      ttLabel.textContent = mark.getAttribute("data-label") || "";
      ttValue.textContent = mark.getAttribute("data-value") || "";
      tooltip.style.left = x + "px";
      tooltip.style.top = y + "px";
      tooltip.classList.add("visible");
    }
    function hideTooltip() {
      tooltip.classList.remove("visible");
    }

    chartMarks.forEach(function (mark) {
      mark.addEventListener("pointerenter", function (e) {
        showTooltip(mark, e.clientX, e.clientY);
      });
      mark.addEventListener("pointermove", function (e) {
        showTooltip(mark, e.clientX, e.clientY);
      });
      mark.addEventListener("pointerleave", hideTooltip);
      mark.addEventListener("focus", function () {
        var r = mark.getBoundingClientRect();
        showTooltip(mark, r.left + r.width / 2, r.top);
      });
      mark.addEventListener("blur", hideTooltip);
    });
  }
})();
