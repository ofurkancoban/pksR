# Detail columns and use cases

From data release 2026.2 on,
[`pks_get()`](https://ofurkancoban.github.io/pksR/de/reference/pks_get.md)
returns more than case counts and rates: the official name of every
district, the district type, cases in which a firearm was used, and
suspects by sex and nationality. This vignette describes these columns,
the rules for using them, and a few typical analyses. All runnable
examples use
[`pks_example()`](https://ofurkancoban.github.io/pksR/de/reference/pks_example.md),
a small panel that ships with the package (five districts, two offence
keys, 2019 to 2025), so they work without internet.

``` r

d <- pksR::pks_example()
```

## The columns

| Column | Content | Years |
|----|----|----|
| `region_name_official` | District name of the BBSR crosswalk at the boundary year of the row; one name per district in a harmonized panel | all |
| `district_type` | District type as published: `KfS` (kreisfreie Stadt), `LK` (Landkreis), `K` (Kreis), `SK` (Stadtkreis), `RV` (Regionalverband) | 2013 onwards |
| `firearm_threatened` | Cases in which the suspect threatened with a firearm | 2013 onwards |
| `firearm_fired` | Cases in which a firearm was fired | 2013 onwards |
| `suspects_male`, `suspects_female` | Suspects by sex; together they give `suspects` | 2013 onwards |
| `suspects_non_german` | Non-German suspects (*nichtdeutsche Tatverdächtige*) | 2013 onwards |

The yearbooks of 2003 to 2012 publish none of the detail fields, so they
are `NA` there. With data releases before 2026.2 all detail columns are
`NA`, and
[`pks_get()`](https://ofurkancoban.github.io/pksR/de/reference/pks_get.md)
says so once per session. The percentages printed in the BKA tables
(share of attempts, share of non-German suspects) are not included: they
follow from the counts, and a percentage cannot be moved to another
boundary with crosswalk weights, while counts can.

`region_name` stays the name as published, which changes in spelling
between years (“SK Mülheim a.d.Ruhr”, “KfS Mülheim an der Ruhr”).
`region_name_official` is the same for a district in every year of a
harmonized panel and is the better choice for labels in tables and maps:

``` r

unique(d[, c("ags", "region_name", "region_name_official", "district_type")])
#> # A tibble: 5 × 4
#>   ags   region_name   region_name_official          district_type
#>   <chr> <chr>         <chr>                         <chr>        
#> 1 01001 Flensburg     Flensburg, Stadt              KfS          
#> 2 02000 Hamburg       Hamburg, Freie und Hansestadt KfS          
#> 3 03159 Göttingen     Göttingen                     LK           
#> 4 11000 Berlin        Berlin, Stadt                 KfS          
#> 5 16063 Wartburgkreis Wartburgkreis                 LK
```

## Rules for the detail columns

1.  **Suspects are persons, not cases.** A person suspected of theft and
    of fraud counts under both keys, so suspect counts must never be
    summed over offence keys. Within one key they add up:
    `suspects_male + suspects_female` equals `suspects`. For keys that
    are computed as the difference of two published keys (`890000`
    in 2014) the suspect columns are `NA`.
2.  **Suspects are not offenders.** A *Tatverdächtiger* is a person the
    police consider sufficiently suspected when the investigation ends.
    The PKS says nothing about charges or convictions.
3.  **Non-German suspects are not only residents.** They include people
    without residence in Germany (tourists, commuters, travelling
    offenders) and offences that only non-Germans can commit, such as
    offences against the Residence and the Asylum Acts (key `725000`).
    Key `890000` (total offences excluding these) removes the second
    part. The PKS publishes no population by nationality; such
    denominators have to come from elsewhere, for example from INKAR
    through the package
    [`inkaR`](https://CRAN.R-project.org/package=inkaR).
4.  **Harmonized values can be fractional.** Where a district was split,
    counts are divided with population or area weights and the row has
    `estimated = TRUE`. Districts changed by harmonization get their
    type in the latest table.
5.  **Rates are recomputed, never averaged.**
    [`pks_rates()`](https://ofurkancoban.github.io/pksR/de/reference/pks_rates.md)
    recomputes the HZ for `cases`. Rates of the detail counts are
    computed the same way: sum the counts first, then divide by the
    population of the same rows.

## Use case 1: cities and rural districts

Compare crime in cities (`KfS`) and rural districts (`LK`). The rate of
a group is the sum of its cases over the sum of its population, not the
mean of the district rates:

``` r

tot <- d[d$offence_key == "------", ]
tot$pop <- dplyr::coalesce(tot$population, tot$derived_population)
by_type <- dplyr::summarise(
  dplyr::group_by(tot, year, district_type),
  cases = sum(cases), pop = sum(pop), .groups = "drop"
)
by_type$hz <- by_type$cases / by_type$pop * 1e5
by_type[by_type$year == 2025, ]
#> # A tibble: 2 × 5
#>    year district_type  cases     pop     hz
#>   <int> <chr>          <dbl>   <dbl>  <dbl>
#> 1  2025 KfS           720003 5644156 12757.
#> 2  2025 LK             30786  482985  6374.
```

In a full panel the same code gives the urban and rural series for all
of Germany from 2013 onwards.

## Use case 2: sex of the suspects

The share of female suspects by district and year:

``` r

tot$female_share <- round(tot$suspects_female / tot$suspects * 100, 1)
tot[tot$year %in% c(2019, 2025), c("year", "region_name_official", "suspects", "female_share")]
#> # A tibble: 10 × 4
#>     year region_name_official          suspects female_share
#>    <int> <chr>                            <dbl>        <dbl>
#>  1  2019 Flensburg, Stadt                 3450          23.5
#>  2  2019 Hamburg, Freie und Hansestadt   66216          22.5
#>  3  2019 Göttingen                        8774          24.8
#>  4  2019 Berlin, Stadt                  136704          26.4
#>  5  2019 Wartburgkreis                    3605.         23.5
#>  6  2025 Flensburg, Stadt                 3650          26.5
#>  7  2025 Hamburg, Freie und Hansestadt   64045          24  
#>  8  2025 Göttingen                        9703          25.4
#>  9  2025 Berlin, Stadt                  132281          25.9
#> 10  2025 Wartburgkreis                    3459          26.3
```

## Use case 3: non-German suspects with and without immigration offences

The share of non-German suspects depends on whether offences against the
Residence and Asylum Acts are counted. Comparing `------` (all offences)
with `890000` (without them) shows how much:

``` r

y25 <- d[d$year == 2025, ]
y25$non_german_share <- round(y25$suspects_non_german / y25$suspects * 100, 1)
wide <- merge(
  y25[y25$offence_key == "------", c("region_name_official", "non_german_share")],
  y25[y25$offence_key == "890000", c("region_name_official", "non_german_share")],
  by = "region_name_official", suffixes = c("_all", "_without_725000")
)
wide
#>            region_name_official non_german_share_all
#> 1                 Berlin, Stadt                 47.3
#> 2              Flensburg, Stadt                 35.8
#> 3                     Göttingen                 33.4
#> 4 Hamburg, Freie und Hansestadt                 52.9
#> 5                 Wartburgkreis                 22.0
#>   non_german_share_without_725000
#> 1                            43.3
#> 2                            34.5
#> 3                            32.3
#> 4                            47.4
#> 5                            21.9
```

A share of suspects is not a crime rate of a population group: for that,
the number of non-German suspects has to be divided by the non-German
population, which the PKS does not publish, and the caveats of rule 3
apply.

## Use case 4: firearm cases

Firearm cases are rare, so single district years are noisy. Pool several
years before computing a rate per 100,000 inhabitants:

``` r

pooled <- dplyr::summarise(
  dplyr::group_by(tot, region_name_official),
  threatened = sum(firearm_threatened), fired = sum(firearm_fired),
  person_years = sum(pop), .groups = "drop"
)
pooled$fired_per_100k <- pooled$fired / pooled$person_years * 1e5
pooled
#> # A tibble: 5 × 5
#>   region_name_official          threatened  fired person_years fired_per_100k
#>   <chr>                              <dbl>  <dbl>        <dbl>          <dbl>
#> 1 Berlin, Stadt                     2564   2427      25758774            9.42
#> 2 Flensburg, Stadt                    80     50        646022            7.74
#> 3 Göttingen                          154    115       2286819            5.03
#> 4 Hamburg, Freie und Hansestadt      913    649      13001128            4.99
#> 5 Wartburgkreis                       30.0   61.9     1115339.           5.55
```

## With the full data

The same columns come with every request to a data release from 2026.2
on, as published and harmonized:

``` r

# All districts, total offences, 2013 to 2025, harmonized to the latest boundary
panel <- pksR::pks_get(years = 2013:2025, offence = "total")

# As published: the districts and names of each year
published <- pksR::pks_get(years = 2013:2025, offence = "total", harmonize_to = NULL)

# Harmonized to another boundary year: the detail counts move with the
# crosswalk weights like the case counts
p2016 <- pksR::pks_get(years = 2013:2016, offence = "total", harmonize_to = 2016)
```

[`pks_validate()`](https://ofurkancoban.github.io/pksR/de/reference/pks_validate.md)
checks a panel; for the detail columns check in addition that
`suspects_male + suspects_female` equals `suspects` and that
`suspects_non_german` and the firearm counts do not exceed their totals.
The pipeline stops a release when one of these fails.

## Without R

The Parquet files of a release hold all columns. The per-year CSV files
keep the columns of release 2026.1 and have a twin
`pks_kreis_<year>_<variant>_details.csv.gz` with `year`, `ags`,
`offence_key` and the detail columns, in the same row order; join them
on these three columns. The official names come from `boundary_map.csv`
of the release (columns `to_name` of the last period for the latest
boundary).
