#' Compare population and area weights
#'
#' Districts that were split had to be divided between their successors, by
#' population (default) or by area. `pks_compare_weights()` puts both
#' versions of a harmonized panel side by side, so you can see where and how
#' much a result depends on that choice. Merged and unchanged districts are
#' the same under both weights.
#'
#' @param data A harmonized tibble from [pks_get()] (not `harmonize_to =
#'   NULL`), with population or area weights.
#' @param other `NULL` (default) to download the same years, offences,
#'   boundary and data version with the other weights, or that panel itself,
#'   for example when you have it already or work offline.
#' @return A tibble with one row per year, district and offence key:
#'   `year`, `ags`, `region_name`, `offence_key`, `estimated` (split in at
#'   least one of the two panels), `cases_population`, `cases_area`,
#'   `difference` (area minus population), `relative_difference`
#'   (`difference / cases_population`), `hz_population` and `hz_area`
#'   (recomputed with [pks_rates()]). A message summarizes how many rows
#'   differ.
#' @section Deutsch:
#' Stellt eine harmonisierte Tabelle mit Bevölkerungs- und mit
#' Flächengewichten nebeneinander. Die Gewichte unterscheiden sich nur bei
#' geteilten Kreisen; so lässt sich prüfen, wie stark ein Ergebnis von dieser
#' Annahme abhängt. `other` kann die Tabelle mit den anderen Gewichten
#' liefern, sonst wird sie mit denselben Jahren, Straftaten, demselben
#' Gebietsstand und derselben Datenversion geladen.
#' @family analysis
#' @export
#' @examplesIf interactive()
#' d <- pks_get(years = 2005:2010, offence = "total")
#' w <- pks_compare_weights(d)
#' w[abs(w$relative_difference) > 0.01, ]
pks_compare_weights <- function(data, other = NULL) {
  check_panel(data)
  weights <- attr(data, "weights")
  if (!isTRUE(weights %in% c("population", "area"))) {
    cli::cli_abort(c(
      tr("{.arg data} must be harmonized with population or area weights."),
      "i" = tr("Data as published ({.code harmonize_to = NULL}) have no weights to compare.")
    ))
  }
  other_weights <- setdiff(c("population", "area"), weights)
  if (is.null(other)) {
    other <- pks_get(
      years = unique(data$year), offence = unique(data$offence_key),
      harmonize_to = attr(data, "boundary_year"), weights = other_weights,
      version = attr(data, "data_version")
    )
  }
  check_panel(other, "other")
  if (!identical(attr(other, "weights"), other_weights)) {
    cli::cli_abort(tr("{.arg other} must have {other_weights} weights."))
  }

  key <- function(d) paste(d$year, d$ags, d$offence_key)
  i <- match(key(data), key(other))
  if (anyNA(i) || nrow(other) != nrow(data)) {
    cli::cli_abort(tr("{.arg data} and {.arg other} must have the same years, districts and offence keys."))
  }
  other <- other[i, ]
  panels <- stats::setNames(list(data, other), c(weights, other_weights))
  cases <- lapply(panels, function(d) dplyr::coalesce(as.numeric(d$cases), d$cases_derived))
  hz <- lapply(panels, function(d) pks_rates(d)$hz)

  out <- tibble::tibble(
    year = data$year,
    ags = data$ags,
    region_name = data$region_name,
    offence_key = data$offence_key,
    estimated = data$estimated | other$estimated,
    cases_population = cases$population,
    cases_area = cases$area,
    difference = cases$area - cases$population,
    relative_difference = ifelse(cases$population == 0, NA_real_, (cases$area - cases$population) / cases$population),
    hz_population = hz$population,
    hz_area = hz$area
  )
  out <- out[order(out$year, out$offence_key, out$ags), ]

  # Rounding noise of the weights is not a difference
  differs <- !is.na(out$difference) & abs(out$difference) > 1e-6
  if (any(differs)) {
    score <- ifelse(differs, abs(out$relative_difference), -Inf)
    largest <- which.max(ifelse(is.na(score), 0, score))
    share <- sprintf("%.1f", 100 * abs(out$relative_difference[largest]))
    where <- paste0(out$region_name[largest], " (", out$ags[largest], ", ", out$year[largest], ")")
    cli::cli_inform(tr("{sum(differs)} of {nrow(out)} row{?s} differ between population and area weights; the largest relative difference is {share} percent in {where}."))
  } else {
    cli::cli_inform(tr("Population and area weights give the same values for all {nrow(out)} row{?s}."))
  }
  out
}
