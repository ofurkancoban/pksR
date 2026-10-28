# List the harmonized offence keys

The district tables contain a selected subset of offence keys
(Straftatenschluessel). The harmonized keys used by
[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md)
are listed here with a short name and a label in German or English,
their parent key and the years they cover. Mappings and names marked
`status = "draft"` have not been reviewed yet.

## Usage

``` r
pks_offences(pattern = NULL, lang = NULL)
```

## Arguments

- pattern:

  Optional text to search for in the keys, short names and labels of
  both languages. Capitals, spaces and umlauts do not matter, so
  `"Diebstahl"`, `"theft"` and `"435*00"` all work.

- lang:

  Language of the `name` and `label` columns: `"de"` or `"en"`. `NULL`
  (default) uses `options(pksR.lang)`, otherwise the language of the R
  session.

## Value

A tibble with `offence_key`, `name` (the short name accepted by
`pks_get(offence = )`), `label`, `parent_key`, `valid_from`, `valid_to`,
`status` and `notes`.

## Details

The table is a snapshot of the offence map of pksR-data that ships with
the package, so it works offline. Each data release also contains its
own `offence_map.csv`, which
[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md)
uses.

## Deutsch

Listet die harmonisierten Straftatenschlüssel mit Kurzname, Bezeichnung
auf Deutsch oder Englisch, übergeordnetem Schlüssel und
Gültigkeitsjahren. `pattern` durchsucht Schlüssel, Kurznamen und
Bezeichnungen beider Sprachen; `lang` wählt die Sprache der Spalten
`name` und `label`. Zuordnungen mit `status = "draft"` sind noch nicht
geprüft.

## See also

Other metadata:
[`pks_breaks()`](https://ofurkancoban.github.io/pksR/reference/pks_breaks.md)

## Examples

``` r
pks_offences("Diebstahl", lang = "de")
#> # A tibble: 12 × 8
#>    offence_key name            label parent_key valid_from valid_to status notes
#>    <chr>       <chr>           <chr> <chr>           <int>    <int> <chr>  <chr>
#>  1 ****00      diebstahl       Dieb… ------           2014     2025 draft  NA   
#>  2 ***100      kraftwagendieb… Dieb… ****00           2013     2025 draft  NA   
#>  3 ***200      kraftrad_diebs… Dieb… ****00           2014     2025 draft  NA   
#>  4 ***300      fahrraddiebsta… Dieb… ****00           2014     2025 draft  NA   
#>  5 *26*00      ladendiebstahl  Lade… ****00           2023     2025 draft  New …
#>  6 *50*00      diebstahl_an_a… Dieb… ****00           2003     2025 draft  Defi…
#>  7 *90*00      taschendiebsta… Tasc… ****00           2014     2025 draft  NA   
#>  8 3***00      einfacher_dieb… Dieb… ****00           2014     2025 draft  NA   
#>  9 326*00      einfacher_lade… Einf… 3***00           2014     2025 draft  Also…
#> 10 4***00      schwerer_diebs… Dieb… ****00           2014     2025 draft  NA   
#> 11 435*00      wohnungseinbru… Wohn… 4***00           2003     2025 draft  Labe…
#> 12 436*00      tageswohnungse… Tage… 435*00           2013     2025 draft  Labe…
pks_offences("theft", lang = "en")
#> # A tibble: 7 × 8
#>   offence_key name             label parent_key valid_from valid_to status notes
#>   <chr>       <chr>            <chr> <chr>           <int>    <int> <chr>  <chr>
#> 1 ****00      theft            Thef… ------           2014     2025 draft  NA   
#> 2 ***100      car_theft        Thef… ****00           2013     2025 draft  NA   
#> 3 ***200      motorcycle_theft Thef… ****00           2014     2025 draft  NA   
#> 4 ***300      bicycle_theft    Thef… ****00           2014     2025 draft  NA   
#> 5 *50*00      theft_from_vehi… Thef… ****00           2003     2025 draft  Defi…
#> 6 3***00      simple_theft     Thef… ****00           2014     2025 draft  NA   
#> 7 4***00      aggravated_theft Thef… ****00           2014     2025 draft  NA   
```
