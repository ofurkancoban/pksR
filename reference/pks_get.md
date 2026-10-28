# Get district-level police crime statistics

Downloads the district (Kreis) tables of the German Police Crime
Statistics (PKS) from a versioned data release, as published by the
Bundeskriminalamt or harmonized to one territorial boundary and offence
classification. Files are cached and checked against the SHA-256
checksums of the release manifest.

## Usage

``` r
pks_get(
  years = NULL,
  offence_keys = NULL,
  harmonize_to = "latest",
  weights = c("population", "area"),
  version = "latest",
  source = c("release", "bka"),
  cache = TRUE
)
```

## Arguments

- years:

  Integer vector of reporting years, or `NULL` (default) for all years
  of the release.

- offence_keys:

  Character vector of offence keys (Straftatenschluessel), or `NULL`
  (default) for all. For harmonized data these are the harmonized keys
  listed by
  [`pks_offences()`](https://ofurkancoban.github.io/pksR/reference/pks_offences.md);
  for the data as published, the keys as printed in the BKA tables.

- harmonize_to:

  Target boundary year (Gebietsstand). `"latest"` (default) is the
  boundary of the release, read as released; another year harmonizes the
  data as published with the crosswalk of the release (forward only, so
  `years` must not be later than the target); `NULL` returns the data as
  published.

- weights:

  Weights for districts that were split: `"population"` (default) or
  `"area"`. Ignored for `harmonize_to = NULL`.

- version:

  Data version such as `"2026.1"`, or `"latest"` (default).

- source:

  `"release"` (default) reads a data release. `"bka"`, which will
  rebuild the spreadsheet years from the original BKA files, is not
  available yet.

- cache:

  Keep downloaded files in the cache (default `TRUE`). With `FALSE`,
  files go to a temporary directory and are removed with the R session.

## Value

A tibble with one row per year, district (`ags`) and offence key.
Columns are described in
[`vignette("pksR")`](https://ofurkancoban.github.io/pksR/articles/pksR.md).
Attributes: `data_version`, `retrieved_at`, `boundary_year`, `weights`
and `source_urls`.

## See also

Other data:
[`pks_example()`](https://ofurkancoban.github.io/pksR/reference/pks_example.md)

## Examples

``` r
if (FALSE) { # interactive()
# Total offences, harmonized to the latest boundary
total <- pks_get(offence_keys = "------")

# As published by the BKA, two years
published <- pks_get(years = 2024:2025, harmonize_to = NULL)
}
```
