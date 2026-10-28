test_that("harmonized data come with the attributes of the request", {
  local_fake_release()
  d <- pks_get(years = 2019:2021)
  expect_s3_class(d, "tbl_df")
  expect_identical(names(d), names(pksR:::harmonized_spec))
  expect_identical(attr(d, "data_version"), "2026.1")
  expect_identical(attr(d, "boundary_year"), 2025L)
  expect_identical(attr(d, "weights"), "population")
  expect_s3_class(attr(d, "retrieved_at"), "POSIXct")
  expect_identical(attr(d, "source_urls"), paste0(
    "https://github.com/test/pksR-data/releases/download/v2026.1/",
    c(sprintf("pks_kreis_%d_population.csv.gz", 2019:2021), "offence_map.csv")
  ))
  expect_true(all(d$boundary_year == 2025L))
  # Eisenach (16056) is part of the Wartburgkreis at the 2025 boundary
  expect_false("16056" %in% d$ags)
  expect_true(all(d$weight_type[d$ags == "16063" & d$year < 2021] == "population"))
})

test_that("the data as published keep the published codes and keys", {
  local_fake_release()
  d <- pks_get(years = 2019, harmonize_to = NULL)
  expect_identical(names(d), names(pksR:::canonical_spec))
  expect_true("16056" %in% d$ags)
  expect_true(all(d$boundary_year == 2019L))
  expect_identical(attr(d, "boundary_year"), NA_integer_)
  expect_identical(attr(d, "weights"), NA_character_)
  # Eisenach and the Wartburgkreis together are the merged district of the
  # 2021 boundary (merger on 1 July 2021, weight 1); at later boundaries a
  # 2024 transfer to 16064 takes a share off
  h <- suppressMessages(pks_get(years = 2019, offence = "total", harmonize_to = 2021))
  merged <- sum(d$cases[d$ags %in% c("16056", "16063") & d$offence_key == "------"])
  expect_equal(h$cases[h$ags == "16063"], merged)
})

test_that("area weights read the area panel", {
  local_fake_release()
  d <- pks_get(years = 2020, weights = "area", offence = "------")
  expect_identical(attr(d, "weights"), "area")
  expect_match(attr(d, "source_urls")[1], "_area\\.csv\\.gz$")
})

test_that("harmonizing to an earlier boundary uses the crosswalk of the release", {
  local_fake_release()
  expect_message(d <- pks_get(years = 2019:2020, harmonize_to = 2021), "Harmonizing")
  expect_true(all(d$boundary_year == 2021L))
  expect_false("16056" %in% d$ags)
  # Counts are conserved per offence key and year
  p <- pks_get(years = 2019:2020, harmonize_to = NULL)
  for (y in 2019:2020) {
    expect_equal(sum(d$cases[d$year == y & d$offence_key == "------"]),
                 sum(p$cases[p$year == y & p$offence_key == "------"]))
  }
  expect_true(any(grepl("boundary_map.csv", attr(d, "source_urls"))))
  expect_true(any(grepl("offence_map.csv", attr(d, "source_urls"))))
})

test_that("harmonizing to the release boundary on the client gives the released panel", {
  local_fake_release()
  released <- pks_get(years = 2019:2021)
  m <- attr(pks_manifest(), "manifest")
  published <- pks_get(years = 2019:2021, harmonize_to = NULL)
  maps <- vapply(c("boundary_map.csv", "offence_map.csv"), function(f) pksR:::release_file("2026.1", f, pksR:::read_manifest("2026.1"), TRUE), "")
  client <- pksR:::harmonize_published(published, pksR:::read_boundary_map(maps[[1]]), pksR:::read_offence_map(maps[[2]]), 2025L, "population")
  # Only districts whose sources are all in the fixture are comparable
  keep <- c("01001", "02000", "11000", "16063")
  key <- function(x) as.data.frame(x[x$ags %in% keep, ][order(x$year[x$ags %in% keep], x$offence_key[x$ags %in% keep], x$ags[x$ags %in% keep]), ])
  common <- c("year", "ags", "offence_key", "cases", "attempts", "cleared", "hz", "clearance_rate", "boundary_year", "harmonized")
  expect_equal(key(client)[common], key(released)[common], tolerance = 1e-10, ignore_attr = TRUE)
})

test_that("forward harmonization only, and only to boundaries the crosswalk covers", {
  local_fake_release()
  expect_error(pks_get(years = 2021, harmonize_to = 2019), "forward")
  expect_error(pks_get(years = 2019, harmonize_to = 1990), "boundary years")
  expect_error(pks_get(harmonize_to = "2020"), "must be a year")
})

test_that("years and offence keys are checked", {
  local_fake_release()
  expect_error(pks_get(years = 2018), "has no year")
  expect_error(pks_get(years = 2019.5), "whole numbers")
  expect_error(pks_get(offence = 890000), "character vector")
  expect_error(pks_get(years = 2021, offence = c("------", "nonsense")), "No offence matches")
  expect_error(pks_get(source = "bka"), "not available yet")
})

test_that("files are downloaded once and reused from the cache", {
  log <- local_fake_release()
  pks_get(years = 2021)
  n <- length(log$requests)
  pks_get(years = 2021)
  expect_identical(length(log$requests), n)
  info <- pks_cache_info()
  expect_true(all(c("manifest.json", "pks_kreis_2021_population.csv.gz") %in% info$file))
  expect_true(startsWith(attr(info, "path"), Sys.getenv("R_USER_CACHE_DIR")))
})

test_that("cache = FALSE leaves the cache empty", {
  local_fake_release()
  pks_get(years = 2021, cache = FALSE)
  expect_equal(nrow(pks_cache_info()), 0)
})

test_that("a download with the wrong checksum is refused and not cached", {
  local_fake_release(corrupt = "pks_kreis_2020_population.csv.gz")
  expect_error(pks_get(years = 2020), "checksum")
  expect_false("pks_kreis_2020_population.csv.gz" %in% pks_cache_info()$file)
})

test_that("a damaged cached file is downloaded again", {
  log <- local_fake_release()
  pks_get(years = 2021)
  path <- list.files(Sys.getenv("R_USER_CACHE_DIR"), "pks_kreis_2021_population", recursive = TRUE, full.names = TRUE)
  writeLines("damaged", path)
  n <- length(log$requests)
  d <- pks_get(years = 2021)
  expect_gt(length(log$requests), n)
  expect_gt(nrow(d), 0)
})

test_that("the data notes are shown once per session and version", {
  local_fake_release()
  expect_message(pks_get(years = 2021), "clearance_rate")
  expect_no_message(pks_get(years = 2021))
})
