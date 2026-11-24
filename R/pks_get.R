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
#' @param offence Offences to return, or `NULL` (default) for all. Each
#'   element can be an offence key (`"435*00"`), a short name in English or
#'   German (`"residential_burglary"`, `"wohnungseinbruch"`), a full label
#'   (`"Wohnungseinbruchdiebstahl"`) or a part of a label (`"einbruch"`, which
#'   selects both burglary keys). An exact key, name or label wins over a part.
#'   Capitals, spaces and umlauts do not matter. See
#'   [pks_offences()] for all keys and names. For the data as published, the
#'   published keys that feed the selected keys are returned.
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
#' @param lang Language of the offence labels in column `offence_label` and
#'   of the messages: `"de"` or `"en"`. `NULL` (default) uses
#'   `options(pksR.lang)`, otherwise the language of the R session. Harmonized
#'   data get the label of the harmonized key; data as published keep the
#'   published German label, or get the English label of the matching
#'   harmonized key.
#'
#' @return A tibble with one row per year, district (`ags`) and offence key.
#'   Columns are described in `vignette("pksR")`. `region_name` is the name
#'   as published; `region_name_official` is the name of the BBSR crosswalk
#'   at the boundary year of the row, the same for every year of a district
#'   in a harmonized panel. The detail columns `district_type`,
#'   `firearm_threatened`, `firearm_fired`, `suspects_male`, `suspects_female`
#'   and `suspects_non_german` come from separate release files (2026.2 and
#'   later; NA for older releases and for 2003 to 2012). Attributes:
#'   `data_version`, `retrieved_at`, `boundary_year`, `weights` and
#'   `source_urls`.
#' @section Deutsch:
#' Lädt die Kreistabellen der Polizeilichen Kriminalstatistik (PKS) aus einer
#' versionierten Datenveröffentlichung, wie vom Bundeskriminalamt veröffentlicht
#' oder auf einen Gebietsstand und eine Straftatenzuordnung harmonisiert. Jede
#' Datei wird gegen die SHA-256-Prüfsumme des Manifests geprüft und im Cache
#' abgelegt.
#'
#' * `years`: Berichtsjahre, `NULL` für alle.
#' * `offence`: Straftaten als Schlüssel (`"435*00"`), Kurzname auf Deutsch oder
#'   Englisch (`"wohnungseinbruch"`, `"residential_burglary"`), vollständige Bezeichnung oder
#'   Teil einer Bezeichnung (`"einbruch"`). Groß- und Kleinschreibung,
#'   Leerzeichen und Umlaute spielen keine Rolle; eine genaue Übereinstimmung hat
#'   Vorrang. Übersicht: [pks_offences()].
#' * `harmonize_to`: `"latest"` (Gebietsstand der Veröffentlichung), ein Jahr
#'   (Harmonisierung nur vorwärts) oder `NULL` (wie veröffentlicht).
#' * `weights`: Gewichtung geteilter Kreise, `"population"` oder `"area"`.
#' * `version`: Datenversion, etwa `"2026.1"`, oder `"latest"`.
#' * `lang`: Sprache der Bezeichnungen und Meldungen, `"de"` oder `"en"`;
#'   Voreinstellung `options(pksR.lang)`, sonst die Sprache der R-Sitzung.
#'
#' Ergebnis: ein Tibble mit einer Zeile je Jahr, Kreis und Straftatenschlüssel
#' und den Attributen `data_version`, `retrieved_at`, `boundary_year`, `weights`
#' und `source_urls`. `region_name` ist der Name wie veröffentlicht,
#' `region_name_official` der Name des BBSR-Umsteigeschlüssels im Gebietsstand
#' der Zeile. Die Detailspalten (Kreisart, Fälle mit Schusswaffe, Tatverdächtige
#' nach Geschlecht und nichtdeutsche Tatverdächtige) stammen aus eigenen Dateien
#' der Veröffentlichung (ab 2026.2; sonst und für 2003 bis 2012 NA).
#' @family data
#' @export
#' @examplesIf interactive()
#' # Total offences, harmonized to the latest boundary
#' total <- pks_get(offence = "total")
#'
#' # Theft in total and both burglary keys, German labels
#' theft <- pks_get(offence = c("diebstahl", "einbruch"), lang = "de")
#'
#' # As published by the BKA, two years
#' published <- pks_get(years = 2024:2025, harmonize_to = NULL)
pks_get <- function(years = NULL,
                    offence = NULL,
                    harmonize_to = "latest",
                    weights = c("population", "area"),
                    version = "latest",
                    source = c("release", "bka"),
                    cache = TRUE,
                    lang = NULL) {
  # Messages of this call follow `lang`
  lang <- check_lang(lang)
  old_lang <- options(pksR.lang = lang)
  on.exit(options(old_lang), add = TRUE)
  weights <- match.arg(weights)
  source <- match.arg(source)
  if (source == "bka") {
    cli::cli_abort(c(
      tr("{.code source = \"bka\"} is not available yet."),
      "i" = tr("Use {.code source = \"release\"}; the releases are built from the BKA files by pksR-data.")
    ))
  }
  check_years(years)
  if (!is.logical(cache) || length(cache) != 1 || is.na(cache)) {
    cli::cli_abort(tr("{.arg cache} must be {.val TRUE} or {.val FALSE}."))
  }

  version <- resolve_version(version)
  manifest <- read_manifest(version, cache)
  target <- resolve_target(harmonize_to, manifest)
  available <- seq(as.integer(manifest$years[[1]]), as.integer(manifest$years[[2]]))
  years <- years %||% available
  if (length(setdiff(years, available)) > 0) {
    cli::cli_abort(c(
      tr("Data release {.val {version}} has no year{?s} {.val {setdiff(years, available)}}."),
      "i" = tr("Available: {min(available)} to {max(available)}.")
    ))
  }
  years <- sort(unique(as.integer(years)))

  # The offence map of this release: offence names, labels and, for the
  # data as published, which published key feeds which harmonized key
  map_file <- release_file(version, "offence_map.csv", manifest, cache)
  map <- with_aliases(read_offence_map(map_file))
  keys <- if (is.null(offence)) NULL else resolve_offences(offence, map)

  # The crosswalk gives the official name of every district (and the
  # boundaries for harmonize_to other than the latest)
  crosswalk <- release_file(version, "boundary_map.csv", manifest, cache)
  boundary_map <- read_boundary_map(crosswalk)

  # Detail columns (suspects by sex and nationality, firearm cases, district
  # type) come in separate files from release 2026.2 on
  details <- has_details(manifest)

  if (is.null(target)) {
    files <- year_files(years, "published", details)
    data <- read_years(version, years, "published", manifest, cache, canonical_spec, details)
    if (!is.null(keys)) data <- data[published_rows(data, keys, map), ]
    if (lang == "en") data$offence_label <- published_labels_en(data, map)
    weights_used <- NA_character_
    notes <- manifest$notes$published
  } else {
    if (identical(target, as.integer(manifest$target_boundary_year))) {
      files <- year_files(years, weights, details)
      data <- read_years(version, years, weights, manifest, cache, harmonized_spec, details)
    } else {
      files <- year_files(years, "published", details)
      published <- read_years(version, years, "published", manifest, cache, canonical_spec, details)
      cli::cli_inform(tr("Harmonizing {length(years)} year{?s} to the boundary of {target} with {weights} weights."))
      data <- harmonize_published(published, boundary_map, map, target, weights)
    }
    if (!is.null(keys)) data <- data[data$offence_key %in% keys, ]
    data$offence_label <- offence_labels(data$offence_key, map, lang)
    weights_used <- weights
    notes <- manifest$notes$harmonized
  }
  data <- add_official_names(data, boundary_map)
  files <- c(files, "boundary_map.csv", "offence_map.csv")

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
  if (!is.numeric(years) || !length(years) || anyNA(years) || any(years != round(years))) {
    cli::cli_abort(tr("{.arg years} must be whole numbers, such as {.code 2015:2025}."))
  }
}

