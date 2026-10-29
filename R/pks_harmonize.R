# Territorial and offence harmonization (brief Section 6), ported from
# R/harmonize_space.R, R/harmonize_offence.R and R/boundary_map.R of
# pksR-data. The pipeline harmonizes to the latest boundary; this copy lets
# pks_get() harmonize the data as published to any other boundary year with
# the crosswalk and offence map of the same data release. A test checks that
# both give the same panel for the latest boundary.

boundary_map_columns <- c(
  "id", "period", "from_ags", "from_name", "to_ags", "to_name",
  "weight_population", "weight_area", "source", "replaces", "status", "reason"
)

read_boundary_map <- function(path) {
  m <- readr::read_csv(path, col_types = readr::cols(.default = "c"), na = "", progress = FALSE)
  if (!all(boundary_map_columns %in% names(m))) {
    cli::cli_abort(tr("{.file {basename(path)}} lacks columns {.val {setdiff(boundary_map_columns, names(m))}}."))
  }
  m$period <- as.integer(m$period)
  m$weight_population <- as.numeric(m$weight_population)
  m$weight_area <- as.numeric(m$weight_area)
  m[boundary_map_columns]
}

# The crosswalk actually used: BBSR rows, with documented manual rows in
# place of the BBSR rows they replace, plus transfers BBSR omits (source
# "destatis"), whose share is taken off the giving district's own row.
effective_boundary_map <- function(map) {
  replaced <- map$id %in% map$replaces[map$source == "manual"]
  out <- map[!replaced & map$source != "destatis", ]
  added <- map[map$source == "destatis", ]
  for (i in seq_len(nrow(added))) {
    own <- which(out$period == added$period[i] & out$from_ags == added$from_ags[i] & out$to_ags == added$from_ags[i])
    if (length(own) != 1) {
      cli::cli_abort(tr("{added$id[i]}: the giving district has no own row to take the transfer from."))
    }
    out$weight_population[own] <- out$weight_population[own] - added$weight_population[i]
    out$weight_area[own] <- out$weight_area[own] - added$weight_area[i]
  }
  out <- dplyr::bind_rows(out, added)
  assert_boundary_map(out)
  out
}

# Weights sum to 1 per source district and period, and consecutive periods
# chain: the districts at 31.12.(t+1) are the sources of period t+1.
assert_boundary_map <- function(map, tolerance = 1e-6) {
  for (w in c("weight_population", "weight_area")) {
    sums <- stats::aggregate(map[[w]], map[c("period", "from_ags")], sum)
    if (any(abs(sums$x - 1) > tolerance)) {
      cli::cli_abort(tr("{w} does not sum to 1 for {sum(abs(sums$x - 1) > tolerance)} source district{?s} of the crosswalk."))
    }
  }
  periods <- sort(unique(map$period))
  if (!identical(periods, seq(min(periods), max(periods)))) {
    cli::cli_abort(tr("The crosswalk periods have gaps."))
  }
  for (p in periods[-length(periods)]) {
    if (!identical(sort(unique(map$to_ags[map$period == p])), sort(unique(map$from_ags[map$period == p + 1])))) {
      cli::cli_abort(tr("Crosswalk periods {p} and {p + 1} do not chain."))
    }
  }
  invisible(map)
}

# District codes valid on 31.12. of `year` according to the crosswalk.
boundary_codes <- function(map, year) {
  if (year %in% map$period) {
    return(sort(unique(map$from_ags[map$period == year])))
  }
  if ((year - 1) %in% map$period) {
    return(sort(unique(map$to_ags[map$period == year - 1])))
  }
  cli::cli_abort(tr("The crosswalk does not cover the boundary of {year}."))
}

boundary_names <- function(map, year) {
  rows <- if (year %in% map$period) {
    map[map$period == year, c("from_ags", "from_name")]
  } else {
    map[map$period == year - 1, c("to_ags", "to_name")]
  }
  names(rows) <- c("ags", "name")
  rows <- unique(rows)
  if (anyDuplicated(rows$ags)) {
    cli::cli_abort(tr("Boundary {year}: codes with several names: {.val {unique(rows$ags[duplicated(rows$ags)])}}"))
  }
  rows
}

# Boundary years the crosswalk can harmonize to.
boundary_years <- function(map) {
  seq(min(map$period), max(map$period) + 1L)
}

