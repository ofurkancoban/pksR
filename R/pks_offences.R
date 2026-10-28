#' List the harmonized offence keys
#'
#' The district tables contain a selected subset of offence keys
#' (Straftatenschluessel). The harmonized keys used by [pks_get()] are listed
#' here with a short name and a label in German or English, their parent key
#' and the years they cover. Mappings and names marked `status = "draft"`
#' have not been reviewed yet.
#'
#' The table is a snapshot of the offence map of pksR-data that ships with the
#' package, so it works offline. Each data release also contains its own
#' `offence_map.csv`, which [pks_get()] uses.
#'
#' @param pattern Optional text to search for in the keys, short names and
#'   labels of both languages. Capitals, spaces and umlauts do not matter, so
#'   `"Diebstahl"`, `"theft"` and `"435*00"` all work.
#' @param lang Language of the `name` and `label` columns: `"de"` or `"en"`.
#'   `NULL` (default) uses `options(pksR.lang)`, otherwise the language of the
#'   R session.
#' @return A tibble with `offence_key`, `name` (the short name accepted by
#'   `pks_get(offence = )`), `label`, `parent_key`, `valid_from`, `valid_to`,
#'   `status` and `notes`.
#' @family metadata
#' @export
#' @examples
#' pks_offences("Diebstahl", lang = "de")
#' pks_offences("theft", lang = "en")
pks_offences <- function(pattern = NULL, lang = NULL) {
  lang <- check_lang(lang)
  old_lang <- options(pksR.lang = lang)
  on.exit(options(old_lang), add = TRUE)
  m <- offence_map_snapshot
  out <- tibble::tibble(
    offence_key = m$offence_key_harmonized,
    name = m[[paste0("alias_", lang)]],
    label = m[[paste0("label_", lang)]],
    parent_key = m$parent_key,
    valid_from = m$valid_from,
    valid_to = m$valid_to,
    status = m$status,
    notes = m$notes
  )
  if (!is.null(pattern)) {
    if (!is.character(pattern) || length(pattern) != 1 || is.na(pattern)) {
      cli::cli_abort(tr("{.arg pattern} must be one string."))
    }
    n <- normalize_name(pattern)
    searched <- cbind(m$alias_en, m$alias_de, normalize_name(m$label_de), normalize_name(m$label_en))
    hit <- grepl(pattern, m$offence_key_harmonized, fixed = TRUE) |
      (nzchar(n) & rowSums(matrix(grepl(n, searched, fixed = TRUE), ncol = 4)) > 0)
    out <- out[hit, ]
  }
  out
}
