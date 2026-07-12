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
})();
