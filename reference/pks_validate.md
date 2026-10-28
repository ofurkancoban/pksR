# Validate a panel

Runs the consistency checks of the pksR-data validation gate that need
only the panel itself: schema, uniqueness, coverage and plausibility.
Use it after filtering, joining or editing data from
[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md).
The checks of national totals and conservation need the national tables
and run in the pipeline before every release.

## Usage

``` r
pks_validate(data)
```

## Arguments

- data:

  A tibble from
  [`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md).

## Value

A tibble with one row per check: `check`, `status` (`pass`, `warn` or
`fail`), `problems` (number of offending rows or years) and `details`.

## Details

Checks:

- `schema`: the columns of the data as published or harmonized, with
  their types.

- `uniqueness`: one row per `year`, `ags` and `offence_key`.

- `city_states`: Berlin (`11000`) and Hamburg (`02000`) present in every
  year.

- `coverage`: harmonized data have the same districts in every year
  (balanced panel).

- `counts`: no negative counts, and `attempts` not above `cases`.

- `population`: the median district population per year lies between
  50,000 and 400,000 (a warning otherwise).

## See also

Other analysis:
[`pks_rates()`](https://ofurkancoban.github.io/pksR/reference/pks_rates.md)

## Examples

``` r
pks_validate(pks_example())
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
