# Builds the hex logo man/figures/logo.svg and man/figures/logo.png.
# Usage (from the package root):
#   Rscript data-raw/logo.R <VG250_KRS.shp> <pks_kreis_2025_published.csv.gz>
#
# The map shows the 400 districts of Germany today, filled by the published
# 2025 frequency rate (HZ) of total offences from the PKS district table.
# Geometries: BKG VG250 as of 1 January 2020 (401 districts), with Eisenach
# (16056) merged into the Wartburgkreis (16063) as on 1 July 2021. The later
# transfer of single municipalities (for example 2024 from 16063 to 16064)
# is too small to see at sticker size and is not drawn. The colours are those of the German flag:
# a black hexagon, and districts from gold (low HZ) over red to dark red
# (high HZ). Source note for the geometries, required by dl-de/by-2-0:
# "(c) GeoBasis-DE / BKG 2025 (Daten veraendert)", see README.
# The PNG is rendered with rsvg-convert (librsvg), which must be on the PATH.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("Usage: Rscript data-raw/logo.R <VG250_KRS.shp> <pks_kreis_2025_published.csv.gz>")

# Pointy-top hexagon of the usual sticker proportions (width : height = sqrt(3) : 2)
width <- 520
height <- 600
hexagon <- function(margin) {
  # Corners of a hexagon `margin` px inside the sticker edge
  r <- height / 2 - margin / cos(pi / 6)
  a <- pi / 2 + seq(0, 5) * pi / 3
  cbind(width / 2 + r * cos(a), height / 2 - r * sin(a))
}
points <- function(h) paste(sprintf("%.1f,%.1f", h[, 1], h[, 2]), collapse = " ")

flag <- c(black = "#000000", red = "#DD0000", gold = "#FFCE00")
colours <- list(
  background_inner = "#26262B",
  background_outer = "#0E0E10",
  text = "#FFFFFF",
  subtitle = "#FFCE00",
  # Low to high HZ: flag gold over flag red to a dark red
  scale = c("#FFE88A", "#FFCE00", "#FFA400", "#FF7300", "#DD0000", "#A80000", "#6E0000")
)

districts <- sf::st_read(args[1], quiet = TRUE)
# GF 4 is land area; GF 2 adds water areas such as the Bodensee as separate rows
districts <- districts[districts$GF == 4, c("AGS", "geometry")]
# Eisenach became part of the Wartburgkreis on 1 July 2021
districts$AGS[districts$AGS == "16056"] <- "16063"
districts <- stats::aggregate(districts[, "geometry"], by = list(AGS = districts$AGS), FUN = function(x) x[1], do_union = TRUE)
if (nrow(districts) != 400) stop("Expected 400 districts after the 2021 merger.")
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
area <- c(x0 = 140, x1 = 380, y0 = 50, y1 = 342)
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

# Flag bar between the name and the subtitle
bar_width <- 132
bar_x <- width / 2 - bar_width / 2
bar <- sprintf('<rect x="%.1f" y="444" width="%.1f" height="7" fill="%s"/>',
               bar_x + (0:2) * bar_width / 3, bar_width / 3, flag)

font <- "Avenir Next, Helvetica Neue, Helvetica, Arial, sans-serif"
svg <- c(
  sprintf('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">', width, height, width, height),
  "<title>pksR: Polizeiliche Kriminalstatistik</title>",
  "<defs>",
  sprintf('<radialGradient id="bg" cx="50%%" cy="38%%" r="65%%"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></radialGradient>',
          colours$background_inner, colours$background_outer),
  # A soft red glow behind the map lifts it off the dark background
  '<filter id="glow" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur in="SourceAlpha" stdDeviation="9" result="blur"/><feFlood flood-color="#DD0000" flood-opacity="0.45"/><feComposite in2="blur" operator="in" result="halo"/><feMerge><feMergeNode in="halo"/><feMergeNode in="SourceGraphic"/></feMerge></filter>',
  "</defs>",
  # Outer gold edge, black body, thin red inner line: the three flag colours
  sprintf('<polygon points="%s" fill="%s"/>', points(hexagon(0)), flag[["gold"]]),
  sprintf('<polygon points="%s" fill="url(#bg)"/>', points(hexagon(11))),
  sprintf('<polygon points="%s" fill="none" stroke="%s" stroke-width="2.5" stroke-linejoin="round"/>', points(hexagon(21)), flag[["red"]]),
  sprintf('<g filter="url(#glow)" stroke="%s" stroke-width="0.5" stroke-linejoin="round" fill-rule="evenodd">', colours$background_outer),
  sprintf('<path d="%s" fill="%s"/>', paths, map$fill),
  "</g>",
  sprintf('<text x="%d" y="430" text-anchor="middle" font-family="%s" font-weight="700" font-size="78" letter-spacing="-1" fill="%s">pksR</text>',
          width / 2, font, colours$text),
  bar,
  sprintf('<text x="%d" y="480" text-anchor="middle" font-family="%s" font-weight="600" font-size="17" letter-spacing="3" fill="%s">POLIZEILICHE</text>',
          width / 2, font, colours$subtitle),
  sprintf('<text x="%d" y="504" text-anchor="middle" font-family="%s" font-weight="600" font-size="17" letter-spacing="3" fill="%s">KRIMINALSTATISTIK</text>',
          width / 2, font, colours$subtitle),
  "</svg>"
)
dir.create("man/figures", showWarnings = FALSE, recursive = TRUE)
writeLines(svg, "man/figures/logo.svg", useBytes = TRUE)

# 240 px wide is what pkgdown and the README show; 2x for sharp screens
status <- system2("rsvg-convert", c("-w", "480", "-o", "man/figures/logo.png", "man/figures/logo.svg"))
if (status != 0) stop("rsvg-convert failed.")
message(sprintf("Logo: %d districts, svg %.0f KB, png %.0f KB", nrow(map),
                file.size("man/figures/logo.svg") / 1024, file.size("man/figures/logo.png") / 1024))
