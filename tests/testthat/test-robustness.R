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

