# pksR (development version)

* `pks_get()` returns a new column `region_name_official`: the district name
  of the BBSR crosswalk at the boundary year of the row. `region_name` stays
  as published, and the yearbooks of 2003 to 2012 spell some names
  differently from year to year, so a harmonized panel now has one name per
  district. The crosswalk (`boundary_map.csv`) is now downloaded with every
  request and listed in `attr(, "source_urls")`.
* `pks_get()` returns six detail columns of the BKA tables (2013 onwards):
  `district_type`, `firearm_threatened`, `firearm_fired`, `suspects_male`,
  `suspects_female` and `suspects_non_german`. They are read from separate
  `*_details.csv.gz` files of data release 2026.2 and later, so older pksR
  versions keep working with new releases; with older releases the columns
  are NA. Detail counts are harmonized like the other counts.

# pksR 0.1.0

* First release on CRAN (21 November 2026).

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
* Several R sessions can fill the same cache at once: each download writes
  to a temporary file of its own.
* A damaged `manifest.json` in the cache is downloaded again.
* An expired or revoked `GITHUB_PAT` no longer blocks the public data
  releases: the release listing is repeated without it, with a warning.
  GitHub's rate limit errors say how to get around them.
