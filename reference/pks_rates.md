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

  `NULL` (default) to use the population in `data` (published where
  available, otherwise derived from cases and HZ), or a data frame with
  columns `year`, `ags` and `population`, for example from an official
  population source. Every row of `data` must find a population.

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

## Deutsch

Berechnet Häufigkeitszahl (Fälle je 100.000 Einwohner) und
Aufklärungsquote neu aus den Fallzahlen, etwa nach einer Harmonisierung,
bei der veröffentlichte Quoten nicht übertragen werden können.
`population` kann eine eigene Einwohnerzahl je Jahr und Kreis liefern;
`per` setzt den Nenner der neuen Spalte `rate`.

## See also

Other analysis:
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
```