# Compose the yearly steps into one map from the boundary of `from_year` to
# the boundary of `to_year` (forward only).
compose_crosswalk <- function(map, from_year, to_year, weights = c("population", "area")) {
  weights <- match.arg(weights)
  if (to_year < from_year) {
    cli::cli_abort(tr("Only forward harmonization is supported ({from_year} to {to_year})."))
  }
  w_col <- paste0("weight_", weights)
  codes <- boundary_codes(map, from_year)
  cw <- tibble::tibble(from_ags = codes, to_ags = codes, weight = 1)
  for (p in seq_len(to_year - from_year) + from_year - 1L) {
    step <- map[map$period == p, c("from_ags", "to_ags", w_col)]
    if (nrow(step) == 0) {
      cli::cli_abort(tr("The crosswalk has no period {p}-{p + 1}."))
    }
    names(step) <- c("mid_ags", "next_ags", "w")
    names(cw)[2] <- "mid_ags"
    cw <- join_checked(cw, step, by = "mid_ags", what = paste("crosswalk period", p))
    cw <- dplyr::summarise(
      dplyr::group_by(cw, .data$from_ags, to_ags = .data$next_ags),
      weight = sum(.data$weight * .data$w), .groups = "drop"
    )
  }
  cw
}

# One population value per district: the published population where it
# exists, otherwise the derived population of the total-crime row, which has
# the most cases and therefore the least rounding in HZ.
district_population <- function(data) {
  rows <- lapply(split(data, data$ags), function(d) {
    pop <- unique(d$population)
    if (length(pop) != 1) {
      cli::cli_abort(tr("District {d$ags[1]}: published population differs between offence keys."))
    }
    corrected <- unique(d$population_corrected)
    if (length(corrected) != 1) {
      cli::cli_abort(tr("District {d$ags[1]}: corrected population differs between offence keys."))
    }
    total <- d$derived_population[d$offence_key %in% c("------", "----")]
    derived <- if (length(total) == 1 && !is.na(total)) total else stats::median(d$derived_population, na.rm = TRUE)
    tibble::tibble(ags = d$ags[1], population = pop, derived_population = if (is.na(derived)) NA_real_ else derived,
                   population_corrected = corrected)
  })
  dplyr::bind_rows(rows)
}

# A missing value in one source district stays NA instead of turning into an
# undercount of the target district.
sum_weighted <- function(x, w) {
  if (anyNA(x)) NA_real_ else sum(x * w)
}

# Counts are moved with the crosswalk weights; rates are recomputed, never
# weighted. One year of data as published, all with the same boundary year.
harmonize_space <- function(data, map, target, weights = c("population", "area")) {
  weights <- match.arg(weights)
  from_year <- unique(data$boundary_year)
  if (length(from_year) != 1) {
    cli::cli_abort(tr("Data to harmonize must have one boundary year."))
  }
  cw <- compose_crosswalk(map, from_year, target, weights)

  unmatched <- setdiff(unique(data$ags), cw$from_ags)
  if (length(unmatched) > 0) {
    cli::cli_warn(tr("{unique(data$year)}: {length(unmatched)} AGS code{?s} not in the crosswalk at {from_year}: {.val {unmatched}}"))
    n <- nrow(data)
    data <- data[!data$ags %in% unmatched, ]
    log_rows_removed(n, nrow(data), "AGS codes without crosswalk row")
  }

  tol <- 1e-9
  status <- dplyr::summarise(
    dplyr::group_by(cw, .data$to_ags),
    identity = dplyr::n() == 1 & .data$from_ags[1] == .data$to_ags[1] & abs(.data$weight[1] - 1) < tol,
    split = any(abs(.data$weight - 1) >= tol),
    .groups = "drop"
  )

  pop <- district_population(data)
  pop <- join_checked(pop, cw, by = c(ags = "from_ags"), what = "population and crosswalk")
  pop <- dplyr::summarise(
    dplyr::group_by(pop, ags = .data$to_ags),
    population = sum_weighted(.data$population, .data$weight),
    derived_population = sum_weighted(.data$derived_population, .data$weight),
    population_corrected = sum_weighted(.data$population_corrected, .data$weight),
    .groups = "drop"
  )

  joined <- join_checked(data, cw, by = c(ags = "from_ags"), what = "data and crosswalk")
  out <- dplyr::summarise(
    dplyr::group_by(joined, .data$offence_key, ags = .data$to_ags),
    dplyr::across(dplyr::all_of(harmonized_counts), ~ sum_weighted(.x, .data$weight)),
    published_name = if (dplyr::n() == 1) .data$region_name[1] else NA_character_,
    offence_label = .data$offence_label[1],
    hz_published = if (dplyr::n() == 1) .data$hz[1] else NA_real_,
    clearance_rate_published = if (dplyr::n() == 1) .data$clearance_rate[1] else NA_real_,
    source_estimated = any(.data$estimated),
    .groups = "drop"
  )
  out <- join_checked(out, status, by = c(ags = "to_ags"), what = "data and district status")
  out <- join_checked(out, pop, by = "ags", what = "data and population")
  out <- join_checked(out, boundary_names(map, target), by = "ags", what = "data and target names")

  cases <- dplyr::coalesce(out$cases, out$cases_derived)
  cleared <- dplyr::coalesce(out$cleared, out$cleared_derived)
  denominator <- dplyr::coalesce(out$population, out$derived_population)
  out$hz <- ifelse(out$identity, out$hz_published, cases / denominator * 1e5)
  # Zero cases: the BKA prints a clearance rate of 0; kept as 0 everywhere
  out$clearance_rate <- ifelse(out$identity, out$clearance_rate_published, cleared / cases * 100)
  out$clearance_rate[!is.na(cases) & cases == 0] <- 0
  out$region_name <- ifelse(out$identity, out$published_name, out$name)

  out$year <- unique(data$year)
  out$source_format <- unique(data$source_format)
  out$source_file <- unique(data$source_file)
  out$boundary_year <- as.integer(target)
  out$harmonized <- !out$identity
  out$weight_type <- ifelse(out$identity, "none", weights)
  out$estimated <- out$split | out$source_estimated
  out$offence_key_published <- out$offence_key
  out <- as_harmonized(out[intersect(names(harmonized_spec), names(out))])
  out[order(out$offence_key, out$ags), ]
}

