# Builds inst/extdata/pks_example.csv: a small subset of the harmonized panel
# of pksR-data (population weights) for examples, tests and vignettes, in the
# format of pks_get(): the release columns, the detail columns and the
# official district names.
# Usage (from the package root, after targets::tar_make() in pksR-data):
#   Rscript data-raw/example.R <path to pksR-data>
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("Usage: Rscript data-raw/example.R <path to pksR-data>")
dir <- file.path(args[1], "output", "harmonized", "population")
pkgload::load_all(".", quiet = TRUE)

years <- 2019:2025
# Flensburg, Hamburg, Goettingen (absorbed Osterode am Harz in 2016), Berlin,
# Wartburgkreis (absorbed Eisenach in 2021): city-states and merged districts
districts <- c("01001", "02000", "03159", "11000", "16063")
keys <- c("------", "890000")

read <- function(f) {
  x <- readr::read_csv(file.path(dir, f), col_types = readr::cols(.default = "c"), na = "", progress = FALSE)
  x[x$ags %in% districts & x$offence_key %in% keys, ]
}
d <- do.call(rbind, lapply(years, function(y) {
  main <- read(sprintf("pks_kreis_%d.csv.gz", y))
  details <- read(sprintf("pks_kreis_%d_details.csv.gz", y))
  out <- dplyr::left_join(main, details, by = c("year", "ags", "offence_key"))
  stopifnot(nrow(out) == nrow(main), nrow(details) == nrow(main))
  out
}))
stopifnot(nrow(d) == length(years) * length(districts) * length(keys))

# Official names from the registry crosswalk, as pks_get() adds them
map <- read_boundary_map(file.path(args[1], "registry", "boundary_map.csv"))
d$boundary_year <- as.integer(d$boundary_year)
d <- add_official_names(d, map)
readr::write_csv(d, "inst/extdata/pks_example.csv", na = "")

commit <- system2("git", c("-C", shQuote(args[1]), "rev-parse", "--short", "HEAD"), stdout = TRUE)
cat(sprintf("Wrote %d rows from pksR-data %s\n", nrow(d), commit))
