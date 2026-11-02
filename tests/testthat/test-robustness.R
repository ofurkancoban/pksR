# Regressions found by the stress test before the first CRAN submission
# (notes/decisions.md, 2026-11-02).

test_that("a download leaves the partial file of another session alone", {
  # Several sessions filling one cache used the same "<file>.part": one
  # session renamed it away while another was still writing it
  dir <- withr::local_tempdir()
  path <- file.path(dir, "x.csv.gz")
  foreign <- paste0(path, ".part")
  httr2::local_mocked_responses(function(req) {
    writeLines("another session", foreign)
    httr2::response(200, body = charToRaw("content\n"))
  })
  pksR:::download("https://example.org/x.csv.gz", path)
  expect_identical(readLines(path), "content")
  expect_identical(readLines(foreign), "another session")
})

test_that("partial downloads are neither listed nor kept by pks_cache_clear()", {
  local_fake_release()
  pks_get(years = 2021, offence = "------")
  dir <- file.path(Sys.getenv("R_USER_CACHE_DIR"), "R", "pksR", "2026.1")
  writeLines("half", file.path(dir, "pks_kreis_2021_area.csv.gz.abc.part"))
  info <- suppressMessages(pks_cache_info())
  expect_false(any(endsWith(info$file, ".part")))
  suppressMessages(pks_cache_clear(ask = FALSE))
  expect_false(dir.exists(dir))
})

test_that("a damaged manifest in the cache is downloaded again", {
  log <- local_fake_release()
  pks_manifest()
  path <- file.path(Sys.getenv("R_USER_CACHE_DIR"), "R", "pksR", "2026.1", "manifest.json")
  for (damaged in c("{\"data_version\": \"2026.1\", \"files\": [", "{\"data_version\": \"2026.1\", \"files\": []}")) {
    writeLines(damaged, path)
    n <- sum(endsWith(log$requests, "manifest.json"))
    m <- pks_manifest()
    expect_identical(attr(m, "manifest")$data_version, "2026.1")
    expect_gt(nrow(m), 0)
    expect_identical(sum(endsWith(log$requests, "manifest.json")), n + 1L)
  }
})

test_that("a token that GitHub rejects does not block the public releases", {
  local_fake_release()
  withr::local_envvar(GITHUB_PAT = "expired")
  with_token <- 0
  httr2::local_mocked_responses(function(req) {
    if (!is.null(req$headers$Authorization)) {
      with_token <<- with_token + 1
      return(httr2::response(401))
    }
    httr2::response_json(body = fake_listing("test/pksR-data"))
  })
  expect_warning(v <- pks_versions(), "rejected the token")
  expect_identical(v$version, c("2026.1", "2025.1"))
  expect_identical(with_token, 1)
})

test_that("HTTP errors from GitHub say what the user can do", {
  local_fake_release()
  httr2::local_mocked_responses(function(req) httr2::response(403, headers = list("x-ratelimit-remaining" = "0")))
  expect_error(pks_versions(), "60 requests per hour")
  withr::local_envvar(GITHUB_PAT = "valid")
  expect_error(pks_versions(), "rate limit for your token")
  httr2::local_mocked_responses(function(req) httr2::response(401))
  expect_error(suppressWarnings(pks_versions()), "renew or unset")
})

test_that("arguments the stress test found unchecked are refused", {
  expect_error(pks_get(years = integer(0)), "whole numbers")
  expect_error(pks_rates(pks_example(), per = Inf), "positive number")
})

