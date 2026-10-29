# Known methodological breaks

Changes in the PKS that make values before and after a year incomparable
or only partly comparable: new offence definitions, key changes, changes
in the population denominator, boundary reforms and others. Check these
before interpreting changes over time.

## Usage

``` r
pks_breaks()
```

## Value

A tibble with `break_id`, `first_year`, `offence_key` (keys separated by
`;`, empty when all keys are affected), `variable`, `type`, `comparable`
(`yes`, `likely`, `unknown`, `no`), `description`, `evidence` and
`status`.

## Details

The table is a snapshot of `known_breaks.csv` of pksR-data that ships
with the package; each data release contains its own copy.

## Deutsch

Bekannte methodische Brüche der PKS: neue Definitionen, geänderte
Schlüssel, geänderte Bezugsbevölkerung, Gebietsreformen und andere.
`comparable` gibt an, ob Werte vor und nach dem Jahr vergleichbar sind
(`yes`, `likely`, `unknown`, `no`). Vor jeder Zeitreihe prüfen.

## See also

Other metadata:
[`pks_offences()`](https://ofurkancoban.github.io/pksR/reference/pks_offences.md)

## Examples

``` r
b <- pks_breaks()
b[b$comparable == "no", c("first_year", "offence_key", "description")]
#> # A tibble: 8 × 3
#>   first_year offence_key                        description                     
#>        <int> <chr>                              <chr>                           
#> 1       2010 220000;222000                      "The second PDF offence column …
#> 2       2013 NA                                 "HZ denominator based on Zensus…
#> 3       2024 NA                                 "HZ denominator based on Zensus…
#> 4       2017 111000                             "Three scopes in one key: 2014 …
#> 5       2018 621020;621021;621100;621110;621120 "621020 and 621021 (until 2017)…
#> 6       2012 *50*00                             "Theft in/from motor vehicles (…
#> 7       2024 730000;------;890000               "Cannabis Act (KCanG) in force …
#> 8       2016 980100                             "The list of component keys dis…
```
