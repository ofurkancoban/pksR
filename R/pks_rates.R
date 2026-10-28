#' Recompute rates
#'
#' Rates cannot be harmonized: when districts are merged or split, the
#' published frequency (Haeufigkeitszahl, cases per 100,000 inhabitants) and
#' clearance rate of the old districts do not carry over. `pks_rates()`
#' recomputes them from the counts, with the population of the data or one
#' you supply.
#'
#' Cases come from `cases`, or from `cases_derived` in the PDF years, where
#' the BKA printed only rates. The clearance rate is 0 where cases are 0, as
#' in the BKA tables.
#'
#' @param data A tibble from [pks_get()].
#' @param population `NULL` (default) to use the population in `data`
#'   (published where available, otherwise derived from cases and HZ), or a
#'   data frame with columns `year`, `ags` and `population`, for example from
#'   an official population source. Every row of `data` must find a
#'   population.
#' @param per Rate denominator for column `rate` (default 100,000).
#' @return `data` with `hz` (cases per 100,000) and `clearance_rate`
#'   recomputed, and a new column `rate` (cases per `per`). The population
#'   used is in column `rate_population`.
#' @family analysis
#' @export
#' @examples
#' d <- pks_example()
#' pks_rates(d, per = 1000)[, c("year", "ags", "cases", "hz", "rate")]
pks_rates <- function(data, population = NULL, per = 1e5) {
  check_panel(data)
  if (!is.numeric(per) || length(per) != 1 || is.na(per) || per <= 0) {
    cli::cli_abort("{.arg per} must be one positive number.")
  }
  if (is.null(population)) {
    pop <- dplyr::coalesce(data$population, data$derived_population)
  } else {
    if (!is.data.frame(population) || !all(c("year", "ags", "population") %in% names(population))) {
      cli::cli_abort("{.arg population} must be a data frame with columns {.field year}, {.field ags} and {.field population}.")
    }
    population <- unique(tibble::tibble(
      year = as.integer(population$year), ags = as.character(population$ags), population = as.numeric(population$population)
    ))
    if (anyDuplicated(population[c("year", "ags")])) {
      cli::cli_abort("{.arg population} has several values for one year and district.")
    }
    i <- match(paste(data$year, data$ags), paste(population$year, population$ags))
    if (anyNA(i)) {
      missing <- unique(paste(data$year[is.na(i)], data$ags[is.na(i)]))
      cli::cli_abort("No population for {length(missing)} year and district pair{?s}: {.val {utils::head(missing, 10)}}")
    }
    pop <- population$population[i]
  }
  cases <- dplyr::coalesce(as.numeric(data$cases), data$cases_derived)
  cleared <- dplyr::coalesce(as.numeric(data$cleared), data$cleared_derived)
  data$rate_population <- pop
  data$hz <- cases / pop * 1e5
  data$rate <- cases / pop * per
  data$clearance_rate <- ifelse(!is.na(cases) & cases == 0, 0, cleared / cases * 100)
  data
}

# Columns every function on a panel needs.
check_panel <- function(data, arg = "data") {
  needed <- c("year", "ags", "offence_key", "cases", "cleared", "population", "derived_population", "cases_derived", "cleared_derived")
  if (!is.data.frame(data) || !all(needed %in% names(data))) {
    cli::cli_abort("{.arg {arg}} must be a tibble from {.fn pks_get}; missing column{?s} {.field {setdiff(needed, names(data))}}.")
  }
  invisible(data)
}
