# Harmonization: methods, assumptions and sensitivity

German districts were merged and split several times since 2003, most of
them in the reforms of Sachsen-Anhalt (2007), Sachsen (2008) and
Mecklenburg-Vorpommern (2011). A district code in 2005 may not exist in
2025, and a district of 2025 may combine parts of several earlier ones.
Comparing districts over time therefore needs the data of every year on
one boundary (Gebietsstand). This vignette describes how `pksR` and its
data pipeline do that, and which assumptions the results rest on. A
German version is
[`vignette("harmonization-de")`](https://ofurkancoban.github.io/pksR/articles/harmonization-de.md).

``` r

library(pksR)
```

## The crosswalk

The territorial crosswalk comes from the transition keys
(Umsteigeschlüssel) of the Bundesinstitut für Bau-, Stadt- und
Raumforschung (BBSR). For every year it maps each district at 31
December of year *t* to the districts at 31 December of *t + 1*, with
two kinds of weights:

- **population**: the share of the district’s inhabitants that moves to
  each successor;
- **area**: the share of its area.

Each data release contains the crosswalk it used, `boundary_map.csv`,
with one row per year, source district and target district. Three kinds
of rows:

| `source` | Meaning |
|----|----|
| `bbsr` | Row of the BBSR file, unchanged |
| `manual` | Replaces a BBSR row that is wrong, with a reason (for example a source code error in the BBSR sheet 2011-2012, where a piece of Bernkastel-Wittlich `07231` is listed under Trier-Saarburg `07235`) |
| `destatis` | A transfer of a municipality between districts that BBSR omits, taken from the Destatis lists of municipal changes, with a reason |

Manual and Destatis rows that have not yet been reviewed by the
maintainer carry `status = "draft"`.

## The method

For a target boundary year *T*, the yearly steps are chained from each
year’s own boundary to *T*. Then, per year:

1.  **Counts are moved, rates are not.** Cases, attempts, cleared cases
    and suspects of each source district are multiplied by its weight
    and summed per target district. Rates cannot be moved: the HZ of a
    merged district is not the sum or the mean of the old HZs.
2.  **Rates are recomputed** for every changed district from the moved
    counts and the moved population: `hz = cases / population * 1e5`,
    `clearance_rate = cleared / cases * 100`. Districts that did not
    change keep the published values.
3.  **Totals are conserved.** The national total of every count and of
    the population is the same before and after harmonization, checked
    for every year and offence key.
4.  **Forward only.** Data are moved from older boundaries to newer
    ones. A request for an earlier target boundary than a year’s own
    boundary is refused.
5.  **Offence keys** are mapped to harmonized keys with the offence map
    of the release
    ([`pks_offences()`](https://ofurkancoban.github.io/pksR/reference/pks_offences.md)).
    A published key is never added to its parent or child key
    implicitly.

Merges are exact (weight 1). Splits are estimates: the weights assume
that cases are distributed like inhabitants (or like area) within the
old district. Rows that rest on such a share are marked
`estimated = TRUE`, as are the PDF years 2003 to 2012, whose counts are
derived from the published rates.

## Choosing the target boundary and weights

``` r

# Latest boundary, population weights: the released panel
latest <- pks_get(years = 2005:2015)

# Boundary of 2011, after the reform in Mecklenburg-Vorpommern
d2011 <- pks_get(years = 2005:2011, harmonize_to = 2011)

# Area weights instead of population weights
area <- pks_get(years = 2005:2015, weights = "area")
```

The latest boundary is read as released and is fastest. Other target
years are computed in your session from the data as published and the
crosswalk of the same release; for the latest boundary both ways give
the same panel (checked to 1e-10 on all years 2003 to 2025).

## Sensitivity

Every harmonized panel rests on two choices: the weights for split
districts, and harmonizing at all. Results that hold under every choice
rest less on the assumptions above.

### Population or area weights

The weights differ only where districts were split.
[`pks_compare_weights()`](https://ofurkancoban.github.io/pksR/reference/pks_compare_weights.md)
puts both versions of a panel side by side:

``` r

d <- pks_get(years = 2005:2012, offence = "total")
w <- pks_compare_weights(d)   # downloads the same request with area weights
w[abs(w$relative_difference) > 0.01, c("year", "ags", "region_name", "cases_population", "cases_area")]
```

The result has the cases and the recomputed HZ under both weights, the
difference and the relative difference. Merged and unchanged districts
are identical; national totals are the same under both weights. A
regression can be run twice, once on each column, to see whether a
coefficient moves:

``` r

w$log_hz_population <- log(w$hz_population)
w$log_hz_area <- log(w$hz_area)
# e.g. the same two-way fixed effects model on log_hz_population and on log_hz_area
```

### Harmonized or as published

Not harmonizing at all is the third choice. `harmonize_to = NULL` gives
each year with its own districts, an unbalanced panel: districts that
were merged or split appear and disappear, and no value is estimated.

``` r

published <- pks_get(years = 2005:2012, offence = "total", harmonize_to = NULL)
table(published$year)          # the number of districts changes with the reforms
harmonized <- pks_get(years = 2005:2012, offence = "total")
table(harmonized$year)         # the same 400 districts every year
```

Two common ways to use the published data:

- **Unbalanced panel:** all districts as published, with district fixed
  effects. A reformed district becomes a new unit after the reform.
- **Balanced panel of unchanged districts:** only districts whose code
  and area did not change over the period. Nothing is estimated, but the
  reformed regions (much of eastern Germany between 2007 and 2011) drop
  out, which can bias results if crime there developed differently.

``` r

# Districts that exist with the same code in every year of the period.
# A district that absorbed another keeps its code (the Wartburgkreis in
# 2021): drop such districts too, using the crosswalk of the release.
stable <- Reduce(intersect, split(published$ags, published$year))
balanced <- published[published$ags %in% stable, ]
# Harmonized rows that rest on split weights
sum(harmonized$estimated)
```

Comparing an estimate on the harmonized panel (population weights), the
harmonized panel (area weights), the unbalanced panel and the balanced
panel of unchanged districts shows how much it depends on harmonization.

## Rates with your own population

The population used for the rates is the published one where the BKA
prints it (the PDF years and 2020), otherwise derived from cases and HZ.
An official population series can replace it:

``` r

d <- pks_example()
pop <- unique(data.frame(year = d$year, ags = d$ags, population = d$derived_population))
head(pks_rates(d, population = pop)[, c("year", "ags", "offence_key", "hz")])
#> # A tibble: 6 × 4
#>    year ags   offence_key     hz
#>   <int> <chr> <chr>        <dbl>
#> 1  2019 01001 ------       9628.
#> 2  2019 02000 ------      11231.
#> 3  2019 03159 ------       6349.
#> 4  2019 11000 ------      14086.
#> 5  2019 16063 ------       4397.
#> 6  2019 01001 890000       9312.
```
