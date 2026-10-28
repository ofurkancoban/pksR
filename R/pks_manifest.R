# Data releases: listing, manifests and verified downloads.
#
# A data release is a GitHub release "v<year>.<n>" of pksR-data (drafts and
# prereleases are dry runs and never used). Its manifest.json lists every
# file with SHA-256, size and rows; each download is checked against it
# (brief Section 8, requirement 2).

release_tag_pattern <- "^v([0-9]{4}\\.[0-9]+)$"

github_request <- function(url) {
  req <- httr2::request(url) |>
    httr2::req_user_agent(user_agent()) |>
    httr2::req_headers(Accept = "application/vnd.github+json") |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_timeout(60)
  # A token raises GitHub's limit of 60 unauthenticated requests per hour
  token <- Sys.getenv("GITHUB_PAT", Sys.getenv("GITHUB_TOKEN"))
  if (nzchar(token)) req <- httr2::req_auth_bearer_token(req, token)
  req
}

# Published data releases, newest first. Kept for the session, because the
# listing costs requests against the GitHub rate limit.
release_index <- function(refresh = FALSE) {
  key <- paste0("releases:", data_repo())
  if (!refresh && !is.null(the[[key]])) return(the[[key]])
  out <- list()
  page <- 1
  repeat {
    url <- sprintf("https://api.github.com/repos/%s/releases?per_page=100&page=%d", data_repo(), page)
    batch <- httr2::resp_body_json(httr2::req_perform(github_request(url)))
    out <- c(out, batch)
    if (length(batch) < 100) break
    page <- page + 1
  }
  keep <- Filter(function(r) grepl(release_tag_pattern, r$tag_name) && !isTRUE(r$draft) && !isTRUE(r$prerelease), out)
  index <- tibble::tibble(
    version = sub(release_tag_pattern, "\\1", vapply(keep, function(r) r$tag_name, "")),
    tag = vapply(keep, function(r) r$tag_name, ""),
    published_at = as.POSIXct(vapply(keep, function(r) r$published_at %||% NA_character_, ""), format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    files = vapply(keep, function(r) length(r$assets), 1L),
    url = vapply(keep, function(r) r$html_url, "")
  )
  index <- index[order(numeric_version(index$version), decreasing = TRUE), ]
  the[[key]] <- index
  index
}

# Session state (release index, notes already shown).
the <- new.env(parent = emptyenv())

#' List the available data releases
#'
#' Data releases are versioned and never change; a correction is published as
#' a new version. Versions are named `<year>.<n>`, for example `"2026.1"`.
#'
#' @return A tibble with one row per data release, newest first: `version`,
#'   `tag`, `published_at`, `files` and `url`.
#' @section Deutsch:
#' Listet die veröffentlichten Datenversionen, die neueste zuerst. Eine
#' Veröffentlichung ändert sich nie; Korrekturen erscheinen als neue Version.
#' @family releases
#' @export
#' @examplesIf interactive()
#' pks_versions()
pks_versions <- function() {
  release_index(refresh = TRUE)
}

# The data version `version` stands for. Without internet, "latest" falls
# back to the newest version in the cache.
resolve_version <- function(version = "latest") {
  if (!is.character(version) || length(version) != 1 || is.na(version)) {
    cli::cli_abort(tr("{.arg version} must be one string, such as {.val latest} or {.val 2026.1}."))
  }
  version <- sub("^v", "", version)
  index <- tryCatch(release_index(), error = function(e) e)
  if (inherits(index, "error")) {
    cached <- cached_versions()
    if (version == "latest" && length(cached)) {
      cli::cli_warn(c(tr("Cannot list the data releases; using the newest cached version {.val {cached[1]}}."), "i" = conditionMessage(index)))
      return(cached[1])
    }
    if (version %in% cached) return(version)
    cli::cli_abort(c(
      tr("Cannot reach GitHub to list the data releases, and version {.val {version}} is not cached."),
      "i" = conditionMessage(index)
    ), parent = index)
  }
  if (nrow(index) == 0) cli::cli_abort(tr("{.val {data_repo()}} has no published data release yet."))
  if (version == "latest") return(index$version[1])
  if (!version %in% index$version) {
    cli::cli_abort(c(tr("Data version {.val {version}} does not exist."), "i" = tr("Available: {.val {index$version}}")))
  }
  version
}

cached_versions <- function() {
  root <- cache_root()
  if (!dir.exists(root)) return(character(0))
  v <- list.dirs(root, full.names = FALSE, recursive = FALSE)
  v <- v[grepl("^[0-9]{4}\\.[0-9]+$", v) & file.exists(file.path(root, v, "manifest.json"))]
  v[order(numeric_version(v), decreasing = TRUE)]
}

asset_url <- function(version, name) {
  sprintf("https://github.com/%s/releases/download/v%s/%s", data_repo(), version, name)
}

# The manifest of `version` as a list; downloaded once and then read from the
# cache (a release never changes).
read_manifest <- function(version, cache = TRUE) {
  dir <- if (cache) cache_dir(version) else tempdir()
  path <- file.path(dir, if (cache) "manifest.json" else paste0("manifest-", version, ".json"))
  if (!file.exists(path)) {
    download(asset_url(version, "manifest.json"), path)
  }
  m <- jsonlite::read_json(path)
  if (!identical(m$data_version, version)) {
    unlink(path)
    cli::cli_abort(tr("The manifest of {.val {version}} names version {.val {m$data_version}}."))
  }
  m
}

#' Read the manifest of a data release
#'
#' The manifest describes one data release: when and from which pipeline
#' commit it was built, the years and target boundary year it covers, the
#' validation result, and every file with its SHA-256, size and number of
#' rows.
#'
#' @param version Data version such as `"2026.1"`, or `"latest"`.
#' @return A tibble with one row per release file (`name`, `sha256`, `bytes`,
#'   `rows`). The other manifest fields (`data_version`, `created_at`,
#'   `pipeline_commit`, `target_boundary_year`, `years`, `validation`,
#'   `notes`, `license`, `attribution`, ...) are attached as attribute
#'   `manifest`.
#' @section Deutsch:
#' Liest das Manifest einer Datenveröffentlichung: wann und mit welchem
#' Stand der Pipeline sie erstellt wurde, welche Jahre und welchen Gebietsstand
#' sie abdeckt, das Ergebnis der Prüfung und jede Datei mit Prüfsumme, Größe und
#' Zeilenzahl. Ergebnis: ein Tibble der Dateien, die übrigen Angaben im Attribut
#' `manifest`.
#' @family releases
#' @export
#' @examplesIf interactive()
#' m <- pks_manifest()
#' attr(m, "manifest")$target_boundary_year
pks_manifest <- function(version = "latest") {
  version <- resolve_version(version)
  m <- read_manifest(version)
  files <- tibble::tibble(
    name = vapply(m$files, function(f) f$name, ""),
    sha256 = vapply(m$files, function(f) f$sha256, ""),
    bytes = vapply(m$files, function(f) as.numeric(f$bytes), 1),
    rows = vapply(m$files, function(f) as.numeric(f$rows %||% NA), 1)
  )
  m$files <- NULL
  attr(files, "manifest") <- m
  files
}

# Path of release file `name` of `version`, downloaded if needed and checked
# against the manifest. A cached file with another hash is downloaded again.
release_file <- function(version, name, manifest, cache = TRUE) {
  entry <- Filter(function(f) identical(f$name, name), manifest$files)
  if (length(entry) != 1) {
    cli::cli_abort(tr("Data release {.val {version}} has no file {.file {name}}."))
  }
  expected <- entry[[1]]$sha256
  path <- file.path(if (cache) cache_dir(version) else tempdir(), name)
  if (file.exists(path) && identical(sha256_file(path), expected)) return(path)
  download(asset_url(version, name), path)
  actual <- sha256_file(path)
  if (!identical(actual, expected)) {
    unlink(path)
    cli::cli_abort(c(
      tr("{.file {name}} of data release {.val {version}} fails its checksum."),
      "i" = tr("Manifest: {expected}"),
      "i" = tr("Download: {actual}")
    ))
  }
  path
}

# Download `url` to `path` via a temporary file, so an interrupted transfer
# never leaves a partial file in the cache.
download <- function(url, path) {
  tmp <- paste0(path, ".part")
  on.exit(unlink(tmp), add = TRUE)
  resp <- tryCatch(
    httr2::req_perform(github_request(url), path = tmp),
    error = function(e) {
      cli::cli_abort(c(tr("Download of {.url {url}} failed."), "i" = conditionMessage(e)), parent = e, call = NULL)
    }
  )
  # A mocked response (tests) keeps its body in memory instead of `tmp`
  if (!file.exists(tmp)) writeBin(httr2::resp_body_raw(resp), tmp)
  file.rename(tmp, path)
  invisible(path)
}
