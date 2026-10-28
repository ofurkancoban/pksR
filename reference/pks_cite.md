# Cite pksR, the data release and the data sources

Work with these data should cite the package, the data release used
(each release is versioned and never changes) and the original sources.
The source data keep their terms of reuse: the PKS tables of the
Bundeskriminalamt and the BBSR crosswalk are licensed under the Data
licence Germany, attribution, version 2.0 (dl-de/by-2-0,
<https://www.govdata.de/dl-de/by-2-0>), which requires naming the source
and stating that the data were changed; the Destatis municipality
directory may be reproduced with a source note.

## Usage

``` r
pks_cite(version = "latest")
```

## Arguments

- version:

  Data version such as `"2026.1"`, or `"latest"` (default). Without
  internet access, only the package and the sources are cited.

## Value

A [`utils::bibentry()`](https://rdrr.io/r/utils/bibentry.html) object
with one entry each for the package, the data release, the PKS, the BBSR
crosswalk and the Destatis municipality directory. Print it, or convert
it with `format(x, "bibtex")`.

## See also

Other releases:
[`pks_manifest()`](https://ofurkancoban.github.io/pksR/reference/pks_manifest.md),
[`pks_versions()`](https://ofurkancoban.github.io/pksR/reference/pks_versions.md)

## Examples

``` r
if (FALSE) { # interactive()
pks_cite()
format(pks_cite(), "bibtex")
}
```
