# Data releases: listing, manifests and verified downloads.
#
# A data release is a GitHub release "v<year>.<n>" of pksR-data (drafts and
# prereleases are dry runs and never used). Its manifest.json lists every
# file with SHA-256, size and rows; each download is checked against it
# (brief Section 8, requirement 2).

release_tag_pattern <- "^v([0-9]{4}\\.[0-9]+)$"

github_request <- function(url, token = github_token()) {
  req <- httr2::request(url) |>
    httr2::req_user_agent(user_agent()) |>
    httr2::req_headers(Accept = "application/vnd.github+json") |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_timeout(60) |>
    httr2::req_error(body = github_error_hint)
  # A token raises GitHub's limit of 60 unauthenticated requests per hour
  if (nzchar(token)) req <- httr2::req_auth_bearer_token(req, token)
  req
}

github_token <- function() {
  Sys.getenv("GITHUB_PAT", Sys.getenv("GITHUB_TOKEN"))
}

# What the user can do about an HTTP error from GitHub, added to the error
# message (NULL when there is nothing to add)
github_error_hint <- function(resp) {
  status <- httr2::resp_status(resp)
  if (status == 401) {
    return(tr("GitHub rejected the token in GITHUB_PAT or GITHUB_TOKEN. Data releases are public and need no token: renew or unset it."))
  }
  limited <- identical(httr2::resp_header(resp, "x-ratelimit-remaining"), "0")
  if (status %in% c(403, 429) && limited) {
    if (nzchar(github_token())) return(tr("GitHub's rate limit for your token is reached; try again later."))
    return(tr("GitHub's limit of 60 requests per hour without a token is reached. Try again later, or set GITHUB_PAT to a GitHub token."))
  }
  NULL
}

# GET a GitHub API url as parsed JSON. A token GitHub rejects (expired or
# revoked, HTTP 401) would block public data that needs no token, so the
# request is repeated without it.
github_json <- function(url) {
  resp <- tryCatch(
    httr2::req_perform(github_request(url)),
    httr2_http_401 = function(e) {
      if (!nzchar(github_token())) stop(e)
      cli::cli_warn(tr("GitHub rejected the token in GITHUB_PAT or GITHUB_TOKEN; continuing without it."))
      httr2::req_perform(github_request(url, token = ""))
    }
  )
  httr2::resp_body_json(resp)
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
    batch <- github_json(url)
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
    url = vapply(keep, function(r) r$html_url, ""),
    doi = vapply(keep, function(r) release_notes_doi(r$body), "")
  )
  index <- index[order(numeric_version(index$version), decreasing = TRUE), ]
  the[[key]] <- index
  index
}

# Zenodo DOI from the line "DOI: <doi>" that pksR-data appends to the release
# notes once Zenodo has archived the release (NA until then).
release_notes_doi <- function(body) {
  body <- body %||% ""
  m <- regmatches(body, regexec("(?m)^DOI: (10\\.\\S+)\\s*$", body, perl = TRUE))[[1]]
  if (length(m) == 2) m[2] else NA_character_
}

# Session state (release index, notes already shown).
the <- new.env(parent = emptyenv())

#' List the available data releases
#'
#' Data releases are versioned and never change; a correction is published as
#' a new version. Versions are named `<year>.<n>`, for example `"2026.1"`.
#'
#' @return A tibble with one row per data release, newest first: `version`,
#'   `tag`, `published_at`, `files`, `url` and `doi` (Zenodo DOI of the
#'   version, `NA` until Zenodo has archived it).
#' @section Deutsch:
#' Listet die veröffentlichten Datenversionen, die neueste zuerst. Eine
#' Veröffentlichung ändert sich nie; Korrekturen erscheinen als neue Version.
#' Die Spalte `doi` enthält die Zenodo-DOI der Version.
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
    cli::cli_abort(
      tr("Cannot reach GitHub to list the data releases, and version {.val {version}} is not cached."),
      parent = index
    )
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
  m <- read_manifest_file(path)
  if (is.null(m)) {
    # A damaged copy in the cache (the release itself never changes): fetch
    # it once more instead of failing until the user clears the cache
    unlink(path)
    download(asset_url(version, "manifest.json"), path)
    m <- read_manifest_file(path)
    if (is.null(m)) {
      unlink(path)
      cli::cli_abort(tr("The manifest of {.val {version}} cannot be read."))
    }
  }
  if (!identical(m$data_version, version)) {
    unlink(path)
    cli::cli_abort(tr("The manifest of {.val {version}} names version {.val {m$data_version}}."))
  }
  m
}

# The manifest at `path`, or NULL unless it parses and names a version, the
# years and the files.
read_manifest_file <- function(path) {
  m <- tryCatch(jsonlite::read_json(path), error = function(e) NULL)
  ok <- is.list(m) && is.character(m$data_version) && length(m$years) == 2 && length(m$files) > 0
  if (ok) m else NULL
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
# never leaves a partial file in the cache. The temporary name is unique, so
# R sessions filling the same cache at once never touch each other's file;
# the last rename wins, and every session writes the same content.
download <- function(url, path) {
  tmp <- tempfile(paste0(basename(path), "."), tmpdir = dirname(path), fileext = ".part")
  on.exit(unlink(tmp), add = TRUE)
  resp <- tryCatch(
    httr2::req_perform(github_request(url), path = tmp),
    error = function(e) {
      cli::cli_abort(tr("Download of {.url {url}} failed."), parent = e, call = NULL)
    }
  )
  # A mocked response (tests) keeps its body in memory instead of `tmp`
  if (!file.exists(tmp)) writeBin(httr2::resp_body_raw(resp), tmp)
  # On Windows the rename fails while another session reads `path`; that
  # session's copy is then used and checked against the manifest as usual
  if (!suppressWarnings(file.rename(tmp, path)) && !file.exists(path)) {
    cli::cli_abort(tr("Cannot write {.file {path}}."))
  }
  invisible(path)
}
