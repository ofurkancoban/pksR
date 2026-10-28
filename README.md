# pksR: District-Level German Police Crime Statistics

[Deutsch](README.de.md)

`pksR` gives R users the district (Kreis) tables of the German Police Crime Statistics (*Polizeiliche Kriminalstatistik*, PKS) published by the Bundeskriminalamt, from 2003 onwards: as published, or harmonized to one territorial boundary and offence classification.

The data come from versioned, validated releases of [pksR-data](https://github.com/ofurkancoban/pksR-data), the pipeline that downloads the original BKA files, extracts and harmonizes them and checks every release. `pksR` downloads only the years you ask for, keeps them in a local cache and checks every file against the SHA-256 checksums of the release.

Not to be confused with the CRAN package `pks` (probabilistic knowledge structures).

## Installation

```r
# install.packages("remotes")
remotes::install_github("ofurkancoban/pksR")
```

## Usage

```r
library(pksR)

# Total offences in every district, harmonized to the latest boundary
total <- pks_get(offence = "total")

# Offences by key, short name or label, in English or German
burglary <- pks_get(offence = c("burglary", "435*00", "Wohnungseinbruchdiebstahl"))

# As published by the BKA, two years
published <- pks_get(years = 2024:2025, harmonize_to = NULL)

# Harmonized to another boundary year, with area weights for split districts
d <- pks_get(years = 2010:2015, harmonize_to = 2016, weights = "area")

# Rates recomputed after harmonization, with your own population if you like
rates <- pks_rates(d)

pks_offences("theft")       # offence keys, short names and labels
pks_breaks()                # known methodological breaks
pks_validate(d)             # consistency checks
pks_versions()              # available data releases
pks_cite()                  # how to cite package, data release and sources
```

## Languages

Messages, errors and offence labels are available in English and German. `options(pksR.lang = "de")` switches to German; otherwise the language of the R session is used. `pks_get()` and `pks_offences()` also take `lang = "de"` or `lang = "en"`. The vignettes and this README exist in both languages.

## Data releases

Every data release has a version (`2026.1`, `2026.2`, ...) and never changes; corrections become a new version. `pks_get(version = "2026.1")` gives the same data at any time later. Each release is validated before it is published: schema, one row per year, district and offence key, the expected number of districts, national totals, conservation of totals under harmonization and plausibility. See the [pksR-data README](https://github.com/ofurkancoban/pksR-data) for details.

## Sources and terms of reuse

The package code is MIT licensed. The data keep the terms of their sources:

- PKS tables: Bundeskriminalamt, [Datenlizenz Deutschland, Namensnennung, Version 2.0](https://www.govdata.de/dl-de/by-2-0). Source note: "PKS Bundeskriminalamt", reporting year, version.
- Crosswalk: [Bundesinstitut für Bau-, Stadt- und Raumforschung](https://www.bbsr.bund.de) (BBSR), Umsteigeschlüssel, Datenlizenz Deutschland, Namensnennung, Version 2.0. Source note: "BBSR Bonn".
- Municipality changes: Statistisches Bundesamt (Destatis), Gemeindeverzeichnis.

The harmonized data are changed data, not official BKA figures. `pks_cite()` returns the full citation.

## Author

Ömer Furkan Çoban
