// Language button of the two sites (English at /pksR/, German at
// /pksR/de/, built by pkgdown/build-site.R): open the same page in the
// other language. Each article has a German twin named <name>-de.
document.addEventListener("DOMContentLoaded", function () {
  var site = "https://ofurkancoban.github.io/pksR/";
  var articles = ["pksR", "harmonization", "provenance"];
  var here = window.location.href.split("#")[0].split("?")[0];
  if (here.indexOf(site) !== 0) return;
  var path = here.slice(site.length);
  var german = path.indexOf("de/") === 0;
  var target;
  if (german) {
    target = path.slice(3).replace(/^articles\/(\w+)-de\.html$/, "articles/$1.html");
  } else {
    target = "de/" + path.replace(/^articles\/(\w+)\.html$/, function (match, name) {
      return articles.indexOf(name) >= 0 ? "articles/" + name + "-de.html" : match;
    });
  }
  var button = german ? site : site + "de/";
  document.querySelectorAll("a.nav-link").forEach(function (a) {
    if (a.getAttribute("href") === button) a.setAttribute("href", site + target);
  });
});
