# Builds the hex logo man/figures/logo.svg and man/figures/logo.png.
# Usage (from the package root):
#   Rscript data-raw/logo.R <VG250_KRS.shp> <pks_kreis_2025_published.csv.gz>
#
# The logo is Germany as a fingerprint: the ridges are contour lines of the
# published 2025 frequency rate (HZ) of total offences in the 400 districts,
# smoothed into a surface, and coloured in the German flag colours from gold
# (low HZ) over red to dark red (high HZ). The real data draw the lines.
#
# Geometries: BKG VG250 as of 1 January 2020 (401 districts), with Eisenach
# (16056) merged into the Wartburgkreis (16063) as on 1 July 2021; the codes
# then match the 2025 table one to one. Later municipality transfers are too
# small to matter at sticker size. Source note required by dl-de/by-2-0:
# "(c) GeoBasis-DE / BKG 2025 (Daten veraendert)", see README.
# The PNG is rendered with rsvg-convert (librsvg), which must be on the PATH.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("Usage: Rscript data-raw/logo.R <VG250_KRS.shp> <pks_kreis_2025_published.csv.gz>")

cell <- 2500       # grid spacing of the surface, metres
sigma <- 45000     # Gaussian smoothing, metres; large values give fingerprint-like ridges
n_ridges <- 52     # number of contour lines
ridge_width <- 1.25

# Districts with their 2025 HZ ------------------------------------------------
districts <- sf::st_read(args[1], quiet = TRUE)
# GF 4 is land area; GF 2 adds water areas such as the Bodensee as separate rows
districts <- districts[districts$GF == 4, c("AGS", "geometry")]
# Eisenach became part of the Wartburgkreis on 1 July 2021
districts$AGS[districts$AGS == "16056"] <- "16063"
districts <- stats::aggregate(districts[, "geometry"], by = list(AGS = districts$AGS), FUN = function(x) x[1], do_union = TRUE)
if (nrow(districts) != 400) stop("Expected 400 districts after the 2021 merger.")
pks <- readr::read_csv(args[2], col_types = readr::cols(.default = "c"), progress = FALSE)
pks <- pks[pks$offence_key == "------", c("ags", "hz")]
districts <- merge(districts, pks, by.x = "AGS", by.y = "ags", all.x = TRUE)
if (anyNA(districts$hz)) stop("Every district needs a published HZ.")
outline <- sf::st_union(districts)

# Smooth surface of log HZ ------------------------------------------------------
box <- sf::st_bbox(outline)
pad <- 3 * sigma
xs <- seq(box[["xmin"]] - pad, box[["xmax"]] + pad, by = cell)
ys <- seq(box[["ymin"]] - pad, box[["ymax"]] + pad, by = cell)
grid <- sf::st_as_sf(expand.grid(x = xs, y = ys), coords = c("x", "y"), crs = sf::st_crs(districts))
hit <- vapply(sf::st_intersects(grid, districts), function(i) if (length(i)) i[1] else NA_integer_, 1L)
value <- matrix(log(as.numeric(districts$hz))[hit], nrow = length(xs))
land <- !is.na(value)
value[!land] <- 0
# Normalized (masked) Gaussian smoothing, separable in x and y, so the sea
# does not pull coastal values down
gauss <- function(n) outer(seq_len(n), seq_len(n), function(a, b) exp(-((a - b) * cell)^2 / (2 * sigma^2)))
kx <- gauss(length(xs))
ky <- gauss(length(ys))
surface <- (kx %*% value %*% t(ky)) / pmax(kx %*% (land * 1) %*% t(ky), 1e-9)

# Evenly spaced levels give evenly spaced ridges, as on a fingertip
range_land <- stats::quantile(surface[land], c(0.005, 0.995))
levels <- seq(range_land[1], range_land[2], length.out = n_ridges)
contours <- grDevices::contourLines(xs, ys, surface, levels = levels)
ridges <- sf::st_sf(
  rank = match(vapply(contours, function(l) l$level, 1), levels),
  geometry = sf::st_sfc(lapply(contours, function(l) sf::st_linestring(cbind(l$x, l$y))), crs = sf::st_crs(districts))
)
ridges <- suppressWarnings(sf::st_intersection(ridges, sf::st_buffer(outline, -1500)))
ridges <- ridges[!sf::st_is_empty(ridges) & sf::st_geometry_type(ridges) %in% c("LINESTRING", "MULTILINESTRING"), ]
ridges <- sf::st_simplify(ridges, dTolerance = 400)

