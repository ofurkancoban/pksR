# A small example panel

A subset of the harmonized panel of pksR-data that ships with the
package, for examples, tests and vignettes without internet access: five
districts, two offence keys and the years 2019 to 2025, harmonized to
the 2025 boundary with population weights, built from pksR-data commit
785ac02 (`data-raw/example.R`), not from a data release, so
`data_version` is `"example"`. Source: PKS Bundeskriminalamt,
Datenlizenz Deutschland, Namensnennung, Version 2.0; changed
(harmonized) by pksR-data.

## Usage

``` r
pks_example()
```

## Value

A tibble in the format of
[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md).

## Deutsch

Ein kleines Beispielpanel, das mit dem Paket ausgeliefert wird: fünf
Kreise, zwei Straftatenschlüssel und die Jahre 2019 bis 2025,
harmonisiert auf den Gebietsstand 2025. Es stammt aus einem lokalen Lauf
von pksR-data, nicht aus einer Datenveröffentlichung
(`data_version = "example"`). Quelle: PKS Bundeskriminalamt, Datenlizenz
Deutschland, Namensnennung, Version 2.0; verändert (harmonisiert).

## See also

Other data:
[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md)

## Examples

``` r
pks_example()
#> # A tibble: 70 × 22
#>     year ags   region_name   offence_key offence_key_published offence_label    
#>    <int> <chr> <chr>         <chr>       <chr>                 <chr>            
#>  1  2019 01001 Flensburg     ------      ------                Straftaten insge…
#>  2  2019 02000 Hamburg       ------      ------                Straftaten insge…
#>  3  2019 03159 Göttingen     ------      ------                Straftaten insge…
#>  4  2019 11000 Berlin        ------      ------                Straftaten insge…
#>  5  2019 16063 Wartburgkreis ------      ------                Straftaten insge…
#>  6  2019 01001 Flensburg     890000      890000                Straftaten insge…
#>  7  2019 02000 Hamburg       890000      890000                Straftaten insge…
#>  8  2019 03159 Göttingen     890000      890000                Straftaten insge…
#>  9  2019 11000 Berlin        890000      890000                Straftaten insge…
#> 10  2019 16063 Wartburgkreis 890000      890000                Straftaten insge…
#> # ℹ 60 more rows
#> # ℹ 16 more variables: cases <dbl>, attempts <dbl>, hz <dbl>, cleared <dbl>,
#> #   clearance_rate <dbl>, suspects <dbl>, cases_derived <dbl>,
#> #   cleared_derived <dbl>, population <dbl>, source_format <chr>,
#> #   source_file <chr>, boundary_year <int>, harmonized <lgl>,
#> #   weight_type <chr>, estimated <lgl>, derived_population <dbl>
```
