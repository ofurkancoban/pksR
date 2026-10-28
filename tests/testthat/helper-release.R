# A fake GitHub for the offline tests: the release listing and the files of
# the fixture release v2026.1 (fixtures/release, built by
# data-raw/test-fixtures.R). The listing also holds a draft, a test
# prerelease and the raw mirror, which must all be ignored.
fixture_dir <- function() test_path("fixtures", "release")

fake_listing <- function(repo) {
  release <- function(tag, draft = FALSE, prerelease = FALSE) {
    list(tag_name = tag, draft = draft, prerelease = prerelease,
         published_at = if (draft) NULL else "2026-10-28T12:00:00Z",
         html_url = sprintf("https://github.com/%s/releases/tag/%s", repo, tag),
         assets = list())
  }
  list(release("test-2026.2-run10", draft = TRUE, prerelease = TRUE), release("raw-mirror", draft = TRUE),
       release("v2026.1"), release("v2025.1"))
}

fake_body <- function(name) {
  if (name == "boundary_map.csv") {
    return(memDecompress(readBin(file.path(fixture_dir(), "boundary_map.csv.gz"), "raw", 2e7), "gzip"))
  }
  path <- file.path(fixture_dir(), name)
  if (!file.exists(path)) return(NULL)
  readBin(path, "raw", file.size(path))
}

# Sets up the fake repository, an empty cache in a temporary directory and a
# fresh session state for the calling test. `offline = TRUE` makes every
# request fail as without a connection. Returns an environment whose
# `requests` lists the URLs asked for.
local_fake_release <- function(offline = FALSE, corrupt = NULL, env = parent.frame()) {
  repo <- "test/pksR-data"
  withr::local_options(pksR.repo = repo, .local_envir = env)
  withr::local_envvar(R_USER_CACHE_DIR = withr::local_tempdir(.local_envir = env), GITHUB_PAT = "", GITHUB_TOKEN = "", .local_envir = env)
  rm(list = ls(pksR:::the), envir = pksR:::the)
  log <- new.env()
  log$requests <- character(0)
  httr2::local_mocked_responses(function(req) {
    log$requests <- c(log$requests, req$url)
    if (offline) stop("Could not resolve host (offline test)")
    if (startsWith(req$url, sprintf("https://api.github.com/repos/%s/releases", repo))) {
      return(httr2::response_json(body = fake_listing(repo)))
    }
    prefix <- sprintf("https://github.com/%s/releases/download/v2026.1/", repo)
    if (startsWith(req$url, prefix)) {
      name <- substring(req$url, nchar(prefix) + 1)
      body <- fake_body(name)
      if (!is.null(body)) {
        if (identical(name, corrupt)) body[length(body)] <- as.raw((as.integer(body[length(body)]) + 1) %% 256)
        return(httr2::response(200, body = body))
      }
    }
    httr2::response(404)
  }, env = env)
  log
}
