#' Get district-level police crime statistics
#'
#' Downloads the district (Kreis) tables of the German Police Crime
#' Statistics (PKS) from a versioned data release, as published by the
#' Bundeskriminalamt or harmonized to one territorial boundary and offence
#' classification. Files are cached and checked against the SHA-256
#' checksums of the release manifest.
#'
#' @param years Integer vector of reporting years, or `NULL` (default) for all
#'   years of the release.
#' @param offence_keys Character vector of offence keys (Straftatenschluessel),
#'   or `NULL` (default) for all. For harmonized data these are the harmonized
#'   keys listed by [pks_offences()]; for the data as published, the keys as
#'   printed in the BKA tables.
#' @param harmonize_to Target boundary year (Gebietsstand). `"latest"`
#'   (default) is the boundary of the release, read as released; another year
#'   harmonizes the data as published with the crosswalk of the release
#'   (forward only, so `years` must not be later than the target); `NULL`
#'   returns the data as published.
#' @param weights Weights for districts that were split: `"population"`
#'   (default) or `"area"`. Ignored for `harmonize_to = NULL`.
#' @param version Data version such as `"2026.1"`, or `"latest"` (default).
#' @param source `"release"` (default) reads a data release. `"bka"`, which
#'   will rebuild the spreadsheet years from the original BKA files, is not
#'   available yet.
#' @param cache Keep downloaded files in the cache (default `TRUE`). With
#'   `FALSE`, files go to a temporary directory and are removed with the R
#'   session.
#'
#' @return A tibble with one row per year, district (`ags`) and offence key.
#'   Columns are described in `vignette("pksR")`. Attributes:
#'   `data_version`, `retrieved_at`, `boundary_year`, `weights` and
#'   `source_urls`.
#' @family data
#' @export
#' @examplesIf interactive()
#' # Total offences, harmonized to the latest boundary
#' total <- pks_get(offence_keys = "------")
#'
#' # As published by the BKA, two years
#' published <- pks_get(years = 2024:2025, harmonize_to = NULL)
pks_get <- function(years = NULL,
                    offence_keys = NULL,
                    harmonize_to = "latest",
                    weights = c("population", "area"),
                    version = "latest",
                    source = c("release", "bka"),
                    cache = TRUE) {
  weights <- match.arg(weights)
  source <- match.arg(source)
  if (source == "bka") {
    cli::cli_abort(c(
      "{.code source = \"bka\"} is not available yet.",
      "i" = "Use {.code source = \"release\"}; the releases are built from the BKA files by pksR-data."
    ))
  }
  check_years(years)
  check_keys(offence_keys)
  if (!is.logical(cache) || length(cache) != 1 || is.na(cache)) {
    cli::cli_abort("{.arg cache} must be {.val TRUE} or {.val FALSE}.")
  }

  version <- resolve_version(version)
  manifest <- read_manifest(version, cache)
  target <- resolve_target(harmonize_to, manifest)
  available <- seq(as.integer(manifest$years[[1]]), as.integer(manifest$years[[2]]))
  years <- years %||% available
  if (length(setdiff(years, available)) > 0) {
    cli::cli_abort(c(
      "Data release {.val {version}} has no year{?s} {.val {setdiff(years, available)}}.",
      "i" = "Available: {min(available)} to {max(available)}."
    ))
  }
  years <- sort(unique(as.integer(years)))

  if (is.null(target)) {
    files <- sprintf("pks_kreis_%d_published.csv.gz", years)
    data <- read_years(version, files, manifest, cache, canonical_spec)
    weights_used <- NA_character_
    notes <- manifest$notes$published
  } else if (identical(target, as.integer(manifest$target_boundary_year))) {
    files <- sprintf("pks_kreis_%d_%s.csv.gz", years, weights)
    data <- read_years(version, files, manifest, cache, harmonized_spec)
    weights_used <- weights
    notes <- manifest$notes$harmonized
  } else {
    published_files <- sprintf("pks_kreis_%d_published.csv.gz", years)
    published <- read_years(version, published_files, manifest, cache, canonical_spec)
    maps <- c("boundary_map.csv", "offence_map.csv")
    paths <- vapply(maps, function(f) release_file(version, f, manifest, cache), "")
    cli::cli_inform("Harmonizing {length(years)} year{?s} to the boundary of {target} with {weights} weights.")
    data <- harmonize_published(published, read_boundary_map(paths[[1]]), read_offence_map(paths[[2]]), target, weights)
    files <- c(published_files, maps)
    weights_used <- weights
    notes <- manifest$notes$harmonized
  }

  if (!is.null(offence_keys)) {
    unknown <- setdiff(offence_keys, data$offence_key)
    if (length(unknown) > 0) {
      cli::cli_warn("Offence key{?s} {.val {unknown}} not in the requested data; see {.fn pks_offences}.")
    }
    data <- data[data$offence_key %in% offence_keys, ]
  }

  show_notes(version, notes, manifest)
  attr(data, "data_version") <- version
  attr(data, "retrieved_at") <- retrieved_at(version, files, cache)
  attr(data, "boundary_year") <- if (is.null(target)) NA_integer_ else target
  attr(data, "weights") <- weights_used
  attr(data, "source_urls") <- asset_url(version, files)
  data
}

