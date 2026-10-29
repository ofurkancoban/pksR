#' A small example panel
#'
#' A subset of the harmonized panel of pksR-data that ships with the package, for
#' examples, tests and vignettes without internet access: five districts,
#' two offence keys and the years 2019 to 2025, harmonized to the 2025
#' boundary with population weights, built from pksR-data commit 9b6985d
#' (`data-raw/example.R`), not from a data release, so `data_version` is
#' `"example"`. Source: PKS Bundeskriminalamt,
#' Datenlizenz Deutschland, Namensnennung, Version 2.0; changed (harmonized)
#' by pksR-data.
#'
#' @return A tibble in the format of [pks_get()].
#' @section Deutsch:
#' Ein kleines Beispielpanel, das mit dem Paket ausgeliefert wird: fünf
#' Kreise, zwei Straftatenschlüssel und die Jahre 2019 bis 2025, harmonisiert
#' auf den Gebietsstand 2025. Es stammt aus einem lokalen Lauf von pksR-data,
#' nicht aus einer Datenveröffentlichung (`data_version = "example"`). Quelle:
#' PKS Bundeskriminalamt, Datenlizenz Deutschland, Namensnennung, Version 2.0;
#' verändert (harmonisiert).
#' @family data
#' @export
#' @examples
#' pks_example()
pks_example <- function() {
  path <- system.file("extdata", "pks_example.csv", package = "pksR")
  d <- read_release_csv(path, harmonized_spec)
  attr(d, "data_version") <- example_info$data_version
  attr(d, "retrieved_at") <- as.POSIXct(example_info$retrieved_at, tz = "UTC")
  attr(d, "boundary_year") <- example_info$boundary_year
  attr(d, "weights") <- "population"
  attr(d, "source_urls") <- character(0)
  d
}

# Built from pksR-data commit 9b6985d on 2026-10-29 (data-raw/example.R)
example_info <- list(data_version = "example", retrieved_at = "2026-10-29 00:00:00", boundary_year = 2025L)
