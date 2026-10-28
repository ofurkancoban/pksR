# Language of messages and labels: German or English (notes/decisions.md).
#
# The language is options(pksR.lang = "de" or "en"), otherwise the language
# of the R session (LANGUAGE, then the message locale). Messages are written
# in English in the code and wrapped in tr(); the German texts are in
# inst/i18n/de.po. R's own gettext is not used, because it ignores LANGUAGE
# in the C locale (CI runners) and cannot follow a package option.

pks_lang <- function() {
  lang <- getOption("pksR.lang")
  if (!is.null(lang)) {
    if (!identical(lang, "de") && !identical(lang, "en")) {
      cli::cli_abort("{.code options(pksR.lang)} must be {.val de} or {.val en}.")
    }
    return(lang)
  }
  session <- Sys.getenv("LANGUAGE")
  if (!nzchar(session)) session <- Sys.getlocale("LC_COLLATE")
  if (grepl("^de|german", session, ignore.case = TRUE)) "de" else "en"
}

# `lang` argument of the exported functions: NULL means pks_lang().
check_lang <- function(lang) {
  if (is.null(lang)) return(pks_lang())
  if (!identical(lang, "de") && !identical(lang, "en")) {
    cli::cli_abort(tr("{.arg lang} must be {.val de} or {.val en}."))
  }
  lang
}

# The German text of `x` when the language is German, otherwise `x`. The
# result is a cli template, interpolated by the cli function it is passed to.
tr <- function(x) {
  if (pks_lang() != "de") return(x)
  de <- translations()
  out <- unname(de[x])
  if (is.na(out)) x else out
}

translations <- function() {
  if (is.null(the$translations)) {
    the$translations <- read_po(system.file("i18n", "de.po", package = "pksR"))
  }
  the$translations
}

# A minimal reader for the po files of this package: one-line msgid and
# msgstr entries, comments starting with "#".
read_po <- function(path) {
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  unquote <- function(x, key) {
    x <- sub(paste0("^", key, " \""), "", x)
    x <- sub("\"$", "", x)
    gsub("\\\\\"", "\"", gsub("\\\\\\\\", "\\\\", x))
  }
  id <- which(startsWith(lines, "msgid \""))
  str <- id + 1L
  if (!all(startsWith(lines[str], "msgstr \""))) {
    cli::cli_abort("{.file {basename(path)}}: every msgid needs a msgstr on the next line.")
  }
  keep <- lines[id] != "msgid \"\""
  stats::setNames(enc2utf8(unquote(lines[str[keep]], "msgstr")), unquote(lines[id[keep]], "msgid"))
}

# Marks a text for translation without translating it (like gettext_noop),
# for texts that reach the package from a data release.
N_ <- function(x) x

# Data notes of the releases, so tr() can translate them when they are shown.
release_note_texts <- c(
  N_("clearance_rate is 0 where cases are 0. This follows the BKA tables and is not a real rate: some of these rows have cleared > 0 (cases recorded in earlier years). The 2022 table leaves these cells empty; they are set to 0 for consistency."),
  N_("As published: clearance_rate is 0 where cases are 0, except in 2022, where the BKA table leaves these cells empty (NA). It is not a real rate.")
)
