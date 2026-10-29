#' Known methodological breaks
#'
#' Changes in the PKS that make values before and after a year incomparable
#' or only partly comparable: new offence definitions, key changes, changes in
#' the population denominator, boundary reforms and others. Check these
#' before interpreting changes over time.
#' Real shocks such as the Covid-19 pandemic (2020 and 2021) are not
#' breaks: they change recorded crime, not how it is measured.
#'
#' The table is a snapshot of `known_breaks.csv` of pksR-data that ships with
#' the package; each data release contains its own copy.
#'
#' @return A tibble with `break_id`, `first_year`, `offence_key` (keys
#'   separated by `;`, empty when all keys are affected), `variable`, `type`,
#'   `comparable` (`yes`, `likely`, `unknown`, `no`), `description`,
#'   `evidence` and `status`.
#' @section Deutsch:
#' Bekannte methodische Brüche der PKS: neue Definitionen, geänderte
#' Schlüssel, geänderte Bezugsbevölkerung, Gebietsreformen und andere.
#' `comparable` gibt an, ob Werte vor und nach dem Jahr vergleichbar sind
#' (`yes`, `likely`, `unknown`, `no`). Vor jeder Zeitreihe prüfen.
#' Echte Schocks wie die Covid-19-Pandemie (2020 und 2021) sind keine
#' Brüche: Sie verändern die erfasste Kriminalität, nicht ihre Messung.
#' @family metadata
#' @export
#' @examples
#' b <- pks_breaks()
#' b[b$comparable == "no", c("first_year", "offence_key", "description")]
pks_breaks <- function() {
  tibble::as_tibble(known_breaks_snapshot)
}
