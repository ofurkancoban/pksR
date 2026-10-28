# Getting started with pksR

`pksR` reads the district (Kreis) tables of the German Police Crime
Statistics (*Polizeiliche Kriminalstatistik*, PKS) of the
Bundeskriminalamt (BKA) from versioned data releases. This vignette
shows the main functions and describes the columns. The examples that
need the internet are shown but not run here; the others use
[`pks_example()`](https://ofurkancoban.github.io/pksR/reference/pks_example.md),
a small panel that ships with the package.

``` r

library(pksR)
```

## Getting data

[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md)
downloads the years you ask for from the latest data release, checks
every file against its SHA-256 checksum and keeps it in a local cache:

``` r

# Total offences, harmonized to the latest boundary (the default)
total <- pks_get(offence = "total")

# Offences by key, short name or label, in English or German
burglary <- pks_get(offence = c("residential_burglary", "einbruch"), lang = "en")

# Two years as published by the BKA, all offence keys
published <- pks_get(years = 2024:2025, harmonize_to = NULL)

# A fixed data release, for reproducible work
d <- pks_get(years = 2015:2025, version = "2026.1")
```

The three choices of `harmonize_to`:

| `harmonize_to` | Result |
|----|----|
| `"latest"` (default) | Harmonized to the boundary of the release, read as released |
| a year, e.g. `2016` | The data as published, harmonized to that year’s boundary in your session (forward only) |
| `NULL` | As published: each year with the districts of its own boundary |

See
[`vignette("harmonization")`](https://ofurkancoban.github.io/pksR/articles/harmonization.md)
for the methods and their assumptions.

## Choosing offences

`offence` takes, for each element, an offence key (`"435*00"`), a short
name (`"residential_burglary"`, or the German `"wohnungseinbruch"`), a
full label in either language, or a part of a label (`"einbruch"`
selects both burglary keys and says so). Capitals, spaces and umlauts do
not matter, and an exact key, name or label wins over a part.
[`pks_offences()`](https://ofurkancoban.github.io/pksR/reference/pks_offences.md)
lists all keys with their names; the names are drafts until the
maintainer has reviewed them.

## Languages

Messages and offence labels come in English or German:
`options(pksR.lang = "de")`, or `lang = "de"` in
[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md)
and
[`pks_offences()`](https://ofurkancoban.github.io/pksR/reference/pks_offences.md).
Without either, the language of the R session decides. A German version
of this vignette is
[`vignette("pksR-de")`](https://ofurkancoban.github.io/pksR/articles/pksR-de.md).

## The example panel

``` r

d <- pks_example()
d[, c("year", "ags", "region_name", "offence_key", "cases", "hz", "harmonized")]
#> # A tibble: 70 × 7
#>     year ags   region_name   offence_key   cases     hz harmonized
#>    <int> <chr> <chr>         <chr>         <dbl>  <dbl> <lgl>     
#>  1  2019 01001 Flensburg     ------        8617   9628. FALSE     
#>  2  2019 02000 Hamburg       ------      206790  11231. FALSE     
#>  3  2019 03159 Göttingen     ------       20829   6349. FALSE     
#>  4  2019 11000 Berlin        ------      513426  14086. FALSE     
#>  5  2019 16063 Wartburgkreis ------        7264.  4397. TRUE      
#>  6  2019 01001 Flensburg     890000        8335   9312. FALSE     
#>  7  2019 02000 Hamburg       890000      199833  10854. FALSE     
#>  8  2019 03159 Göttingen     890000       20571   6270. FALSE     
#>  9  2019 11000 Berlin        890000      495091  13583. FALSE     
#> 10  2019 16063 Wartburgkreis 890000        7222.  4372. TRUE      
#> # ℹ 60 more rows
```

Every object carries its provenance as attributes:

``` r

attributes(d)[c("data_version", "boundary_year", "weights")]
#> $data_version
#> [1] "example"
#> 
#> $boundary_year
#> [1] 2025
#> 
#> $weights
#> [1] "population"
```

For data from
[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md),
`data_version` is the release version, `retrieved_at` the time of
download and `source_urls` the release files the data came from.

## Columns

| Column | Content |
|----|----|
| `year` | Reporting year |
| `ags` | District code (Kreisschlüssel), 5 digits with leading zero, e.g. `"02000"` for Hamburg |
| `region_name` | District name as published, or the name at the target boundary for changed districts |
| `offence_key` | Offence key (Straftatenschlüssel); in harmonized data the harmonized key, see [`pks_offences()`](https://ofurkancoban.github.io/pksR/reference/pks_offences.md) |
| `offence_key_published` | Harmonized data only: the key as published, or `"KEY minus KEY"` for computed keys |
| `offence_label` | German label as published |
| `cases` | Recorded cases (published; `NA` in the PDF years 2003 to 2012) |
| `attempts` | Attempted cases |
| `hz` | Häufigkeitszahl: cases per 100,000 inhabitants |
| `cleared` | Cleared cases |
| `clearance_rate` | Aufklärungsquote in percent (0 where cases are 0, as in the BKA tables) |
| `suspects` | Suspects (persons; not additive over offence keys) |
| `cases_derived`, `cleared_derived` | PDF years only: `hz * population / 1e5`, because those tables print rates and population but no counts |
| `population` | Published population (PDF years and 2020) |
| `derived_population` | `cases / hz * 1e5`, derived from the published rate; one value per district and year |
| `source_format`, `source_file` | Format and file of the BKA source |
| `boundary_year` | Territorial boundary (Gebietsstand) of the row |
| `harmonized` | `TRUE` if the district was changed by harmonization |
| `weight_type` | `none`, `population` or `area` |
| `estimated` | `TRUE` for shares of split districts and for derived counts (PDF years) |

Counts in harmonized data are doubles: a split district passes fractions
of its cases to its successors, and rounding them would change the
national totals.

## Offence keys and breaks

``` r

pks_offences("theft", lang = "en")[, c("offence_key", "name", "label")]
#> # A tibble: 7 × 3
#>   offence_key name                label                                         
#>   <chr>       <chr>               <chr>                                         
#> 1 ****00      theft               Theft, total                                  
#> 2 ***100      car_theft           Theft of motor cars, total, incl. unauthorize…
#> 3 ***200      motorcycle_theft    Theft of mopeds and motorcycles, total, incl.…
#> 4 ***300      bicycle_theft       Theft of bicycles, total, incl. unauthorized …
#> 5 *50*00      theft_from_vehicles Theft of parts from and items out of motor ve…
#> 6 3***00      simple_theft        Theft without aggravating circumstances       
#> 7 4***00      aggravated_theft    Theft under aggravating circumstances
```

The district tables contain only a selected set of offence keys, and
keys change over time. Before reading a time series, check the known
methodological breaks:

``` r

b <- pks_breaks()
b[b$comparable == "no", c("first_year", "offence_key", "type")]
#> # A tibble: 8 × 3
#>   first_year offence_key                        type       
#>        <int> <chr>                              <chr>      
#> 1       2010 220000;222000                      key_change 
#> 2       2013 NA                                 denominator
#> 3       2024 NA                                 denominator
#> 4       2017 111000                             definition 
#> 5       2018 621020;621021;621100;621110;621120 key_change 
#> 6       2012 *50*00                             definition 
#> 7       2024 730000                             law_change 
#> 8       2016 980100                             definition
```

## Rates, checks and citation

After filtering or harmonizing, recompute rates from the counts and run
the checks:

``` r

r <- pks_rates(d, per = 1000)
head(r[, c("year", "ags", "offence_key", "cases", "rate")])
#> # A tibble: 6 × 5
#>    year ags   offence_key   cases  rate
#>   <int> <chr> <chr>         <dbl> <dbl>
#> 1  2019 01001 ------        8617   96.3
#> 2  2019 02000 ------      206790  112. 
#> 3  2019 03159 ------       20829   63.5
#> 4  2019 11000 ------      513426  141. 
#> 5  2019 16063 ------        7264.  44.0
#> 6  2019 01001 890000        8335   93.1
pks_validate(d)
#> Validation: 6 passed, 0 warnings, 0 failed.
#> # A tibble: 6 × 4
#>   check       status problems details
#>   <chr>       <chr>     <int> <chr>  
#> 1 schema      pass          0 ""     
#> 2 uniqueness  pass          0 ""     
#> 3 city_states pass          0 ""     
#> 4 coverage    pass          0 ""     
#> 5 counts      pass          0 ""     
#> 6 population  pass          0 ""
```

Work with these data should cite the package, the data release and the
sources.
[`pks_cite()`](https://ofurkancoban.github.io/pksR/reference/pks_cite.md)
returns all five entries, including the licence of the BKA data
(Datenlizenz Deutschland, Namensnennung, Version 2.0):

``` r

pks_cite()
```

## Cache

Downloads are kept below `tools::R_user_dir("pksR", "cache")`, one
folder per data version. A release never changes, so a cached file is
used until its checksum fails.

``` r

pks_cache_info()
pks_cache_clear(version = "2026.1")
```
