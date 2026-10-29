# pksR: District-Level German Police Crime Statistics <img src="man/figures/logo.png" align="right" height="139" alt="pksR logo" />

**English** | [Deutsch](README.de.md)

<!-- badges: start -->
[![R-CMD-check](https://github.com/ofurkancoban/pksR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ofurkancoban/pksR/actions/workflows/R-CMD-check.yaml)
[![test-coverage](https://github.com/ofurkancoban/pksR/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/ofurkancoban/pksR/actions/workflows/test-coverage.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Project Status: WIP](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
<!-- badges: end -->

`pksR` gives R users the district (Kreis) tables of the German Police Crime Statistics (*Polizeiliche Kriminalstatistik*, PKS) of the Bundeskriminalamt (BKA) from 2003 onwards, either as published or harmonized to one territorial boundary and one offence classification, so that districts can be compared over time.

Not to be confused with the CRAN package `pks` (probabilistic knowledge structures).

## Why pksR

The BKA publishes the district tables once a year: as PDF yearbooks up to 2012 and as spreadsheets from 2013, each with its own layout and its own district boundaries. Districts were merged and split several times (Sachsen-Anhalt 2007, Sachsen 2008, Mecklenburg-Vorpommern 2011, Göttingen 2016, Eisenach 2021), and offence keys change. `pksR` does this work once, openly and reproducibly:

- **One table for all years.** One row per year, district and offence key, with the same columns and types in every year.
- **Harmonized boundaries.** Counts are moved to one boundary with the BBSR transition keys (population or area weights); rates are recomputed afterwards, never averaged.
- **Validated releases.** Every data release passes consistency checks before it is published (national totals, conservation of totals, coverage, plausibility).
- **Provenance.** Every file has a version and a SHA-256 checksum, and every row can be traced to the BKA file it came from.
- **English and German.** Messages, offence labels and documentation in both languages.

## Status

The package is under development and not yet on CRAN. **The first data release is being prepared.** Until it is published, `pks_get()` has no data to download; `pks_example()`, `pks_offences()` and `pks_breaks()` work already, without internet.

## Installation

```r
# install.packages("remotes")
remotes::install_github("ofurkancoban/pksR")
```

## Getting started

```r
library(pksR)

# Total offences in every district and year, harmonized to the latest boundary
total <- pks_get(offence = "total")

# Several offences at once: by short name, offence key or label
d <- pks_get(years = 2015:2025, offence = c("residential_burglary", "730000", "Gewaltkriminalität"))

# As published by the BKA: each year with its own districts
published <- pks_get(years = 2024:2025, harmonize_to = NULL)

# Harmonized to the boundary of 2016, area weights for split districts
d2016 <- pks_get(years = 2010:2015, harmonize_to = 2016, weights = "area")

# A fixed data release, for reproducible work
d <- pks_get(version = "2026.1", offence = "total")
```

Without internet, try the small example panel shipped with the package:

```r
d <- pks_example()
pks_rates(d, per = 1000)   # rates per 1,000 inhabitants
pks_validate(d)            # consistency checks
```

## Choosing offences

`offence` takes, for each element, one of:

| Form | Example | Result |
|---|---|---|
| Offence key | `"435*00"` | that key |
| Short name, English or German | `"residential_burglary"`, `"wohnungseinbruch"` | that key |
| Full label, either language | `"Residential burglary"` | that key |
| Part of a label | `"einbruch"` | every matching key, with a message saying which |

Capitals, spaces and umlauts do not matter, and an exact key, name or label always wins over a part. `pks_offences()` lists all keys:

```r
pks_offences("theft")              # search by name or label
pks_offences(lang = "de")          # German names and labels
```

Some common short names:

| Key | English | German |
|---|---|---|
| `------` | `total` | `insgesamt` |
| `****00` | `theft` | `diebstahl` |
| `435*00` | `residential_burglary` | `wohnungseinbruch` |
| `210000` | `robbery` | `raub` |
| `892000` | `violent_crime` | `gewaltkriminalitaet` |
| `674000` | `criminal_damage` | `sachbeschaedigung` |
| `730000` | `drug_offences` | `rauschgiftdelikte` |
| `899000` | `street_crime` | `strassenkriminalitaet` |

## What the data contain

- **Years:** 2003 to 2025; new years are added by the pipeline once the BKA publishes them.
- **Districts:** all districts and independent cities, 400 on the latest boundary; Berlin and Hamburg in every year.
- **Offences:** the 46 offence keys of the district tables. The tables contain a selection of keys that changes over time: 6 keys cover all years 2003 to 2025, 37 keys cover 2014 to 2025.
- **Measures:** cases, attempts, frequency rate (HZ, cases per 100,000 inhabitants), cleared cases, clearance rate and suspects.

All columns are described in `vignette("pksR")`.

## Things to keep in mind

- **2003 to 2012** come from PDF yearbooks that print rates and population but no case counts. Counts for these years are derived (`hz * population / 1e5`) and marked `estimated = TRUE`.
- **Split districts** are estimates: the weights assume that cases are distributed like inhabitants (or like area). Such rows are marked `estimated = TRUE`; merges are exact. `pks_compare_weights()` shows how much a panel changes between population and area weights.
- **Breaks:** offence definitions, laws and recording practice change. Check `pks_breaks()` before reading a time series.
- **Harmonized data are changed data**, not official BKA figures.

## Languages

`options(pksR.lang = "de")` switches messages and offence labels to German, `options(pksR.lang = "en")` to English; otherwise the language of the R session is used. `pks_get()` and `pks_offences()` also take `lang = "de"` or `lang = "en"`. Every help page has a German section.

## Documentation

The [package website](https://ofurkancoban.github.io/pksR/) has the reference and three articles, each in English and German:

| Article | English | German |
|---|---|---|
| Getting started | [pksR](https://ofurkancoban.github.io/pksR/articles/pksR.html) | [pksR-de](https://ofurkancoban.github.io/pksR/articles/pksR-de.html) |
| Harmonization: methods, assumptions and sensitivity | [harmonization](https://ofurkancoban.github.io/pksR/articles/harmonization.html) | [harmonization-de](https://ofurkancoban.github.io/pksR/articles/harmonization-de.html) |
| Data provenance and validation | [provenance](https://ofurkancoban.github.io/pksR/articles/provenance.html) | [provenance-de](https://ofurkancoban.github.io/pksR/articles/provenance-de.html) |

## Data releases and cache

The data are produced by [pksR-data](https://github.com/ofurkancoban/pksR-data), a pipeline that downloads the original BKA files, extracts, harmonizes and validates them, and publishes each result as a GitHub release.

- Every release has a version (`2026.1`, `2026.2`, ...) and never changes; corrections become a new version. `pks_versions()` lists them, `pks_manifest()` shows the files of one release.
- `pks_get()` downloads only the years you ask for and checks every file against the SHA-256 checksum in the release manifest.
- Downloads are cached in `tools::R_user_dir("pksR", "cache")`; `pks_cache_info()` and `pks_cache_clear()` manage the cache.
- Every result carries its provenance as attributes: `data_version`, `retrieved_at`, `boundary_year`, `weights` and `source_urls`.

## Citation

Please cite the package, the data release and the sources. `pks_cite()` returns all entries, including BibTeX:

```r
pks_cite()
pks_cite(version = "2026.1")
```

## Sources and terms of reuse

The package code is MIT licensed. The data keep the terms of their sources:

- **PKS tables:** Bundeskriminalamt, [Datenlizenz Deutschland, Namensnennung, Version 2.0](https://www.govdata.de/dl-de/by-2-0). Source note: "PKS Bundeskriminalamt", reporting year, version.
- **Crosswalk:** [Bundesinstitut für Bau-, Stadt- und Raumforschung](https://www.bbsr.bund.de) (BBSR), Umsteigeschlüssel, Datenlizenz Deutschland, Namensnennung, Version 2.0. Source note: "BBSR Bonn".
- **Municipality changes:** Statistisches Bundesamt (Destatis), Gemeindeverzeichnis.
- **Logo:** Germany as a fingerprint drawn by the PKS data of 2025 (PKS Bundeskriminalamt 2025). The ridges are contour lines of the frequency rate of total offences, smoothed over about 45 km; each ridge is about 1.7 percent higher than the one below and is coloured from yellow (low) to red (high). It is a portrait of the regional pattern, not a district map. District geometries: © [BKG](https://www.bkg.bund.de) (2025) [dl-de/by-2-0](https://www.govdata.de/dl-de/by-2-0), [Datenquellen](https://sgx.geodatenzentrum.de/web_public/gdz/datenquellen/datenquellen_vg_nuts.pdf); VG250 as of 1 January 2020, changed: Eisenach merged into the Wartburgkreis (2021), smoothed and drawn as contour lines. Built by `data-raw/logo.R`.

## Related packages

- [`inkaR`](https://CRAN.R-project.org/package=inkaR): regional indicators of the BBSR (INKAR), for example population and economic covariates for the same districts.
- [`ags`](https://CRAN.R-project.org/package=ags): BBSR crosswalks for German district codes.

## Contributing

Bug reports and suggestions are welcome in the [issue tracker](https://github.com/ofurkancoban/pksR/issues). Problems with the data themselves (a wrong value, a missing district) are best reported in the [pksR-data issues](https://github.com/ofurkancoban/pksR-data/issues). See the [contributing guide](.github/CONTRIBUTING.md) for pull requests and the [roadmap](ROADMAP.md) for planned work.

## Author

Ömer Furkan Çoban