# SVG ---------------------------------------------------------------------------
width <- 520
height <- 600
hexagon <- function(margin) {
  # Corners of a pointy-top hexagon `margin` px inside the sticker edge
  r <- height / 2 - margin / cos(pi / 6)
  a <- pi / 2 + seq(0, 5) * pi / 3
  cbind(width / 2 + r * cos(a), height / 2 - r * sin(a))
}
points <- function(h) paste(sprintf("%.1f,%.1f", h[, 1], h[, 2]), collapse = " ")

# Fit the map into the upper part of the hexagon, keeping its aspect ratio
area <- c(x0 = 118, x1 = 402, y0 = 40, y1 = 384)
scale <- min((area[["x1"]] - area[["x0"]]) / (box[["xmax"]] - box[["xmin"]]),
             (area[["y1"]] - area[["y0"]]) / (box[["ymax"]] - box[["ymin"]]))
x_offset <- (area[["x0"]] + area[["x1"]]) / 2 - scale * (box[["xmin"]] + box[["xmax"]]) / 2
y_offset <- (area[["y0"]] + area[["y1"]]) / 2 + scale * (box[["ymin"]] + box[["ymax"]]) / 2
svg_path <- function(geometry, close = FALSE) {
  # One subpath per line or ring, from the coordinate table of any geometry
  xy <- sf::st_coordinates(geometry)
  part <- interaction(as.data.frame(xy[, grepl("^L", colnames(xy)), drop = FALSE]), drop = TRUE)
  pieces <- vapply(split(seq_len(nrow(xy)), part), function(i) {
    paste0("M", paste(sprintf("%.1f %.1f", x_offset + scale * xy[i, 1], y_offset - scale * xy[i, 2]), collapse = "L"), if (close) "Z" else "")
  }, "")
  paste(pieces, collapse = "")
}

flag <- c(black = "#000000", red = "#DD0000", gold = "#FFCE00")
ramp <- grDevices::colorRampPalette(c("#FFE27A", flag[["gold"]], "#FF8A00", flag[["red"]], "#8E0000"))(n_ridges)
ridge_paths <- vapply(seq_len(nrow(ridges)), function(i) {
  sprintf('<path d="%s" stroke="%s"/>', svg_path(sf::st_geometry(ridges)[i]), ramp[ridges$rank[i]])
}, "")

font <- "Avenir Next, Helvetica Neue, Helvetica, Arial, sans-serif"
svg <- c(
  sprintf('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">', width, height, width, height),
  "<title>pksR: Polizeiliche Kriminalstatistik</title>",
  "<defs>",
  '<radialGradient id="bg" cx="50%" cy="38%" r="72%"><stop offset="0" stop-color="#1F1F24"/><stop offset="1" stop-color="#08080A"/></radialGradient>',
  '<filter id="glow" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="1.3" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>',
  "</defs>",
  sprintf('<polygon points="%s" fill="url(#bg)" stroke="%s" stroke-width="9" stroke-linejoin="round"/>', points(hexagon(6)), flag[["gold"]]),
  sprintf('<path d="%s" fill="#000000" fill-opacity="0.35" stroke="%s" stroke-opacity="0.35" stroke-width="0.8"/>',
          svg_path(sf::st_simplify(outline, dTolerance = 1200), close = TRUE), flag[["gold"]]),
  sprintf('<g filter="url(#glow)" fill="none" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round">', ridge_width),
  ridge_paths,
  "</g>",
  sprintf('<text x="260" y="458" text-anchor="middle" font-family="%s" font-weight="700" font-size="74" letter-spacing="-1" fill="#FFFFFF">pksR</text>', font),
  # Flag bar; the black part gets a faint edge so it stays visible on the dark body
  sprintf('<rect x="%.1f" y="472" width="40" height="5" fill="%s"/>', 200 + (0:2) * 40, flag),
  '<rect x="200" y="472" width="40" height="5" fill="none" stroke="#3A3A40" stroke-width="0.8"/>',
  sprintf('<text x="260" y="502" text-anchor="middle" font-family="%s" font-weight="600" font-size="12.5" letter-spacing="2.2" fill="%s">POLIZEILICHE KRIMINALSTATISTIK</text>',
          font, flag[["gold"]]),
  "</svg>"
)
dir.create("man/figures", showWarnings = FALSE, recursive = TRUE)
writeLines(svg, "man/figures/logo.svg", useBytes = TRUE)

# 240 px wide is what pkgdown and the README show; 2x for sharp screens
status <- system2("rsvg-convert", c("-w", "480", "-o", "man/figures/logo.png", "man/figures/logo.svg"))
if (status != 0) stop("rsvg-convert failed.")
message(sprintf("Logo: %d districts, %d ridge pieces, svg %.0f KB, png %.0f KB", nrow(districts), nrow(ridges),
                file.size("man/figures/logo.svg") / 1024, file.size("man/figures/logo.png") / 1024))
