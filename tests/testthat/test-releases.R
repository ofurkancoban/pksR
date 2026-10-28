test_that("only published v<year>.<n> releases count, newest first", {
  local_fake_release()
  v <- pks_versions()
  expect_identical(v$version, c("2026.1", "2025.1"))
  expect_identical(v$tag, c("v2026.1", "v2025.1"))
})

test_that("the manifest lists every file with its checksum", {
  local_fake_release()
  m <- pks_manifest()
  expect_s3_class(m, "tbl_df")
  expect_true(all(c("boundary_map.csv", "pks_kreis_2021_population.csv.gz") %in% m$name))
  expect_true(all(grepl("^[0-9a-f]{64}$", m$sha256)))
  meta <- attr(m, "manifest")
  expect_identical(meta$data_version, "2026.1")
  expect_equal(meta$target_boundary_year, 2025)
})

test_that("an unknown version is an error that lists the available ones", {
  local_fake_release()
  expect_error(pks_manifest("2024.9"), "2026.1")
  expect_error(pks_get(version = c("a", "b")), "one string")
})

test_that("without internet the newest cached version is used, and nothing else is possible", {
  local_fake_release()
  pks_get(years = 2021, offence = "------")
  # Same cache, network gone
  cache <- Sys.getenv("R_USER_CACHE_DIR")
  log <- local_fake_release(offline = TRUE)
  withr::local_envvar(R_USER_CACHE_DIR = cache)
  expect_warning(d <- pks_get(years = 2021, offence = "------"), "newest cached version")
  expect_identical(attr(d, "data_version"), "2026.1")
  # Five districts in the fixture, four at the 2025 boundary (Eisenach merged)
  expect_equal(nrow(d), 4)
  # A year that was never downloaded cannot come from the cache
  expect_error(suppressWarnings(pks_get(years = 2019)), "failed")
})

test_that("without internet and without cache the error says why", {
  local_fake_release(offline = TRUE)
  expect_error(pks_get(), "Cannot reach GitHub")
})
