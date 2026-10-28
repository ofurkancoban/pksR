# Local cache of release files (brief Section 8, requirement 1): only below
# tools::R_user_dir("pksR", "cache"), one folder per data version. Releases
# never change, so a cached file stays valid as long as its SHA-256 matches
# the manifest.

cache_root <- function() {
  tools::R_user_dir("pksR", "cache")
}

cache_dir <- function(version, create = TRUE) {
  dir <- file.path(cache_root(), version)
  if (create && !dir.exists(dir)) dir.create(dir, recursive = TRUE)
  dir
}

#' Inspect the local cache
#'
#' Lists the release files that [pks_get()] and [pks_manifest()] have stored
#' in the cache directory, `tools::R_user_dir("pksR", "cache")`.
#'
#' @return A tibble with one row per cached file: `version`, `file`, `bytes`
#'   and `modified`. The cache directory is attached as attribute `path`.
#' @family cache
#' @export
#' @examples
#' pks_cache_info()
pks_cache_info <- function() {
  root <- cache_root()
  files <- if (dir.exists(root)) list.files(root, recursive = TRUE, full.names = TRUE) else character(0)
  info <- file.info(files)
  out <- tibble::tibble(
    version = basename(dirname(files)),
    file = basename(files),
    bytes = as.numeric(info$size),
    modified = info$mtime
  )
  out <- out[order(out$version, out$file), ]
  cli::cli_inform(c(
    "i" = tr("Cache: {.path {root}}"),
    "i" = tr("{nrow(out)} file{?s}, {format_bytes(sum(out$bytes))} in {length(unique(out$version))} data version{?s}.")
  ))
  attr(out, "path") <- root
  out
}

#' Clear the local cache
#'
#' Deletes cached release files, for all data versions or only for the ones
#' given. The files are downloaded again when they are next needed.
#'
#' @param version Character vector of data versions to remove, such as
#'   `"2026.1"`, or `NULL` (default) for the whole cache.
#' @param ask Ask for confirmation before deleting. Defaults to `TRUE` in
#'   interactive sessions.
#' @return The removed files as a tibble like [pks_cache_info()], invisibly.
#' @family cache
#' @export
#' @examples
#' \donttest{
#' pks_cache_clear(ask = FALSE)
#' }
pks_cache_clear <- function(version = NULL, ask = interactive()) {
  info <- suppressMessages(pks_cache_info())
  if (!is.null(version)) info <- info[info$version %in% version, ]
  if (nrow(info) == 0) {
    cli::cli_inform(tr("Nothing to remove from the cache."))
    return(invisible(info))
  }
  if (ask) {
    answer <- ask_yes_no(sprintf(tr("Delete %d cached file(s), %s?"), nrow(info), format_bytes(sum(info$bytes))))
    if (!isTRUE(answer)) {
      cli::cli_inform(tr("Cache left unchanged."))
      return(invisible(info[0, ]))
    }
  }
  dirs <- file.path(cache_root(), unique(info$version))
  unlink(file.path(cache_root(), info$version, info$file))
  for (d in dirs) if (length(list.files(d)) == 0) unlink(d, recursive = TRUE)
  cli::cli_inform(tr("Removed {nrow(info)} file{?s} from the cache."))
  invisible(info)
}

format_bytes <- function(x) {
  units <- c("B", "KB", "MB", "GB")
  i <- if (x > 0) min(length(units), floor(log(x, 1024)) + 1) else 1
  sprintf(if (i == 1) "%.0f %s" else "%.1f %s", x / 1024^(i - 1), units[i])
}

# A wrapper, so tests can answer the question
ask_yes_no <- function(question) utils::askYesNo(question)