# National totals per offence key and population must not change.
check_conservation <- function(before, after, tolerance = 1e-9) {
  totals <- function(d) {
    sums <- dplyr::summarise(
      dplyr::group_by(d, .data$offence_key),
      dplyr::across(dplyr::all_of(harmonized_counts), ~ if (all(is.na(.x))) NA_real_ else sum(.x, na.rm = TRUE)),
      .groups = "drop"
    )
    as.data.frame(sums[order(sums$offence_key), ])
  }
  a <- totals(before)
  b <- totals(after[, c("offence_key", harmonized_counts)])
  if (!identical(a$offence_key, b$offence_key)) {
    cli::cli_abort(tr("{unique(before$year)}: offence keys differ before and after harmonization."))
  }
  rel <- abs(as.matrix(b[-1]) - as.matrix(a[-1])) / pmax(abs(as.matrix(a[-1])), 1)
  district_total <- function(p) sum(dplyr::coalesce(p$population, p$derived_population))
  pop_before <- district_total(district_population(before))
  pop_after <- district_total(unique(after[c("ags", "population", "derived_population")]))
  corrected_before <- sum(district_population(before)$population_corrected)
  corrected_after <- sum(unique(after[c("ags", "population_corrected")])$population_corrected)
  changed <- function(x, y) is.na(x) != is.na(y) || isTRUE(abs(x - y) / y > tolerance)
  bad <- which(rel > tolerance | xor(is.na(as.matrix(a[-1])), is.na(as.matrix(b[-1]))), arr.ind = TRUE)
  if (nrow(bad) > 0 || changed(pop_after, pop_before) || changed(corrected_after, corrected_before)) {
    cli::cli_abort(tr("{unique(before$year)}: harmonization changed national totals for {.val {unique(a$offence_key[bad[, 1]])}}."))
  }
  invisible(TRUE)
}

# Offence map (registry offence_map.csv of the release). `source_keys` lists,
# per harmonized key, the published key in each year: entries
# "EXPR@YEARS" separated by ";", EXPR a key or "KEY minus KEY".
offence_map_columns <- c(
  "offence_key_harmonized", "label_de", "label_en", "parent_key",
  "valid_from", "valid_to", "source_keys", "status", "notes"
)

read_offence_map <- function(path) {
  m <- readr::read_csv(path, col_types = readr::cols(.default = "c"), na = "", progress = FALSE)
  if (!all(offence_map_columns %in% names(m))) {
    cli::cli_abort(tr("{.file {basename(path)}} lacks columns {.val {setdiff(offence_map_columns, names(m))}}."))
  }
  m$valid_from <- as.integer(m$valid_from)
  m$valid_to <- as.integer(m$valid_to)
  # Releases before the alias columns lack them (with_aliases() fills them)
  m[intersect(c(offence_map_columns, "alias_en", "alias_de"), names(m))]
}

