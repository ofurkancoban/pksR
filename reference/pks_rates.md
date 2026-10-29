# Recompute rates

Rates cannot be harmonized: when districts are merged or split, the
published frequency (Haeufigkeitszahl, cases per 100,000 inhabitants)
and clearance rate of the old districts do not carry over. `pks_rates()`
recomputes them from the counts, with the population of the data or one
you supply.

## Usage

``` r
pks_rates(data, population = NULL, per = 1e+05)
```

## Arguments

- data:

  A tibble from
  [`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md).

- population:

  `NULL` (default) to use the population behind the published HZ
  (published where available, otherwise derived from cases and HZ);
  `"corrected"` for the census-corrected population in column
  `population_corrected`; or a data frame with columns `year`, `ags` and
  `population`, for example from an official population source. Every
  row of `data` must find a population.

- per:

  Rate denominator for column `rate` (default 100,000).

## Value

`data` with `hz` (cases per 100,000) and `clearance_rate` recomputed,
and a new column `rate` (cases per `per`). The population used is in
column `rate_population`.

## Details

Cases come from `cases`, or from `cases_derived` in the PDF years, where
the BKA printed only rates. The clearance rate is 0 where cases are 0,
as in the BKA tables.

The BKA divides by the population of 31 December of the year before, on
the census base of its time: older registers until 2012, Zensus 2011 for
2013 to 2023, Zensus 2022 from 2024. Rates therefore jump in 2013 and
2024 without any change in crime (see
[`pks_breaks()`](https://ofurkancoban.github.io/pksR/reference/pks_breaks.md)).
With `population = "corrected"` every year uses the census-corrected
population of the BBSR (INKAR), at the same date and on the same
boundary, so rates are on one base over the whole period.

## Deutsch

Berechnet Häufigkeitszahl (Fälle je 100.000 Einwohner) und
Aufklärungsquote neu aus den Fallzahlen, etwa nach einer Harmonisierung,
bei der veröffentlichte Quoten nicht übertragen werden können.
`population` kann eine eigene Einwohnerzahl je Jahr und Kreis liefern;
`per` setzt den Nenner der neuen Spalte `rate`. Das BKA teilt durch die
Einwohnerzahl zum 31.12. des Vorjahres auf der Zensusbasis ihrer Zeit,
daher springen die Quoten 2013 und 2024. `population = "corrected"`
nutzt für alle Jahre die zensuskorrigierte Einwohnerzahl des BBSR
(INKAR) und macht die Quoten über den ganzen Zeitraum vergleichbar.

## See also

Other analysis:
[`pks_compare_weights()`](https://ofurkancoban.github.io/pksR/reference/pks_compare_weights.md),
[`pks_validate()`](https://ofurkancoban.github.io/pksR/reference/pks_validate.md)

## Examples

``` r
d <- pks_example()
pks_rates(d, per = 1000)[, c("year", "ags", "cases", "hz", "rate")]
#> # A tibble: 70 × 5
#>     year ags     cases     hz  rate
#>    <int> <chr>   <dbl>  <dbl> <dbl>
#>  1  2019 01001   8617   9628.  96.3
#>  2  2019 02000 206790  11231. 112. 
#>  3  2019 03159  20829   6349.  63.5
#>  4  2019 11000 513426  14086. 141. 
#>  5  2019 16063   7264.  4397.  44.0
#>  6  2019 01001   8335   9312.  93.1
#>  7  2019 02000 199833  10854. 109. 
#>  8  2019 03159  20571   6270.  62.7
#>  9  2019 11000 495091  13583. 136. 
#> 10  2019 16063   7222.  4372.  43.7
#> # ℹ 60 more rows

# One census base for all years
pks_rates(d, population = "corrected")[, c("year", "ags", "hz", "rate_population")]
#> # A tibble: 70 × 4
#>     year ags       hz rate_population
#>    <int> <chr>  <dbl>           <dbl>
#>  1  2019 01001  9383.          91838 
#>  2  2019 02000 11467.        1803349 
#>  3  2019 03159  6354.         327807 
#>  4  2019 11000 14394.        3566936 
#>  5  2019 16063  4449.         163267.
#>  6  2019 01001  9076.          91838 
#>  7  2019 02000 11081.        1803349 
#>  8  2019 03159  6275.         327807 
#>  9  2019 11000 13880.        3566936 
#> 10  2019 16063  4424.         163267.
#> # ℹ 60 more rows
```
