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
#'   German (`"burglary"`, `"wohnungseinbruch"`), a full label
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
#'   Columns are described in `vignette("pksR")`. Attributes:
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
#'   Englisch (`"wohnungseinbruch"`, `"burglary"`), vollständige Bezeichnung oder
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
#' und `source_urls`.
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

  if (is.null(target)) {
    files <- sprintf("pks_kreis_%d_published.csv.gz", years)
    data <- read_years(version, files, manifest, cache, canonical_spec)
    if (!is.null(keys)) data <- data[published_rows(data, keys, map), ]
    if (lang == "en") data$offence_label <- published_labels_en(data, map)
    weights_used <- NA_character_
    notes <- manifest$notes$published
  } else {
    if (identical(target, as.integer(manifest$target_boundary_year))) {
      files <- sprintf("pks_kreis_%d_%s.csv.gz", years, weights)
      data <- read_years(version, files, manifest, cache, harmonized_spec)
    } else {
      published_files <- sprintf("pks_kreis_%d_published.csv.gz", years)
      published <- read_years(version, published_files, manifest, cache, canonical_spec)
      crosswalk <- release_file(version, "boundary_map.csv", manifest, cache)
      cli::cli_inform(tr("Harmonizing {length(years)} year{?s} to the boundary of {target} with {weights} weights."))
      data <- harmonize_published(published, read_boundary_map(crosswalk), map, target, weights)
      files <- c(published_files, "boundary_map.csv")
    }
    if (!is.null(keys)) data <- data[data$offence_key %in% keys, ]
    data$offence_label <- offence_labels(data$offence_key, map, lang)
    weights_used <- weights
    notes <- manifest$notes$harmonized
  }
  files <- c(files, "offence_map.csv")

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
