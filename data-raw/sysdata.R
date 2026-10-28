# Builds R/sysdata.rda: the offence map and the known methodological breaks
# of pksR-data, for pks_offences() and pks_breaks() without internet.
# Usage (from the package root):
#   Rscript data-raw/sysdata.R <path to pksR-data>
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("Usage: Rscript data-raw/sysdata.R <path to pksR-data>")
registry <- file.path(args[1], "registry")

read <- function(name) {
  readr::read_csv(file.path(registry, name), col_types = readr::cols(.default = "c"), na = "", progress = FALSE)
}

offence_map_snapshot <- read("offence_map.csv")
offence_map_snapshot$valid_from <- as.integer(offence_map_snapshot$valid_from)
offence_map_snapshot$valid_to <- as.integer(offence_map_snapshot$valid_to)

known_breaks_snapshot <- read("known_breaks.csv")
known_breaks_snapshot$first_year <- as.integer(known_breaks_snapshot$first_year)

# Which pipeline state the snapshot reflects
snapshot_info <- list(
  pipeline_commit = system2("git", c("-C", shQuote(args[1]), "rev-parse", "HEAD"), stdout = TRUE),
  created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
)

save(offence_map_snapshot, known_breaks_snapshot, snapshot_info,
     file = "R/sysdata.rda", compress = "xz", version = 2)
