test_that("harmonized data come with the attributes of the request", {
  local_fake_release()
  d <- pks_get(years = 2019:2021)
  expect_s3_class(d, "tbl_df")
  expect_identical(names(d), returned_columns(pksR:::harmonized_spec))
  expect_identical(attr(d, "data_version"), "2026.1")
  expect_identical(attr(d, "boundary_year"), 2025L)
  expect_identical(attr(d, "weights"), "population")
  expect_s3_class(attr(d, "retrieved_at"), "POSIXct")
  expect_identical(attr(d, "source_urls"), paste0(
    "https://github.com/test/pksR-data/releases/download/v2026.1/",
    c(sprintf("pks_kreis_%d_population.csv.gz", 2019:2021), sprintf("pks_kreis_%d_population_details.csv.gz", 2019:2021),
      "boundary_map.csv", "offence_map.csv")
  ))
  expect_true(all(d$boundary_year == 2025L))
  # Eisenach (16056) is part of the Wartburgkreis at the 2025 boundary
  expect_false("16056" %in% d$ags)
  expect_true(all(d$weight_type[d$ags == "16063" & d$year < 2021] == "population"))
})

test_that("the data as published keep the published codes and keys", {
  local_fake_release()
  d <- pks_get(years = 2019, harmonize_to = NULL)
  expect_identical(names(d), returned_columns(pksR:::canonical_spec))
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
  # The census-corrected population moves with the districts
  corrected <- sum(d$population_corrected[d$ags %in% c("16056", "16063") & d$offence_key == "------"])
  expect_equal(h$population_corrected[h$ags == "16063"], corrected)
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
  path <- list.files(Sys.getenv("R_USER_CACHE_DIR"), "pks_kreis_2021_population\\.csv\\.gz$", recursive = TRUE, full.names = TRUE)
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

test_that("every row gets the official name of its district and boundary year", {
  local_fake_release()
  h <- suppressMessages(pks_get(years = 2019:2021, offence = "total"))
  expect_false(anyNA(h$region_name_official))
  # One official name per district in a harmonized panel
  per_ags <- tapply(h$region_name_official, h$ags, function(x) length(unique(x)))
  expect_true(all(per_ags == 1))
  # The data as published name Eisenach, which the 2025 boundary lacks
  p <- suppressMessages(pks_get(years = 2019, offence = "total", harmonize_to = NULL))
  expect_false(anyNA(p$region_name_official))
  expect_match(p$region_name_official[p$ags == "16056"], "Eisenach")
  # Harmonizing to another boundary names the districts of that boundary
  h21 <- suppressMessages(pks_get(years = 2019, offence = "total", harmonize_to = 2021))
  expect_false(anyNA(h21$region_name_official))
  expect_false("16056" %in% h21$ags)
})

test_that("official names never add or drop rows", {
  map <- tibble::tibble(
    id = c("a", "b"), period = 2019L, from_ags = c("01001", "01002"), from_name = c("Flensburg", "Kiel"),
    to_ags = c("01001", "01002"), to_name = c("Flensburg", "Kiel"), weight_population = 1, weight_area = 1,
    source = "bbsr", replaces = NA_character_, status = "official", reason = NA_character_
  )
  d <- tibble::tibble(year = 2019L, ags = c("01001", "01002", "01003"), region_name = "x", boundary_year = 2019L)
  expect_warning(out <- pksR:::add_official_names(d, map), "01003")
  expect_identical(nrow(out), 3L)
  expect_identical(names(out), c("year", "ags", "region_name", "region_name_official", "boundary_year"))
  expect_identical(out$region_name_official, c("Flensburg", "Kiel", NA))
})

test_that("detail columns are joined from the detail files", {
  local_fake_release()
  p <- suppressMessages(pks_get(years = 2019:2021, harmonize_to = NULL))
  expect_false(anyNA(p[c("district_type", "suspects_male", "suspects_female", "suspects_non_german", "firearm_threatened", "firearm_fired")]))
  expect_identical(p$suspects_male + p$suspects_female, p$suspects)
  expect_true(all(p$suspects_non_german <= p$suspects))
  expect_true(all(p$district_type %in% c("KfS", "K", "LK", "SK", "RV")))
  expect_true(any(grepl("_published_details.csv.gz$", attr(p, "source_urls"))))
  # Harmonized as released and by the package: the breakdown still adds up
  h <- suppressMessages(pks_get(years = 2019:2021))
  expect_equal(h$suspects_male + h$suspects_female, h$suspects)
  h21 <- suppressMessages(pks_get(years = 2019:2020, harmonize_to = 2021))
  expect_equal(h21$suspects_male + h21$suspects_female, h21$suspects)
  # The merged Wartburgkreis has no published type for 2019 and 2020
  expect_true(all(is.na(h21$district_type[h21$ags == "16063"])))
  expect_false(anyNA(h21$district_type[h21$ags == "01001"]))
  # Detail counts are conserved like cases
  key <- p$year %in% 2019:2020 & p$offence_key == "------"
  expect_equal(sum(h21$suspects_non_german[h21$offence_key == "------"]), sum(p$suspects_non_german[key]))
})

test_that("a release without detail files gives NA detail columns", {
  local_fake_release(without_details = TRUE)
  expect_message(d <- pks_get(years = 2019), "no detail columns")
  expect_identical(names(d), returned_columns(pksR:::harmonized_spec))
  expect_true(all(is.na(d[c("district_type", "suspects_male", "suspects_non_german")])))
  expect_type(d$suspects_male, "double")
  expect_false(any(grepl("_details", attr(d, "source_urls"))))
})

test_that("detail files that do not match the data stop the request", {
  data <- tibble::tibble(year = 2019L, ags = c("01001", "01002"), offence_key = "------", cases = 1:2)
  extra <- tibble::tibble(year = 2019L, ags = "01001", offence_key = "------", suspects_male = 1L)
  expect_error(pksR:::join_details(data, extra), "row by row")
  expect_error(pksR:::join_details(data, rbind(extra, extra)), "duplicate")
})
