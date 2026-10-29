# Builds the hex logo man/figures/logo.svg and man/figures/logo.png.
# Usage (from the package root):
#   Rscript data-raw/logo.R <VG250_KRS.shp> <pks_kreis_2025_published.csv.gz>
#
# The logo is Germany as a fingerprint drawn by the PKS data of 2025. It is a
# portrait of the regional pattern, not a map at district resolution:
# 1. Every point of a 2.5 km grid takes the log HZ of total offences of the
#    district it lies in.
# 2. The values are smoothed with a Gaussian kernel (sigma 45 km), using land
#    points only, so the sea does not pull coastal values down. Large rural
#    districts weigh more than small cities (area weighting).
# 3. The ridges are 52 contour lines, evenly spaced on the log scale between
#    the 0.5th and 99.5th percentile of the surface: each ridge is about 1.7
#    percent higher in HZ than the one below.
# 4. Each ridge is coloured by its level, from yellow (low HZ) over orange to
#    red (high HZ), evenly on the same log scale.
# The short breaks in the ridges are decoration (fixed seed), not data.
#
# Geometries: BKG VG250 as of 1 January 2020 (401 districts), with Eisenach
# (16056) merged into the Wartburgkreis (16063) as on 1 July 2021; the codes
# then match the 2025 table one to one. Source note required by dl-de/by-2-0:
# "(c) GeoBasis-DE / BKG 2025 (Daten veraendert)", see README.
# The PNG is rendered with rsvg-convert (librsvg), which must be on the PATH.
# In logo.svg the lettering is converted to outlines, so it looks the same on
# systems without Avenir Next. logo.png is rendered from the same drawing with
# real text, because font hinting keeps the small subtitle crisp. The font
# file ships with macOS and is not part of the package.
# It is not reduced to a colour palette: that shifts the flag colours.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("Usage: Rscript data-raw/logo.R <VG250_KRS.shp> <pks_kreis_2025_published.csv.gz>")

cell <- 2500        # grid spacing of the surface, metres
sigma <- 45000      # Gaussian smoothing, metres; large values give fingerprint-like ridges
n_ridges <- 52      # number of contour lines
ridge_width <- 1.35
set.seed(2025)      # fixed breaks in the ridges, so every build is identical

# Districts with their 2025 HZ -------------------------------------------------
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

# Smooth surface of log HZ -------------------------------------------------------
box <- sf::st_bbox(outline)
pad <- 3 * sigma
xs <- seq(box[["xmin"]] - pad, box[["xmax"]] + pad, by = cell)
ys <- seq(box[["ymin"]] - pad, box[["ymax"]] + pad, by = cell)
grid <- sf::st_as_sf(expand.grid(x = xs, y = ys), coords = c("x", "y"), crs = sf::st_crs(districts))
hit <- vapply(sf::st_intersects(grid, districts), function(i) if (length(i)) i[1] else NA_integer_, 1L)
value <- matrix(log(as.numeric(districts$hz))[hit], nrow = length(xs))
land <- !is.na(value)
value[!land] <- 0
# Masked Gaussian smoothing, separable in x and y
gauss <- function(n) outer(seq_len(n), seq_len(n), function(a, b) exp(-((a - b) * cell)^2 / (2 * sigma^2)))
kx <- gauss(length(xs))
ky <- gauss(length(ys))
surface <- (kx %*% value %*% t(ky)) / pmax(kx %*% (land * 1) %*% t(ky), 1e-9)

# Ridges: evenly spaced contour lines ----------------------------------------------
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
if (anyNA(ridges$rank)) stop("Every ridge needs its level.")
# Only tones between the flag gold and the flag red; the gold is a little
# deeper than FFCE00 so the thin low ridges stay visible on white
ramp <- grDevices::colorRampPalette(c("#F2B800", "#F08C00", "#E85A00", "#DD0000"))(n_ridges)
message(sprintf("Ridges from HZ %.0f (yellow) to %.0f (red), %.1f percent per ridge",
                exp(range_land[1]), exp(range_land[2]), 100 * (exp(diff(levels[1:2])) - 1)))

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

# Fit the map inside the hexagon (with a margin) and above the lockup: start
# from the largest size and shrink until every outline point is inside
outline_xy <- sf::st_coordinates(sf::st_simplify(outline, dTolerance = 1200))[, 1:2]
inner <- sf::st_sfc(sf::st_polygon(list(rbind(hexagon(30), hexagon(30)[1, ]))))
inside_hex <- function(x, y) all(lengths(sf::st_intersects(sf::st_cast(sf::st_sfc(sf::st_multipoint(cbind(x, y))), "POINT"), inner)) > 0)
map_top <- 30
map_bottom <- 384
scale <- (map_bottom - map_top) / (box[["ymax"]] - box[["ymin"]])
repeat {
  x_offset <- width / 2 - scale * (box[["xmin"]] + box[["xmax"]]) / 2
  y_offset <- map_bottom + scale * box[["ymin"]]
  if (inside_hex(x_offset + scale * outline_xy[, 1], y_offset - scale * outline_xy[, 2])) break
  scale <- scale * 0.99
}
svg_path <- function(geometry, close = FALSE) {
  # One subpath per line or ring, from the coordinate table of any geometry
  xy <- sf::st_coordinates(geometry)
  part <- interaction(as.data.frame(xy[, grepl("^L", colnames(xy)), drop = FALSE]), drop = TRUE)
  pieces <- vapply(split(seq_len(nrow(xy)), part), function(i) {
    paste0("M", paste(sprintf("%.1f %.1f", x_offset + scale * xy[i, 1], y_offset - scale * xy[i, 2]), collapse = "L"), if (close) "Z" else "")
  }, "")
  paste(pieces, collapse = "")
}

