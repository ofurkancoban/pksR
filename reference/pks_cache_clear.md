# Clear the local cache

Deletes cached release files, for all data versions or only for the ones
given. The files are downloaded again when they are next needed.

## Usage

``` r
pks_cache_clear(version = NULL, ask = interactive())
```

## Arguments

- version:

  Character vector of data versions to remove, such as `"2026.1"`, or
  `NULL` (default) for the whole cache.

- ask:

  Ask for confirmation before deleting. Defaults to `TRUE` in
  interactive sessions.

## Value

The removed files as a tibble like
[`pks_cache_info()`](https://ofurkancoban.github.io/pksR/reference/pks_cache_info.md),
invisibly.

## Deutsch

Löscht Dateien aus dem Cache, für alle oder für die angegebenen
Datenversionen. In interaktiven Sitzungen wird vorher nachgefragt.

## See also

Other cache:
[`pks_cache_info()`](https://ofurkancoban.github.io/pksR/reference/pks_cache_info.md)

## Examples

``` r
# \donttest{
pks_cache_clear(ask = FALSE)
#> Nothing to remove from the cache.
# }
```
