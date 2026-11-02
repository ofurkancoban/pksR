# Builds the pkgdown site in English (docs/) and in German (docs/de/).
# pkgdown has no multilingual sites, so the German site is a second build
# with the settings of pkgdown/_pkgdown-de.yml and README.de.md as its home
# page. Run from the package root:
#   Rscript pkgdown/build-site.R

site <- "https://ofurkancoban.github.io/pksR/"

# pkgdown takes pkgdown/index.md as home page before README.md. The
# language links of the READMEs point to the other README on GitHub; on
# the site they switch between the two sites.
write_home <- function(readme, links, pkg = ".") {
  lines <- readLines(readme, encoding = "UTF-8")
  at <- grep("^\\*\\*English\\*\\* \\||\\| \\*\\*Deutsch\\*\\*$", lines)
  if (length(at) != 1) stop("No language line found in ", readme)
  lines[at] <- links
  writeLines(enc2utf8(lines), file.path(pkg, "pkgdown", "index.md"), useBytes = TRUE)
}

# English site
tryCatch({
  write_home("README.md", sprintf("**English** | [Deutsch](%sde/)", site))
  pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)
}, finally = unlink(file.path("pkgdown", "index.md")))

# German site. The override argument of pkgdown merges named settings
# only and would keep the English lists of articles and reference
# sections, so it is built from a copy of the package whose _pkgdown.yml
# holds the German settings.
copy <- file.path(tempfile("pksR-de-"), "pksR")
dir.create(copy, recursive = TRUE)
files <- setdiff(list.files(".", all.files = TRUE, no.. = TRUE), c("docs", ".git"))
file.copy(files, copy, recursive = TRUE)
en <- yaml::read_yaml("_pkgdown.yml")
de <- yaml::read_yaml(file.path("pkgdown", "_pkgdown-de.yml"))
config <- utils::modifyList(en, de)
config$articles <- de$articles
config$reference <- de$reference
config$destination <- file.path(normalizePath("docs"), "de")
yaml::write_yaml(config, file.path(copy, "_pkgdown.yml"))
write_home("README.de.md", sprintf("[English](%s) | **Deutsch**", site), pkg = copy)
pkgdown::build_site(copy, new_process = FALSE, install = FALSE, preview = FALSE)
unlink(dirname(copy), recursive = TRUE)
