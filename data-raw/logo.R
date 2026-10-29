# Builds the hex logo man/figures/logo.svg and man/figures/logo.png.
# Usage (from the package root):
#   Rscript data-raw/logo.R <VG250_KRS.shp> <pks_kreis_2020_published.csv.gz>
#
# The map shows the real districts of Germany (BKG VG250, as of 1 January
# 2020) filled by the published 2020 frequency rate (HZ) of total offences
# from the PKS district table. Both sources are on the 2020 boundary, so the
# join is exact (401 districts). Source note for the geometries, required by
# dl-de/by-2-0: "(c) GeoBasis-DE / BKG 2025 (Daten veraendert)", see README.
# The PNG is rendered with rsvg-convert (librsvg), which must be on the PATH.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("Usage: Rscript data-raw/logo.R <VG250_KRS.shp> <pks_kreis_2020_published.csv.gz>")

# Pointy-top hexagon of the usual sticker proportions (width : height = sqrt(3) : 2)
width <- 520
height <- 600
inset <- 8
hex <- cbind(
  c(width / 2, width - inset, width - inset, width / 2, inset, inset),
  c(inset, height * 0.25 + inset / 2, height * 0.75 - inset / 2, height - inset, height * 0.75 - inset / 2, height * 0.25 + inset / 2)
)
colours <- list(
  background = "#16213B",
  border = "#E8B04B",
  district_border = "#16213B",
  text = "#FFFFFF",
  # Sequential palette from low to high HZ, readable on the dark background
  scale = c("#FFF1C9", "#FDD58A", "#F9B45C", "#F08A3E", "#DE5B31", "#BF3428", "#8F1D22")
)

districts <- sf::st_read(args[1], quiet = TRUE)
# GF 4 is land area; GF 2 adds water areas such as the Bodensee as separate rows
districts <- districts[districts$GF == 4, c("AGS", "geometry")]
pks <- readr::read_csv(args[2], col_types = readr::cols(.default = "c"), progress = FALSE)
pks <- pks[pks$offence_key == "------", c("ags", "hz")]
map <- merge(districts, pks, by.x = "AGS", by.y = "ags", all.x = TRUE)
if (nrow(map) != nrow(districts) || anyNA(map$hz)) stop("Every district needs a published HZ.")

# Quantile classes, so the colours spread evenly over the districts
hz <- as.numeric(map$hz)
breaks <- stats::quantile(hz, probs = seq(0, 1, length.out = length(colours$scale) + 1))
map$fill <- colours$scale[findInterval(hz, breaks, rightmost.closed = TRUE, all.inside = TRUE)]

# Simplify for a small file; a few hundred metres are invisible at sticker size
map <- sf::st_simplify(map, dTolerance = 900, preserveTopology = TRUE)

# Fit the map into the upper part of the hexagon, keeping its aspect ratio
box <- sf::st_bbox(map)
area <- c(x0 = 135, x1 = 385, y0 = 58, y1 = 400)
scale <- min((area[["x1"]] - area[["x0"]]) / (box[["xmax"]] - box[["xmin"]]),
             (area[["y1"]] - area[["y0"]]) / (box[["ymax"]] - box[["ymin"]]))
x_offset <- (area[["x0"]] + area[["x1"]]) / 2 - scale * (box[["xmin"]] + box[["xmax"]]) / 2
y_offset <- (area[["y0"]] + area[["y1"]]) / 2 + scale * (box[["ymin"]] + box[["ymax"]]) / 2

ring_path <- function(ring) {
  x <- x_offset + scale * ring[, 1]
  y <- y_offset - scale * ring[, 2]
  paste0("M", paste(sprintf("%.1f %.1f", x, y), collapse = "L"), "Z")
}
geometry_path <- function(g) {
  polygons <- if (inherits(g, "MULTIPOLYGON")) unclass(g) else list(unclass(g))
  paste(vapply(unlist(polygons, recursive = FALSE), ring_path, ""), collapse = "")
}
paths <- vapply(sf::st_geometry(map), geometry_path, "")

points <- paste(sprintf("%.1f,%.1f", hex[, 1], hex[, 2]), collapse = " ")
svg <- c(
  sprintf('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">', width, height, width, height),
  "<title>pksR</title>",
  sprintf('<polygon points="%s" fill="%s" stroke="%s" stroke-width="12" stroke-linejoin="round"/>', points, colours$background, colours$border),
  sprintf('<g stroke="%s" stroke-width="0.6" stroke-linejoin="round" fill-rule="evenodd">', colours$district_border),
  sprintf('<path d="%s" fill="%s"/>', paths, map$fill),
  "</g>",
  sprintf('<text x="%d" y="488" text-anchor="middle" font-family="Avenir Next, Helvetica Neue, Helvetica, Arial, sans-serif" font-weight="700" font-size="86" fill="%s">pksR</text>', width / 2, colours$text),
  "</svg>"
)
dir.create("man/figures", showWarnings = FALSE, recursive = TRUE)
writeLines(svg, "man/figures/logo.svg", useBytes = TRUE)

# 240 px wide is what pkgdown and the README show; 2x for sharp screens
status <- system2("rsvg-convert", c("-w", "480", "-o", "man/figures/logo.png", "man/figures/logo.svg"))
if (status != 0) stop("rsvg-convert failed.")
message(sprintf("Logo: %d districts, svg %.0f KB, png %.0f KB", nrow(map),
                file.size("man/figures/logo.svg") / 1024, file.size("man/figures/logo.png") / 1024))
