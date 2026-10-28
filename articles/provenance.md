# Data provenance and validation

Every number that `pksR` returns can be traced to a file published by
the Bundeskriminalamt, and every data release is validated before it is
published. This vignette describes the path from the BKA files to a data
release, and how to check where your data came from. A German version is
[`vignette("provenance-de")`](https://ofurkancoban.github.io/pksR/articles/provenance-de.md).

``` r

library(pksR)
```

## From the BKA files to a data release

The data releases are built by
[pksR-data](https://github.com/ofurkancoban/pksR-data), a pipeline run
on GitHub Actions:

1.  **Sources.** Every source file has one row in a registry, with its
    exact URL, the BKA page that links it, its SHA-256 checksum and the
    BKA table version. URLs are never built from templates. A download
    whose checksum differs from the registry is not used; when two
    downloads agree on a new checksum, the pipeline reports a
    republished file instead of releasing.
2.  **Extraction.** The PDF yearbooks (2003 to 2012) and the
    spreadsheets (2013 onwards) are extracted into one common schema
    with explicit types. Columns a year lacks are present as `NA`.
3.  **Harmonization.** Territorial and offence harmonization as
    described in
    [`vignette("harmonization")`](https://ofurkancoban.github.io/pksR/articles/harmonization.md).
4.  **Validation gate.** The release is built only if all checks pass
    (see below).
5.  **Release.** The files are published as an immutable GitHub release
    `v<year>.<n>` with a manifest.

## The manifest

The manifest of a release records what it contains and how it was made:

``` r

m <- pks_manifest("2026.1")
m                                  # files with SHA-256, size and rows
meta <- attr(m, "manifest")
meta$pipeline_commit               # the pipeline code that built it
meta$target_boundary_year          # boundary of the harmonized panel
meta$validation                    # result of the validation gate
meta$attribution                   # sources, licences, source notes
```

[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md)
checks every downloaded file against the SHA-256 in the manifest and
refuses a file that does not match. Releases never change:
`version = "2026.1"` returns the same data at any later time, and a
correction is published as a new version.

The registries of a release (`sources.csv`, `boundary_map.csv`,
`offence_map.csv`, `known_breaks.csv` and the source lists of the
national tables, the crosswalk and the municipal changes) are files of
the release too, so every mapping that went into the data can be
inspected.

## The validation gate

Before each release the pipeline checks:

| Check | Rule |
|----|----|
| Schema | All columns present with their types |
| Uniqueness | One row per year, district and offence key |
| Coverage | The expected number of districts for the boundary year; Berlin and Hamburg in every year |
| National totals | The sum over districts is consistent with the national (Bund) table of the same year and key, within a documented tolerance for cases without known place of offence |
| Conservation | Harmonization does not change the national total of any count or the population |
| Plausibility | No negative counts; attempts not above cases; median district population within 50,000 to 400,000 |
| Year completeness | Every registered year produces output |

If a check fails, nothing is published and an issue is opened with the
report. The result of the gate is part of the manifest (`validation`).

## Checking your own data

[`pks_validate()`](https://ofurkancoban.github.io/pksR/reference/pks_validate.md)
runs the checks that need only the panel, for example after filtering or
combining data:

``` r

d <- pks_example()
pks_validate(d)
#> Validation: 6 passed, 0 warnings, 0 failed.
#> # A tibble: 6 × 4
#>   check       status problems details
#>   <chr>       <chr>     <int> <chr>  
#> 1 schema      pass          0 ""     
#> 2 uniqueness  pass          0 ""     
#> 3 city_states pass          0 ""     
#> 4 coverage    pass          0 ""     
#> 5 counts      pass          0 ""     
#> 6 population  pass          0 ""

# A broken panel: Berlin removed
pks_validate(d[d$ags != "11000", ])
#> Validation: 5 passed, 0 warnings, 1 failed.
#> ! city_states: 2019: 11000 missing; 2020: 11000 missing; 2021: 11000 missing;
#>   2022: 11000 missing; 2023: 11000 missing; 2024: 11000 missing; 2025: 11000
#>   missing
#> # A tibble: 6 × 4
#>   check       status problems details                                           
#>   <chr>       <chr>     <int> <chr>                                             
#> 1 schema      pass          0 ""                                                
#> 2 uniqueness  pass          0 ""                                                
#> 3 city_states fail          7 "2019: 11000 missing; 2020: 11000 missing; 2021: …
#> 4 coverage    pass          0 ""                                                
#> 5 counts      pass          0 ""                                                
#> 6 population  pass          0 ""
```

## What the data are not

The harmonized data are changed data: values of changed districts are
computed from the published ones and are not official BKA figures.
Counts of the PDF years are derived from rounded rates. The district
tables contain only a selection of offence keys, and recording practice,
offence definitions and population denominators change over time
([`pks_breaks()`](https://ofurkancoban.github.io/pksR/reference/pks_breaks.md)).

## Terms of reuse and citation

The PKS tables and the BBSR crosswalk are licensed under the Datenlizenz
Deutschland, Namensnennung, Version 2.0
(<https://www.govdata.de/dl-de/by-2-0>), which requires naming the
source (“PKS Bundeskriminalamt”, reporting year, version) and stating
that data were changed. The Destatis municipality directory may be
reproduced with a source note.
[`pks_cite()`](https://ofurkancoban.github.io/pksR/reference/pks_cite.md)
returns citations for the package, the data release and all three
sources.
