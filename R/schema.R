# Column schemas of the release files. They mirror R/schema.R in pksR-data
# (brief Section 5.2); a release whose files deviate is refused rather than
# read with guessed types.

canonical_spec <- c(
  year = "integer",
  ags = "character",
  region_name = "character",
  offence_key = "character",
  offence_label = "character",
  cases = "integer",
  attempts = "integer",
  hz = "double",
  cleared = "integer",
  clearance_rate = "double",
  suspects = "integer",
  cases_derived = "double",
  cleared_derived = "double",
  population = "double",
  source_format = "character",
  source_file = "character",
  boundary_year = "integer",
  harmonized = "logical",
  weight_type = "character",
  estimated = "logical",
  derived_population = "double",
  population_corrected = "double"
)

count_columns <- c("cases", "attempts", "cleared", "suspects")

# Detail columns of the spreadsheet years (2013 onward), in separate files
# *_details.csv.gz from release 2026.2 on; NA in the PDF years. They are
# kept out of the main files because pksR 0.1.0 refuses unknown columns.
detail_spec <- c(
  district_type = "character",
  firearm_threatened = "integer",
  firearm_fired = "integer",
  suspects_male = "integer",
  suspects_female = "integer",
  suspects_non_german = "integer"
)
detail_key <- c("year", "ags", "offence_key")
detail_counts <- setdiff(names(detail_spec), "district_type")

# Suspects are persons and cannot be subtracted between offence keys.
person_counts <- c("suspects", "suspects_male", "suspects_female", "suspects_non_german")

# Everything that is moved with crosswalk weights during harmonization.
harmonized_counts <- c(count_columns, "cases_derived", "cleared_derived", detail_counts)

# Harmonized panel: offence_key is the harmonized key and the published key
# moves to offence_key_published. Counts are double, because splitting a
# district yields fractional cases; rounding would break the national totals.
harmonized_spec <- local({
  spec <- canonical_spec
  spec[count_columns] <- "double"
  at <- match("offence_key", names(spec))
  c(spec[seq_len(at)], offence_key_published = "character", spec[-seq_len(at)])
})

# Columns of a detail file: the row key and the detail columns, with counts
# as double in the harmonized files (weights give fractions).
details_file_spec <- function(spec) {
  d <- detail_spec
  if (identical(spec[["cases"]], "double")) d[detail_counts] <- "double"
  c(spec[detail_key], d)
}

# Columns returned by pks_get(): the release schema plus the detail columns.
full_spec <- function(spec) c(spec, details_file_spec(spec)[names(detail_spec)])

# All columns of pks_get() in their order: the official name after the
# published name, the detail columns at the end.
returned_spec <- function(spec) {
  full <- full_spec(spec)
  at <- match("region_name", names(full))
  c(full[seq_len(at)], region_name_official = "character", full[-seq_len(at)])
}

# Detail columns as typed NA where data lack them (an older release, or data
# built outside pks_get()), so harmonization always finds them.
with_detail_columns <- function(data) {
  types <- details_file_spec(c(year = "integer", ags = "character", offence_key = "character",
                               cases = if (is.double(data$cases)) "double" else "integer"))
  for (col in setdiff(names(detail_spec), names(data))) {
    data[[col]] <- methods::as(rep(NA, nrow(data)), types[[col]])
  }
  data
}

readr_types <- function(spec) {
  codes <- c(integer = "i", double = "d", character = "c", logical = "l")
  types <- stats::setNames(as.list(unname(codes[spec])), names(spec))
  do.call(readr::cols, c(types, list(.default = readr::col_skip())))
}

# Read one release CSV with the types of `spec`. Missing or extra columns are
# an error: silently carrying them would hide drift between releases.
read_release_csv <- function(path, spec) {
  header <- names(readr::read_csv(path, n_max = 0, col_types = readr::cols(.default = "c"), progress = FALSE))
  if (!identical(sort(header), sort(names(spec)))) {
    cli::cli_abort(c(
      tr("{.file {basename(path)}} does not have the expected columns."),
      "i" = tr("Missing: {.val {setdiff(names(spec), header)}}; unexpected: {.val {setdiff(header, names(spec))}}"),
      "i" = tr("A newer pksR version may be needed for this data release.")
    ))
  }
  # The pipeline writes NA as an empty field (readr::write_csv(na = ""))
  d <- readr::read_csv(path, col_types = readr_types(spec), na = "", progress = FALSE)
  tibble::as_tibble(d[names(spec)])
}

assert_schema <- function(data, spec, what) {
  if (!identical(names(data), names(spec))) {
    cli::cli_abort(tr("Columns differ from the {what} schema."))
  }
  types <- vapply(data, typeof, character(1))
  bad <- names(types)[types != spec[names(types)]]
  if (length(bad) > 0) {
    cli::cli_abort(tr("Wrong column types in the {what} schema: {.val {bad}}"))
  }
  invisible(data)
}

as_harmonized <- function(data) {
  spec <- full_spec(harmonized_spec)
  for (col in setdiff(names(spec), names(data))) {
    data[[col]] <- methods::as(rep(NA, nrow(data)), spec[[col]])
  }
  for (col in names(spec)) {
    data[[col]] <- methods::as(data[[col]], spec[[col]])
  }
  tibble::as_tibble(data[names(spec)])
}
