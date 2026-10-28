# Inspect the local cache

Lists the release files that
[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md)
and
[`pks_manifest()`](https://ofurkancoban.github.io/pksR/reference/pks_manifest.md)
have stored in the cache directory,
`tools::R_user_dir("pksR", "cache")`.

## Usage

``` r
pks_cache_info()
```

## Value

A tibble with one row per cached file: `version`, `file`, `bytes` and
`modified`. The cache directory is attached as attribute `path`.

## Deutsch

Listet die im Cache (`tools::R_user_dir("pksR", "cache")`) gespeicherten
Dateien, je Datenversion.

## See also

Other cache:
[`pks_cache_clear()`](https://ofurkancoban.github.io/pksR/reference/pks_cache_clear.md)

## Examples

``` r
pks_cache_info()
#> ℹ Cache: /home/runner/.cache/R/pksR
#> ℹ 0 files, 0 B in 0 data versions.
#> # A tibble: 0 × 4
#> # ℹ 4 variables: version <chr>, file <chr>, bytes <dbl>, modified <dttm>
```