# NULL for the data as published, otherwise the target boundary year.
resolve_target <- function(harmonize_to, manifest) {
  if (is.null(harmonize_to)) return(NULL)
  if (identical(harmonize_to, "latest")) return(as.integer(manifest$target_boundary_year))
  if (!is.numeric(harmonize_to) || length(harmonize_to) != 1 || is.na(harmonize_to) || harmonize_to != round(harmonize_to)) {
    cli::cli_abort(tr("{.arg harmonize_to} must be a year, {.val latest} or {.code NULL}."))
  }
  as.integer(harmonize_to)
}

# Adds `region_name_official`, the BBSR name of each district at the boundary
# year of its row, after `region_name`. `region_name` stays as published, and
# the yearbooks of 2003 to 2012 spell some names differently from year to
# year; the official name is the same for a district and boundary year.
add_official_names <- function(data, boundary_map) {
  map <- effective_boundary_map(boundary_map)
  years <- intersect(unique(data$boundary_year), boundary_years(map))
  official <- dplyr::bind_rows(lapply(years, function(y) {
    n <- boundary_names(map, y)
    tibble::tibble(ags = n$ags, boundary_year = as.integer(y), region_name_official = n$name)
  }))
  # A left join with unique keys keeps every row and adds none
  out <- dplyr::left_join(data, official, by = c("ags", "boundary_year"))
  if (nrow(out) != nrow(data)) {
    cli::cli_abort(tr("Adding the official district names changed the number of rows."))
  }
  missing <- unique(out$ags[is.na(out$region_name_official)])
  if (length(missing) > 0) {
    cli::cli_warn(tr("No official name in the crosswalk for district{?s} {.val {missing}}."))
  }
  dplyr::relocate(out, "region_name_official", .after = "region_name")
}

