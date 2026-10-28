#' Known methodological breaks
#'
#' Changes in the PKS that make values before and after a year incomparable
#' or only partly comparable: new offence definitions, key changes, changes in
#' the population denominator, boundary reforms and others. Check these
#' before interpreting changes over time.
#'
#' The table is a snapshot of `known_breaks.csv` of pksR-data that ships with
#' the package; each data release contains its own copy.
#'
#' @return A tibble with `break_id`, `first_year`, `offence_key` (keys
#'   separated by `;`, empty when all keys are affected), `variable`, `type`,
#'   `comparable` (`yes`, `likely`, `unknown`, `no`), `description`,
#'   `evidence` and `status`.
#' @family metadata
#' @export
#' @examples
#' b <- pks_breaks()
#' b[b$comparable == "no", c("first_year", "offence_key", "description")]
pks_breaks <- function() {
  tibble::as_tibble(known_breaks_snapshot)
}
