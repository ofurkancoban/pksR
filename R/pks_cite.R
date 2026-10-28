#' Cite pksR, the data release and the data sources
#'
#' Work with these data should cite the package, the data release used (each
#' release is versioned and never changes) and the original sources. The
#' source data keep their terms of reuse: the PKS tables of the
#' Bundeskriminalamt and the BBSR crosswalk are licensed under the Data
#' licence Germany, attribution, version 2.0 (dl-de/by-2-0,
#' <https://www.govdata.de/dl-de/by-2-0>), which requires naming the source
#' and stating that the data were changed; the Destatis municipality
#' directory may be reproduced with a source note.
#'
#' @param version Data version such as `"2026.1"`, or `"latest"` (default).
#'   Without internet access, only the package and the sources are cited.
#' @return A [utils::bibentry()] object with one entry each for the package,
#'   the data release, the PKS, the BBSR crosswalk and the Destatis
#'   municipality directory. Print it, or convert it with `format(x, "bibtex")`.
#' @family releases
#' @export
#' @examplesIf interactive()
#' pks_cite()
#' format(pks_cite(), "bibtex")
pks_cite <- function(version = "latest") {
  author <- utils::person("\u00d6mer Furkan", "\u00c7oban")
  pkg_version <- as.character(utils::packageVersion("pksR"))
  entries <- list(utils::bibentry(
    "Manual",
    key = "pksR",
    title = "pksR: District-Level German Police Crime Statistics",
    author = author,
    year = format(Sys.Date(), "%Y"),
    note = paste("R package version", pkg_version),
    url = "https://github.com/ofurkancoban/pksR"
  ))

  m <- tryCatch(attr(pks_manifest(version), "manifest"), error = function(e) {
    cli::cli_warn(c("Cannot read the manifest of data version {.val {version}}; the data release is not cited.", "i" = conditionMessage(e)))
    NULL
  })
  years <- "2003 to the latest reporting year"
  if (!is.null(m)) {
    years <- paste(unlist(m$years), collapse = " to ")
    entries <- c(entries, list(utils::bibentry(
      "Misc",
      key = paste0("pksR-data-", m$data_version),
      title = sprintf("pksR-data: District-level German Police Crime Statistics, harmonized to the %s boundary", m$target_boundary_year),
      author = author,
      year = substr(m$created_at, 1, 4),
      note = paste0("Data version ", m$data_version, ", pipeline commit ", substr(m$pipeline_commit, 1, 7),
                    ". Contains data of the Bundeskriminalamt (dl-de/by-2-0), changed: harmonized and validated"),
      url = sprintf("https://github.com/%s/releases/tag/v%s", data_repo(), m$data_version),
      doi = m$zenodo_doi
    )))
  }

  entries <- c(entries, list(
    utils::bibentry(
      "Misc",
      key = "pks",
      title = paste0("Polizeiliche Kriminalstatistik (PKS), Kreis- und Bundesfalltabellen, Berichtsjahre ", years),
      author = utils::person("Bundeskriminalamt"),
      organization = "Bundeskriminalamt",
      address = "Wiesbaden",
      note = "PKS Bundeskriminalamt; table versions as listed in the data release. Datenlizenz Deutschland, Namensnennung, Version 2.0",
      url = "https://www.bka.de/DE/AktuelleInformationen/StatistikenLagebilder/PolizeilicheKriminalstatistik/pks_node.html",
      year = if (is.null(m)) format(Sys.Date(), "%Y") else substr(m$created_at, 1, 4)
    ),
    utils::bibentry(
      "Misc",
      key = "bbsr",
      title = "Umsteigeschl\u00fcssel f\u00fcr Kreise (ref-kreise)",
      author = utils::person("Bundesinstitut f\u00fcr Bau-, Stadt- und Raumforschung (BBSR)"),
      note = "BBSR Bonn. Datenlizenz Deutschland, Namensnennung, Version 2.0",
      url = "https://www.bbsr.bund.de",
      year = if (is.null(m)) format(Sys.Date(), "%Y") else substr(m$created_at, 1, 4)
    ),
    utils::bibentry(
      "Misc",
      key = "destatis",
      title = "Gemeindeverzeichnis, Namens- und Gebiets\u00e4nderungen",
      author = utils::person("Statistisches Bundesamt (Destatis)"),
      note = "Statistisches Bundesamt (Destatis), Gemeindeverzeichnis",
      url = "https://www.destatis.de",
      year = if (is.null(m)) format(Sys.Date(), "%Y") else substr(m$created_at, 1, 4)
    )
  ))
  do.call(c, entries)
}
