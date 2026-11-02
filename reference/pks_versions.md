# List the available data releases

Data releases are versioned and never change; a correction is published
as a new version. Versions are named `<year>.<n>`, for example
`"2026.1"`.

## Usage

``` r
pks_versions()
```

## Value

A tibble with one row per data release, newest first: `version`, `tag`,
`published_at`, `files`, `url` and `doi` (Zenodo DOI of the version,
`NA` until Zenodo has archived it).

## Deutsch

Listet die veröffentlichten Datenversionen, die neueste zuerst. Eine
Veröffentlichung ändert sich nie; Korrekturen erscheinen als neue
Version. Die Spalte `doi` enthält die Zenodo-DOI der Version.

## See also

Other releases:
[`pks_cite()`](https://ofurkancoban.github.io/pksR/reference/pks_cite.md),
[`pks_manifest()`](https://ofurkancoban.github.io/pksR/reference/pks_manifest.md)

## Examples

``` r
if (FALSE) { # interactive()
pks_versions()
}
```