# Ridge breaks like the ridge endings on a fingertip: long segments, short gaps
breaks <- function() paste(sprintf("%.1f %.1f", stats::runif(6, 25, 90), stats::runif(6, 2.8, 4.2)), collapse = " ")
ridge_paths <- vapply(seq_len(nrow(ridges)), function(i) {
  sprintf('<path d="%s" stroke="%s" stroke-dasharray="%s" stroke-dashoffset="%.1f"/>',
          svg_path(sf::st_geometry(ridges)[i]), ramp[ridges$rank[i]], breaks(), stats::runif(1, 0, 60))
}, "")

flag <- c(black = "#000000", red = "#DD0000", gold = "#FFCE00")
font <- "/System/Library/Fonts/Avenir Next.ttc"
if (!file.exists(font)) stop("Avenir Next not found; the lettering needs ", font)
face <- c(bold = 0L, medium = 5L)   # face indices inside the font collection
text_path <- function(text, face, size, x, y, fill, spacing = 0) {
  # Lettering as one path: glyphs placed with the font's own kerning, plus
  # extra spacing per letter as letter-spacing would add it. The outlines are
  # flattened to lines at 200 px and scaled down, so the curves stay smooth
  # even in the small subtitle (at its own size they look visibly soft).
  glyphs <- textshaping::shape_text(text, path = font, index = face, size = size)$shape
  outline <- systemfonts::glyph_outline(glyphs$index, font, face, size = 200)
  k <- size / 200
  left <- x + glyphs$x_offset + (seq_len(nrow(glyphs)) - 1) * spacing
  contours <- split(outline, list(outline$glyph, outline$contour), drop = TRUE)
  d <- vapply(contours, function(p) {
    paste0("M", paste(sprintf("%.2f %.2f", left[p$glyph[1]] + k * p$x, y - k * p$y), collapse = "L"), "Z")
  }, "")
  sprintf('<path d="%s" fill="%s"/>', paste(d, collapse = ""), fill)
}
bar_x <- width / 2 - 84
lettering <- list(
  list(text = "pksR", face = "bold", weight = 700, size = 66, x = bar_x + 19, y = 446, fill = "#151515", spacing = -1.5),
  list(text = "Polizeiliche", face = "medium", weight = 500, size = 16.5, x = bar_x + 21, y = 482, fill = "#3C3C3C", spacing = 0),
  list(text = "Kriminalstatistik", face = "medium", weight = 500, size = 16.5, x = bar_x + 21, y = 501, fill = "#3C3C3C", spacing = 0)
)
as_paths <- vapply(lettering, function(l) text_path(l$text, face[[l$face]], l$size, l$x, l$y, l$fill, l$spacing), "")
as_text <- vapply(lettering, function(l) {
  sprintf('<text x="%.1f" y="%d" font-family="Avenir Next" font-weight="%d" font-size="%s" letter-spacing="%s" fill="%s">%s</text>',
          l$x, l$y, l$weight, l$size, l$spacing, l$fill, l$text)
}, "")
logo <- function(letters) c(
  sprintf('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">', width, height, width, height),
  "<title>pksR: Polizeiliche Kriminalstatistik</title>",
  # Edge in the flag colours, from the inside out: black, red, gold
  sprintf('<polygon points="%s" fill="%s"/>', points(hexagon(0)), flag[["gold"]]),
  sprintf('<polygon points="%s" fill="%s"/>', points(hexagon(6)), flag[["red"]]),
  sprintf('<polygon points="%s" fill="%s"/>', points(hexagon(11)), flag[["black"]]),
  sprintf('<polygon points="%s" fill="#FFFFFF"/>', points(hexagon(16))),
  # Faint fill of Germany without an outline: the ridges draw the border
  sprintf('<path d="%s" fill="#000000" fill-opacity="0.03"/>', svg_path(sf::st_simplify(outline, dTolerance = 1200), close = TRUE)),
  sprintf('<g fill="none" stroke-width="%.2f" stroke-linecap="round" stroke-linejoin="round">', ridge_width),
  ridge_paths,
  "</g>",
  # Lockup: vertical flag bar, the name, and the full title in two lines
  sprintf('<rect x="%.1f" y="%d" width="7" height="34" fill="%s"/>', bar_x, 398 + (0:2) * 34, flag),
  letters,
  "</svg>"
)
dir.create("man/figures", showWarnings = FALSE, recursive = TRUE)
writeLines(logo(as_paths), "man/figures/logo.svg", useBytes = TRUE)

# 240 px wide is what pkgdown and the README show; 4x stays sharp on high
# density screens and when the logo is shown larger, such as on slides
with_text <- tempfile(fileext = ".svg")
writeLines(logo(as_text), with_text, useBytes = TRUE)
status <- system2("rsvg-convert", c("-w", "960", "-o", "man/figures/logo.png", with_text))
# Large copy for print and stickers; kept out of the package by .Rbuildignore
status <- status + system2("rsvg-convert", c("-w", "2000", "-o", "man/figures/logo-2000.png", with_text))
unlink(with_text)
if (status != 0) stop("rsvg-convert failed.")
message(sprintf("Logo: %d ridge pieces, svg %.0f KB, png %.0f KB, print png %.0f KB", nrow(ridges),
                file.size("man/figures/logo.svg") / 1024, file.size("man/figures/logo.png") / 1024,
                file.size("man/figures/logo-2000.png") / 1024))