check_years <- function(years) {
  if (is.null(years)) return(invisible())
  if (!is.numeric(years) || anyNA(years) || any(years != round(years))) {
    cli::cli_abort("{.arg years} must be whole numbers, such as {.code 2015:2025}.")
  }
}

check_keys <- function(keys) {
  if (is.null(keys)) return(invisible())
  if (!is.character(keys) || anyNA(keys)) {
    cli::cli_abort("{.arg offence_keys} must be a character vector, such as {.code c(\"------\", \"435*00\")}.")
  }
}

# NULL for the data as published, otherwise the target boundary year.
resolve_target <- function(harmonize_to, manifest) {
  if (is.null(harmonize_to)) return(NULL)
  if (identical(harmonize_to, "latest")) return(as.integer(manifest$target_boundary_year))
  if (!is.numeric(harmonize_to) || length(harmonize_to) != 1 || is.na(harmonize_to) || harmonize_to != round(harmonize_to)) {
    cli::cli_abort("{.arg harmonize_to} must be a year, {.val latest} or {.code NULL}.")
  }
  as.integer(harmonize_to)
}

read_years <- function(version, files, manifest, cache, spec) {
  paths <- vapply(files, function(f) release_file(version, f, manifest, cache), "")
  data <- dplyr::bind_rows(lapply(paths, read_release_csv, spec = spec))
  data[order(data$year, data$offence_key, data$ags), ]
}

# When the files were downloaded: the oldest file of the request.
retrieved_at <- function(version, files, cache) {
  dir <- if (cache) cache_dir(version, create = FALSE) else tempdir()
  times <- file.info(file.path(dir, files))$mtime
  if (all(is.na(times))) return(as.POSIXct(NA))
  min(times, na.rm = TRUE)
}

# Data notes of the release and the source note, once per session and
# version.
show_notes <- function(version, notes, manifest) {
  key <- paste0("notes:", data_repo(), ":", version)
  if (isTRUE(the[[key]])) return(invisible())
  the[[key]] <- TRUE
  # Note texts come from the release: braces are escaped so cli prints them
  # literally
  notes <- gsub("}", "}}", gsub("{", "{{", unlist(notes), fixed = TRUE), fixed = TRUE)
  licence <- manifest$license %||% "see the release"
  cli::cli_inform(c(
    "i" = "PKS data release {.val {version}}.",
    stats::setNames(notes, rep("!", length(notes))),
    "i" = "Source: PKS Bundeskriminalamt; licence {licence}. Cite with {.fn pks_cite}."
  ))
}
