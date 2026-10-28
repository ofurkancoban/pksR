# Builds inst/extdata/pks_example.csv: a small subset of the harmonized panel
# of pksR-data (population weights) for examples, tests and vignettes.
# Usage (from the package root):
#   Rscript data-raw/example.R <path to pksR-data>
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("Usage: Rscript data-raw/example.R <path to pksR-data>")
dir <- file.path(args[1], "output", "harmonized", "population")

years <- 2019:2025
# Flensburg, Hamburg, Goettingen (absorbed Osterode am Harz in 2016), Berlin,
# Wartburgkreis (absorbed Eisenach in 2021): city-states and merged districts
districts <- c("01001", "02000", "03159", "11000", "16063")
keys <- c("------", "890000")

d <- do.call(rbind, lapply(years, function(y) {
  x <- readr::read_csv(file.path(dir, sprintf("pks_kreis_%d.csv.gz", y)),
                       col_types = readr::cols(.default = "c"), na = "", progress = FALSE)
  x[x$ags %in% districts & x$offence_key %in% keys, ]
}))
stopifnot(nrow(d) == length(years) * length(districts) * length(keys))
readr::write_csv(d, "inst/extdata/pks_example.csv", na = "")

commit <- system2("git", c("-C", shQuote(args[1]), "rev-parse", "--short", "HEAD"), stdout = TRUE)
cat(sprintf("Wrote %d rows from pksR-data %s\n", nrow(d), commit))
