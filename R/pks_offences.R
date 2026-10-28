#' List the harmonized offence keys
#'
#' The district tables contain a selected subset of offence keys
#' (Straftatenschluessel). The harmonized keys used by [pks_get()] are listed
#' here with their German and English labels, their parent key and the years
#' they cover. Mappings marked `status = "draft"` have not been reviewed yet.
#'
#' The table is a snapshot of the offence map of pksR-data that ships with the
#' package, so it works offline. Each data release also contains its own
#' `offence_map.csv`, which [pks_get()] uses.
#'
#' @param pattern Optional text to search for: an offence key (matched
#'   literally, so `"435*00"` works) or a regular expression matched against
#'   the labels, ignoring case.
#' @param lang Language of the `label` column: `"de"` (default) or `"en"`.
#' @return A tibble with `offence_key`, `label`, `parent_key`, `valid_from`,
#'   `valid_to`, `status` and `notes`.
#' @family metadata
#' @export
#' @examples
#' pks_offences("Diebstahl")
#' pks_offences("theft", lang = "en")
pks_offences <- function(pattern = NULL, lang = c("de", "en")) {
  lang <- match.arg(lang)
  m <- offence_map_snapshot
  out <- tibble::tibble(
    offence_key = m$offence_key_harmonized,
    label = if (lang == "de") m$label_de else m$label_en,
    parent_key = m$parent_key,
    valid_from = m$valid_from,
    valid_to = m$valid_to,
    status = m$status,
    notes = m$notes
  )
  if (!is.null(pattern)) {
    if (!is.character(pattern) || length(pattern) != 1 || is.na(pattern)) {
      cli::cli_abort("{.arg pattern} must be one string.")
    }
    hit <- grepl(pattern, out$offence_key, fixed = TRUE) |
      grepl(pattern, out$label, ignore.case = TRUE, perl = TRUE)
    out <- out[hit, ]
  }
  out
}
