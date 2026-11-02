# pksR 0.0.0.9000

* First version: `pks_get()`, `pks_manifest()`, `pks_versions()`,
  `pks_cache_info()`, `pks_cache_clear()`, `pks_rates()`, `pks_offences()`,
  `pks_breaks()`, `pks_validate()`, `pks_cite()` and `pks_example()`.
* `pks_compare_weights()` puts a harmonized panel with population and area
  weights side by side.
* New column `population_corrected` (census-corrected population of the BBSR
  at the HZ reference date) and `pks_rates(population = "corrected")`, which
  puts all years on one census base.
* `pks_cite()` gives the Zenodo DOI of the data release, and
  `pks_versions()` has a new column `doi`. The DOI is read from the release
  notes; until Zenodo has archived a version, the concept DOI is used.
