# Read the manifest of a data release

The manifest describes one data release: when and from which pipeline
commit it was built, the years and target boundary year it covers, the
validation result, and every file with its SHA-256, size and number of
rows.

## Usage

``` r
pks_manifest(version = "latest")
```

## Arguments

- version:

  Data version such as `"2026.1"`, or `"latest"`.

## Value

A tibble with one row per release file (`name`, `sha256`, `bytes`,
`rows`). The other manifest fields (`data_version`, `created_at`,
`pipeline_commit`, `target_boundary_year`, `years`, `validation`,
`notes`, `license`, `attribution`, ...) are attached as attribute
`manifest`.

## See also

Other releases:
[`pks_cite()`](https://ofurkancoban.github.io/pksR/reference/pks_cite.md),
[`pks_versions()`](https://ofurkancoban.github.io/pksR/reference/pks_versions.md)

## Examples

``` r
if (FALSE) { # interactive()
m <- pks_manifest()
attr(m, "manifest")$target_boundary_year
}
```
