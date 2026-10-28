# List the harmonized offence keys

The district tables contain a selected subset of offence keys
(Straftatenschluessel). The harmonized keys used by
[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md)
are listed here with their German and English labels, their parent key
and the years they cover. Mappings marked `status = "draft"` have not
been reviewed yet.

## Usage

``` r
pks_offences(pattern = NULL, lang = c("de", "en"))
```

## Arguments

- pattern:

  Optional text to search for: an offence key (matched literally, so
  `"435*00"` works) or a regular expression matched against the labels,
  ignoring case.

- lang:

  Language of the `label` column: `"de"` (default) or `"en"`.

## Value

A tibble with `offence_key`, `label`, `parent_key`, `valid_from`,
`valid_to`, `status` and `notes`.

## Details

The table is a snapshot of the offence map of pksR-data that ships with
the package, so it works offline. Each data release also contains its
own `offence_map.csv`, which
[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md)
uses.

## See also

Other metadata:
[`pks_breaks()`](https://ofurkancoban.github.io/pksR/reference/pks_breaks.md)

## Examples

``` r
pks_offences("Diebstahl")
#> # A tibble: 12 × 7
#>    offence_key label                 parent_key valid_from valid_to status notes
#>    <chr>       <chr>                 <chr>           <int>    <int> <chr>  <chr>
#>  1 ****00      Diebstahl insgesamt   ------           2014     2025 draft  NA   
#>  2 ***100      Diebstahl insgesamt … ****00           2013     2025 draft  NA   
#>  3 ***200      Diebstahl insgesamt … ****00           2014     2025 draft  NA   
#>  4 ***300      Diebstahl insgesamt … ****00           2014     2025 draft  NA   
#>  5 *26*00      Ladendiebstahl insge… ****00           2023     2025 draft  New …
#>  6 *50*00      Diebstahl insgesamt … ****00           2003     2025 draft  Defi…
#>  7 *90*00      Taschendiebstahl ins… ****00           2014     2025 draft  NA   
#>  8 3***00      Diebstahl ohne ersch… ****00           2014     2025 draft  NA   
#>  9 326*00      Einfacher Ladendiebs… 3***00           2014     2025 draft  Also…
#> 10 4***00      Diebstahl unter ersc… ****00           2014     2025 draft  NA   
#> 11 435*00      Wohnungseinbruchdieb… 4***00           2003     2025 draft  Labe…
#> 12 436*00      Tageswohnungseinbruc… 435*00           2013     2025 draft  Labe…
pks_offences("theft", lang = "en")
#> # A tibble: 7 × 7
#>   offence_key label                  parent_key valid_from valid_to status notes
#>   <chr>       <chr>                  <chr>           <int>    <int> <chr>  <chr>
#> 1 ****00      Theft, total           ------           2014     2025 draft  NA   
#> 2 ***100      Theft of motor cars, … ****00           2013     2025 draft  NA   
#> 3 ***200      Theft of mopeds and m… ****00           2014     2025 draft  NA   
#> 4 ***300      Theft of bicycles, to… ****00           2014     2025 draft  NA   
#> 5 *50*00      Theft of parts from a… ****00           2003     2025 draft  Defi…
#> 6 3***00      Theft without aggrava… ****00           2014     2025 draft  NA   
#> 7 4***00      Theft under aggravati… ****00           2014     2025 draft  NA   
```
