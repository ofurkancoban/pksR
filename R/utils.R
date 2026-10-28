# Small helpers shared by the package functions.

# The GitHub repository whose releases hold the data. An option, so tests and
# forks can point the package at another repository.
data_repo <- function() {
  getOption("pksR.repo", "ofurkancoban/pksR-data")
}

user_agent <- function() {
  sprintf(
    "pksR/%s (R package for German Police Crime Statistics; https://github.com/ofurkancoban/pksR)",
    utils::packageVersion("pksR")
  )
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# Every step that can remove rows says how many it removed and why.
log_rows_removed <- function(n_before, n_after, reason) {
  removed <- n_before - n_after
  if (removed > 0) {
    cli::cli_inform("Removed {removed} row{?s}: {reason}")
  }
  invisible(removed)
}

# Inner join that refuses to lose rows of `x`: every row of `x` must find at
# least one partner in `y`. Several partners are allowed, which a split
# district needs.
join_checked <- function(x, y, by, what) {
  key_x <- if (is.null(names(by))) by else ifelse(names(by) == "", by, names(by))
  out <- dplyr::inner_join(x, y, by = by, relationship = "many-to-many")
  matched <- dplyr::semi_join(x, y, by = by)
  if (nrow(matched) != nrow(x)) {
    lost <- dplyr::anti_join(x, y, by = by)
    cli::cli_abort("Join of {what} loses {nrow(lost)} row{?s}; unmatched {.val {unique(do.call(paste, lost[key_x]))}}")
  }
  out
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256")
}

# Year ranges in registries: "2003-2007" or "2008-2009,2013".
parse_years <- function(x) {
  parts <- strsplit(x, ",", fixed = TRUE)[[1]]
  unlist(lapply(parts, function(p) {
    b <- as.integer(strsplit(p, "-", fixed = TRUE)[[1]])
    if (anyNA(b) || !length(b) %in% 1:2) {
      cli::cli_abort("Invalid year range {.val {p}}.")
    }
    seq(b[1], b[length(b)])
  }))
}
