# Updates inst/i18n/de.po from the texts marked with tr() or N_() in R/.
# Existing translations are kept, new texts get an empty msgstr, and texts
# no longer in the code are dropped and listed. Usage (package root):
#   Rscript data-raw/translations.R
files <- list.files("R", pattern = "[.]R$", full.names = TRUE)
texts <- unlist(lapply(files, function(f) {
  p <- utils::getParseData(parse(f, keep.source = TRUE))
  calls <- which(p$token == "SYMBOL_FUNCTION_CALL" & p$text %in% c("tr", "N_"))
  unlist(lapply(calls, function(i) {
    # The text is the string constant of the call's first argument
    call <- p$parent[p$id == p$parent[i]]
    kids <- p[p$parent == call, ]
    str <- p$text[p$parent %in% kids$id[kids$token == "expr"][-1] & p$token == "STR_CONST"][1]
    if (is.na(str)) NULL else eval(parse(text = str))
  }))
}))
texts <- unique(texts)

source("R/lang.R")
path <- "inst/i18n/de.po"
old <- if (file.exists(path)) read_po(path) else character(0)
quote <- function(x) paste0("\"", gsub("\"", "\\\\\"", gsub("\\\\", "\\\\\\\\", x)), "\"")
entries <- unlist(lapply(texts, function(x) {
  c(paste("msgid", quote(x)), paste("msgstr", quote(if (x %in% names(old)) old[[x]] else "")), "")
}))
header <- c(
  "# German texts of pksR (read by R/lang.R). Updated by data-raw/translations.R;",
  "# keep placeholders in braces exactly as in the msgid.",
  "msgid \"\"", "msgstr \"Content-Type: text/plain; charset=UTF-8\"", ""
)
writeLines(enc2utf8(c(header, entries)), path, useBytes = TRUE)
missing <- setdiff(texts, names(old)[nzchar(old)])
dropped <- setdiff(names(old), texts)
cat(length(texts), "texts,", length(missing), "without translation,", length(dropped), "dropped\n")
if (length(dropped)) cat("Dropped:", dropped, sep = "\n  ")
