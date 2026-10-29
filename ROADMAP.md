# Roadmap

Planned work for pksR and the pksR-data pipeline, roughly in order. Nothing here is promised for a date; suggestions are welcome in the [issue tracker](https://github.com/ofurkancoban/pksR/issues).

## Next

1. **First data release (`2026.1`).** The pipeline is ready; the first release makes `pks_get()` usable.
2. **CRAN submission** after the first release, followed by rOpenSci software peer review and a paper in the Journal of Open Source Software.

## Data

1. **Suspects and victims tables.** Tables of suspects (Tatverdächtige) and victims (Opfer), at the district level where the BKA publishes them. They would become new tables in the same release, with their own canonical schema and validation.
2. **Länder and city tables.** State (Bundesland) and city (Städte ab 100.000 Einwohnern) tables, useful as checks of the district tables and for analyses at these levels.
3. **Gemeinde-level ground truth for split districts.** Split districts (Sachsen-Anhalt 2007, Sachsen 2008, Mecklenburg-Vorpommern 2011) are divided with population or area weights. Where municipality-level data exist, they can show how good these estimates are, and could replace them.

## Package

1. **`source = "bka"` in `pks_get()`.** Rebuild the spreadsheet years (2013 onwards) directly from the original BKA files instead of a release. Postponed until after the first CRAN release: it needs the extractors of pksR-data and a spreadsheet reader in the package, which would make it much larger. Until then the argument gives an informative error.
2. **`pks_geometry()` and `pks_map()`.** District geometries of the BKG (VG250) for the boundary of a panel, and a quick map.
3. **Covariates via [`inkaR`](https://CRAN.R-project.org/package=inkaR).** Join regional indicators of the BBSR (population, economy, labour market) to a panel by year and district code.
4. **Linking to the Strafverfolgungsstatistik.** The prosecution and conviction statistics of the Statistisches Bundesamt, to follow cases from police recording to court decisions.
5. **Python reader.** A small Python package that reads the same releases and checks the same checksums.

## Research support

1. **Sensitivity of econometric results to harmonization.** `pks_compare_weights()` and the harmonization vignette cover population versus area weights and harmonized versus published panels; further tools may follow from the analyses for the maintainer's master's thesis.