offence_spec <- function(map) {
  rows <- lapply(seq_len(nrow(map)), function(i) {
    entries <- trimws(strsplit(map$source_keys[i], ";", fixed = TRUE)[[1]])
    dplyr::bind_rows(lapply(entries, function(e) {
      at <- regexpr("@[^@]*$", e)
      if (at < 0) cli::cli_abort(tr("Offence map entry {.val {e}} lacks @YEARS."))
      expr <- strsplit(substr(e, 1, at - 1), " minus ", fixed = TRUE)[[1]]
      if (!length(expr) %in% 1:2) cli::cli_abort(tr("Offence map entry {.val {e}} is not KEY or KEY minus KEY."))
      tibble::tibble(
        offence_key_harmonized = map$offence_key_harmonized[i],
        year = parse_years(substr(e, at + 1, nchar(e))),
        plus_key = expr[1],
        minus_key = if (length(expr) == 2) expr[2] else NA_character_
      )
    }))
  })
  dplyr::bind_rows(rows)
}

# Published keys become harmonized keys; a key is never summed with its
# parent or child implicitly, and an unmapped key is an error.
harmonize_offences <- function(data, map) {
  year <- unique(data$year)
  spec <- offence_spec(map)
  spec <- spec[spec$year == year, ]
  published <- unique(data$offence_key)
  unknown <- setdiff(published, spec$plus_key[is.na(spec$minus_key)])
  if (length(unknown) > 0) {
    cli::cli_abort(tr("{year}: offence key{?s} {.val {unknown}} not in the offence map of this data release."))
  }
  absent <- setdiff(stats::na.omit(c(spec$plus_key, spec$minus_key)), published)
  if (length(absent) > 0) {
    cli::cli_abort(tr("{year}: the offence map expects key{?s} {.val {absent}}, which the data lack."))
  }
  direct <- spec[is.na(spec$minus_key), ]
  out <- data[data$offence_key %in% direct$plus_key, ]
  out$offence_key <- direct$offence_key_harmonized[match(out$offence_key, direct$plus_key)]
  derived <- lapply(which(!is.na(spec$minus_key)), function(i) difference_rows(data, spec[i, ], map))
  out <- as_harmonized(dplyr::bind_rows(out, derived))
  assert_schema(out, harmonized_spec, "harmonized")
  out[order(out$offence_key, out$ags), ]
}

# A key computed as the difference of two published keys. Case-based counts
# are additive; suspects are persons and are not, so they become NA.
difference_rows <- function(data, spec_row, map) {
  plus <- data[data$offence_key == spec_row$plus_key, ]
  minus <- data[data$offence_key == spec_row$minus_key, ]
  minus <- minus[match(plus$ags, minus$ags), ]
  if (anyNA(minus$ags)) {
    cli::cli_abort(tr("{spec_row$year}: key {spec_row$minus_key} is missing for some districts."))
  }
  out <- plus
  for (col in setdiff(harmonized_counts, "suspects")) {
    out[[col]] <- plus[[col]] - minus[[col]]
  }
  out$suspects <- NA_real_
  cases <- dplyr::coalesce(out$cases, out$cases_derived)
  cleared <- dplyr::coalesce(out$cleared, out$cleared_derived)
  out$hz <- cases / dplyr::coalesce(out$population, out$derived_population) * 1e5
  out$clearance_rate <- ifelse(cases > 0, cleared / cases * 100, 0)
  out$offence_key <- spec_row$offence_key_harmonized
  out$offence_key_published <- paste(spec_row$plus_key, "minus", spec_row$minus_key)
  out$offence_label <- map$label_de[map$offence_key_harmonized == spec_row$offence_key_harmonized]
  out
}

# Data as published (several years) to the boundary of `target`, then to the
# harmonized offence keys, year by year, with the conservation check.
harmonize_published <- function(published, boundary_map, offence_map, target, weights) {
  map <- effective_boundary_map(boundary_map)
  if (!target %in% boundary_years(map)) {
    cli::cli_abort(c(
      tr("This data release can harmonize to boundary years {min(boundary_years(map))} to {max(boundary_years(map))}, not {target}."),
      "i" = tr("Use {.code harmonize_to = NULL} for the data as published.")
    ))
  }
  later <- unique(published$boundary_year[published$boundary_year > target])
  if (length(later) > 0) {
    cli::cli_abort(c(
      tr("Only forward harmonization is supported: years with boundary {.val {sort(later)}} cannot be moved back to {target}."),
      "i" = tr("Request years up to {target}, or a later {.arg harmonize_to}.")
    ))
  }
  years <- split(published, published$year)
  out <- lapply(years, function(d) {
    spatial <- harmonize_space(d, map, target, weights)
    check_conservation(d, spatial)
    harmonize_offences(spatial, offence_map)
  })
  dplyr::bind_rows(out)
}
