# Compare population and area weights

Districts that were split had to be divided between their successors, by
population (default) or by area. `pks_compare_weights()` puts both
versions of a harmonized panel side by side, so you can see where and
how much a result depends on that choice. Merged and unchanged districts
are the same under both weights.

## Usage

``` r
pks_compare_weights(data, other = NULL)
```

## Arguments

- data:

  A harmonized tibble from
  [`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md)
  (not `harmonize_to = NULL`), with population or area weights.

- other:

  `NULL` (default) to download the same years, offences, boundary and
  data version with the other weights, or that panel itself, for example
  when you have it already or work offline.

## Value

A tibble with one row per year, district and offence key: `year`, `ags`,
`region_name`, `offence_key`, `estimated` (split in at least one of the
two panels), `cases_population`, `cases_area`, `difference` (area minus
population), `relative_difference` (`difference / cases_population`),
`hz_population` and `hz_area` (recomputed with
[`pks_rates()`](https://ofurkancoban.github.io/pksR/reference/pks_rates.md)).
A message summarizes how many rows differ.

## Deutsch

Stellt eine harmonisierte Tabelle mit Bevölkerungs- und mit
Flächengewichten nebeneinander. Die Gewichte unterscheiden sich nur bei
geteilten Kreisen; so lässt sich prüfen, wie stark ein Ergebnis von
dieser Annahme abhängt. `other` kann die Tabelle mit den anderen
Gewichten liefern, sonst wird sie mit denselben Jahren, Straftaten,
demselben Gebietsstand und derselben Datenversion geladen.

## See also

Other analysis:
[`pks_rates()`](https://ofurkancoban.github.io/pksR/reference/pks_rates.md),
[`pks_validate()`](https://ofurkancoban.github.io/pksR/reference/pks_validate.md)

## Examples

``` r
if (FALSE) { # interactive()
d <- pks_get(years = 2005:2010, offence = "total")
w <- pks_compare_weights(d)
w[abs(w$relative_difference) > 0.01, ]
}
```
