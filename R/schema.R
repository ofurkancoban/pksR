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
  derived_population = "double"
)

count_columns <- c("cases", "attempts", "cleared", "suspects")

# Everything that is moved with crosswalk weights during harmonization.
harmonized_counts <- c(count_columns, "cases_derived", "cleared_derived")

# Harmonized panel: offence_key is the harmonized key and the published key
# moves to offence_key_published. Counts are double, because splitting a
# district yields fractional cases; rounding would break the national totals.
harmonized_spec <- local({
  spec <- canonical_spec
  spec[count_columns] <- "double"
  at <- match("offence_key", names(spec))
  c(spec[seq_len(at)], offence_key_published = "character", spec[-seq_len(at)])
})

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
  for (col in setdiff(names(harmonized_spec), names(data))) {
    data[[col]] <- methods::as(rep(NA, nrow(data)), harmonized_spec[[col]])
  }
  for (col in names(harmonized_spec)) {
    data[[col]] <- methods::as(data[[col]], harmonized_spec[[col]])
  }
  tibble::as_tibble(data[names(harmonized_spec)])
}
