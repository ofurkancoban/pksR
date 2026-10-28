# Builds tests/testthat/fixtures/release/: a small fake data release
# "v2026.1" for the offline tests, cut from a local build of pksR-data.
# Usage (from the package root, after targets::tar_make() in pksR-data):
#   Rscript data-raw/test-fixtures.R <path to pksR-data>
#
# Contents: years 2019 to 2021 for five districts (all offence keys, so the
# offence map applies), as published and harmonized with both weightings,
# plus the full crosswalk and offence map. Eisenach (16056) merged into the
# Wartburgkreis (16063) on 1 July 2021, so harmonization is exercised.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("Usage: Rscript data-raw/test-fixtures.R <path to pksR-data>")
rel <- file.path(args[1], "output", "release")
out <- "tests/testthat/fixtures/release"
unlink(out, recursive = TRUE)
dir.create(out, recursive = TRUE)

years <- 2019:2021
districts <- c("01001", "02000", "11000", "16056", "16063")
subset_csv <- function(name) {
  x <- readr::read_csv(file.path(rel, name), col_types = readr::cols(.default = "c"), na = "", progress = FALSE)
  x <- x[x$ags %in% districts, ]
  readr::write_csv(x, file.path(out, name), na = "")
}
for (y in years) {
  subset_csv(sprintf("pks_kreis_%d_published.csv.gz", y))
  for (w in c("population", "area")) subset_csv(sprintf("pks_kreis_%d_%s.csv.gz", y, w))
}
file.copy(file.path(rel, "offence_map.csv"), out)
# Stored compressed, served uncompressed by the mock (helper-release.R)
writeLines(readLines(file.path(rel, "boundary_map.csv"), encoding = "UTF-8"), gzfile(file.path(out, "boundary_map.csv.gz")), useBytes = TRUE)

served <- function(f) {
  if (f == "boundary_map.csv") {
    tmp <- tempfile()
    writeBin(memDecompress(readBin(file.path(out, "boundary_map.csv.gz"), "raw", 2e7), "gzip"), tmp)
    return(tmp)
  }
  file.path(out, f)
}
names <- c(sort(setdiff(list.files(out), "boundary_map.csv.gz")), "boundary_map.csv")
# The data notes as the pipeline writes them into the manifest
pipeline <- new.env()
for (f in list.files(file.path(args[1], "R"), pattern = "[.]R$", full.names = TRUE)) sys.source(f, envir = pipeline)
notes <- list(published = as.list(pipeline$published_notes), harmonized = as.list(pipeline$panel_notes))
manifest <- list(
  data_version = "2026.1",
  created_at = "2026-10-28T12:00:00Z",
  pipeline_commit = "0000000000000000000000000000000000000000",
  target_boundary_year = 2025L,
  years = c(2019L, 2021L),
  weights = c("area", "population"),
  validation = list(area = "pass", population = "pass"),
  notes = notes,
  license = "dl-de/by-2-0",
  license_url = "https://www.govdata.de/dl-de/by-2-0",
  zenodo_doi = NULL,
  files = lapply(names, function(f) {
    p <- served(f)
    list(name = f, sha256 = digest::digest(file = p, algo = "sha256"), bytes = file.size(p), rows = NA)
  })
)
jsonlite::write_json(manifest, file.path(out, "manifest.json"), auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null", digits = NA)
cat("Fixture release:", length(names), "files,", round(sum(file.size(list.files(out, full.names = TRUE))) / 1024), "KB\n")
