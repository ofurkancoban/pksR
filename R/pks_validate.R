#' Validate a panel
#'
#' Runs the consistency checks of the pksR-data validation gate that need
#' only the panel itself: schema, uniqueness, coverage and plausibility. Use
#' it after filtering, joining or editing data from [pks_get()]. The checks of
#' national totals and conservation need the national tables and run in the
#' pipeline before every release.
#'
#' Checks:
#' * `schema`: the columns of the data as published or harmonized, with their
#'   types.
#' * `uniqueness`: one row per `year`, `ags` and `offence_key`.
#' * `city_states`: Berlin (`11000`) and Hamburg (`02000`) present in every
#'   year.
#' * `coverage`: harmonized data have the same districts in every year
#'   (balanced panel).
#' * `counts`: no negative counts, and `attempts` not above `cases`.
#' * `population`: the median district population per year lies between
#'   50,000 and 400,000 (a warning otherwise).
#'
#' @param data A tibble from [pks_get()].
#' @return A tibble with one row per check: `check`, `status` (`pass`,
#'   `warn` or `fail`), `problems` (number of offending rows or years) and
#'   `details`.
#' @family analysis
#' @export
#' @examples
#' pks_validate(pks_example())
pks_validate <- function(data) {
  if (!is.data.frame(data)) cli::cli_abort(tr("{.arg data} must be a data frame."))
  spec <- if ("offence_key_published" %in% names(data)) harmonized_spec else canonical_spec
  checks <- list(
    check_schema(data, spec),
    check_unique(data),
    check_city_states(data),
    check_coverage(data),
    check_counts(data),
    check_population(data)
  )
  out <- dplyr::bind_rows(checks)
  n <- table(factor(out$status, c("pass", "warn", "fail")))
  cli::cli_inform(tr("Validation: {n[['pass']]} passed, {n[['warn']]} warning{?s}, {n[['fail']]} failed."))
  for (i in which(out$status != "pass")) {
    cli::cli_inform(c("!" = tr("{out$check[i]}: {out$details[i]}")))
  }
  out
}

check_result <- function(check, problems, details, warn_only = FALSE) {
  status <- if (problems == 0) "pass" else if (warn_only) "warn" else "fail"
  tibble::tibble(check = check, status = status, problems = as.integer(problems), details = if (problems == 0) "" else details)
}

check_schema <- function(data, spec) {
  missing <- setdiff(names(spec), names(data))
  present <- intersect(names(spec), names(data))
  types <- vapply(data[present], typeof, "")
  wrong <- present[types != spec[present]]
  check_result("schema", length(missing) + length(wrong),
               sprintf(tr("missing: %s; wrong type: %s"), paste(missing, collapse = ", "), paste(wrong, collapse = ", ")))
}

check_unique <- function(data) {
  if (!all(c("year", "ags", "offence_key") %in% names(data))) return(check_result("uniqueness", 1, tr("year, ags or offence_key missing")))
  dup <- duplicated(data[c("year", "ags", "offence_key")])
  check_result("uniqueness", sum(dup), sprintf(tr("%d duplicate year, ags, offence_key rows"), sum(dup)))
}

check_city_states <- function(data) {
  if (!all(c("year", "ags") %in% names(data))) return(check_result("city_states", 1, tr("year or ags missing")))
  missing <- vapply(split(data$ags, data$year), function(a) {
    paste(setdiff(c("11000", "02000"), a), collapse = ", ")
  }, "")
  bad <- missing[nzchar(missing)]
  check_result("city_states", length(bad), paste(sprintf(tr("%s: %s missing"), names(bad), bad), collapse = "; "))
}

check_coverage <- function(data) {
  if (!"harmonized" %in% names(data) || !"offence_key_published" %in% names(data)) {
    return(check_result("coverage", 0, ""))
  }
  sets <- lapply(split(data$ags, data$year), function(a) sort(unique(a)))
  ref <- sets[[which.max(lengths(sets))]]
  differ <- names(sets)[!vapply(sets, identical, TRUE, ref)]
  check_result("coverage", length(differ), sprintf(tr("district set differs in %s"), paste(differ, collapse = ", ")))
}

check_counts <- function(data) {
  cols <- intersect(c(count_columns, "cases_derived", "cleared_derived"), names(data))
  negative <- Reduce(`|`, lapply(cols, function(col) !is.na(data[[col]]) & data[[col]] < 0), FALSE)
  over <- if (all(c("attempts", "cases") %in% names(data))) {
    !is.na(data$attempts) & !is.na(data$cases) & data$attempts > data$cases + 1e-9
  } else {
    FALSE
  }
  check_result("counts", sum(negative | over),
               sprintf(tr("%d rows with negative counts, %d with attempts above cases"), sum(negative), sum(over)))
}

check_population <- function(data) {
  if (!all(c("year", "ags", "population", "derived_population") %in% names(data))) {
    return(check_result("population", 1, tr("population columns missing"), warn_only = TRUE))
  }
  pop <- unique(data.frame(year = data$year, ags = data$ags, p = dplyr::coalesce(data$population, data$derived_population)))
  med <- vapply(split(pop$p, pop$year), stats::median, 1, na.rm = TRUE)
  bad <- names(med)[is.na(med) | med < 5e4 | med > 4e5]
  check_result("population", length(bad),
               sprintf(tr("median district population outside 50,000 to 400,000 in %s"), paste(bad, collapse = ", ")),
               warn_only = TRUE)
}
