test_that("the cache lives below R_user_dir and can be cleared by version", {
  local_fake_release()
  pks_get(years = 2021)
  info <- pks_cache_info()
  expect_identical(attr(info, "path"), tools::R_user_dir("pksR", "cache"))
  expect_true(all(info$version == "2026.1"))
  expect_message(pks_cache_clear(version = "2025.1", ask = FALSE), "Nothing to remove")
  removed <- pks_cache_clear(version = "2026.1", ask = FALSE)
  expect_equal(nrow(removed), nrow(info))
  expect_equal(nrow(pks_cache_info()), 0)
})

test_that("clearing asks first in interactive use", {
  local_fake_release()
  pks_get(years = 2021)
  local_mocked_bindings(ask_yes_no = function(...) FALSE)
  expect_message(pks_cache_clear(ask = TRUE), "unchanged")
  expect_gt(nrow(pks_cache_info()), 0)
})

test_that("sizes are printed in readable units", {
  expect_identical(pksR:::format_bytes(0), "0 B")
  expect_identical(pksR:::format_bytes(2048), "2.0 KB")
  expect_identical(pksR:::format_bytes(5 * 1024^2), "5.0 MB")
})