# Release files of `years` for one variant ("published" or a weighting):
# the main file of each year and, where the release has them, its details.
year_files <- function(years, variant, details) {
  main <- sprintf("pks_kreis_%d_%s.csv.gz", years, variant)
  if (details) c(main, sprintf("pks_kreis_%d_%s_details.csv.gz", years, variant)) else main
}

has_details <- function(manifest) {
  any(grepl("_details\\.csv\\.gz$", vapply(manifest$files, function(f) f$name, "")))
}

# The years of one variant with the detail columns joined. A release without
# detail files (2026.1) gives the detail columns as NA, once with a message.
read_years <- function(version, years, variant, manifest, cache, spec, details) {
  read <- function(f, s) read_release_csv(release_file(version, f, manifest, cache), s)
  data <- dplyr::bind_rows(lapply(sprintf("pks_kreis_%d_%s.csv.gz", years, variant), read, s = spec))
  if (details) {
    dspec <- details_file_spec(spec)
    extra <- dplyr::bind_rows(lapply(sprintf("pks_kreis_%d_%s_details.csv.gz", years, variant), read, s = dspec))
    data <- join_details(data, extra)
  } else {
    no_details_message(version)
    for (col in names(detail_spec)) data[[col]] <- methods::as(rep(NA, nrow(data)), details_file_spec(spec)[[col]])
  }
  data[order(data$year, data$offence_key, data$ags), ]
}

# Every row of the main file has exactly one detail row: the join neither
# adds nor drops rows, and a row without details stops instead of turning NA.
join_details <- function(data, extra) {
  if (anyDuplicated(extra[detail_key])) {
    cli::cli_abort(tr("The detail files have duplicate rows."))
  }
  out <- dplyr::left_join(data, extra, by = detail_key)
  unmatched <- nrow(dplyr::anti_join(data[detail_key], extra[detail_key], by = detail_key))
  if (nrow(out) != nrow(data) || unmatched > 0 || nrow(extra) != nrow(data)) {
    cli::cli_abort(tr("The detail files do not match the data files row by row."))
  }
  out
}

no_details_message <- function(version) {
  key <- paste0("details:", data_repo(), ":", version)
  if (isTRUE(the[[key]])) return(invisible())
  the[[key]] <- TRUE
  cli::cli_inform(c("i" = tr("Data release {.val {version}} has no detail columns; they are NA.")))
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
  # literally; known notes are translated
  notes <- vapply(unlist(notes), tr, "", USE.NAMES = FALSE)
  notes <- gsub("}", "}}", gsub("{", "{{", notes, fixed = TRUE), fixed = TRUE)
  licence <- manifest$license %||% "see the release"
  cli::cli_inform(c(
    "i" = tr("PKS data release {.val {version}}."),
    stats::setNames(notes, rep("!", length(notes))),
    "i" = tr("Source: PKS Bundeskriminalamt; licence {licence}. Cite with {.fn pks_cite}.")
  ))
}
