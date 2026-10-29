---
title: 'pksR: Harmonized, validated and versioned district-level German Police Crime Statistics for R'
tags:
  - R
  - crime statistics
  - Germany
  - official statistics
  - regional data
  - territorial harmonization
authors:
  - name: Ömer Furkan Çoban
    orcid: 0009-0005-3623-7178
    affiliation: 1
affiliations:
  - name: Carl von Ossietzky Universität Oldenburg, Germany
    index: 1
date: 29 October 2026
bibliography: paper.bib
---

# Summary

The German Police Crime Statistics (*Polizeiliche Kriminalstatistik*, PKS) of the Bundeskriminalamt (BKA) are the main source of recorded crime in Germany at the level of the about 400 districts (Kreise) [@bka_pks]. The BKA publishes one district table per year: as PDF yearbooks up to 2012 and as spreadsheets from 2013, each with its own layout, its own district boundaries and the offence keys valid in that year. Comparing a district over time therefore requires extracting, cleaning and harmonizing more than twenty separate files.

`pksR` gives R users these tables from 2003 onwards in one long table with one row per year, district and offence key. Users can request the data as published or harmonized to one territorial boundary and one offence classification, recompute rates on a consistent population base, and inspect the known methodological breaks in the series. The data come from versioned, validated and immutable releases produced by a separate open pipeline, `pksR-data`, with checksums and full provenance for every file.

# Statement of need

Regional crime data are widely used in economics, criminology and political science, for example to study the effects of immigration, policing or local economic conditions on crime. Researchers who use the German district tables face the same preparatory work in every project: downloading the yearly files, extracting the PDF years, reconciling changing spreadsheet layouts, and moving counts across the district reforms of Sachsen-Anhalt (2007), Sachsen (2008), Mecklenburg-Vorpommern (2011), Göttingen (2016) and Eisenach (2021). This work is usually done once per project, by hand and without documentation, which makes results hard to reproduce and errors hard to detect.

The choices made in this step are not neutral. Whether split districts are apportioned by population or by area, whether a panel is harmonized at all, whether rates are harmonized directly or recomputed from harmonized counts, and which population base is used after the censuses of 2011 and 2022 can all change estimates in panel regressions. `pksR` makes these choices explicit arguments, documents their assumptions, and provides `pks_compare_weights()` to show how results depend on them. It also records the methodological breaks of the series (changed offence definitions, new laws such as the Cannabis Act of 2024, census-based population revisions) in a reviewed table available through `pks_breaks()`, so that users can see where year-to-year comparisons are not valid.

# State of the field

The common practice is to download the BKA tables manually and process them with project-specific scripts. The R package `ags` [@ags] provides crosswalks of the Federal Institute for Research on Building, Urban Affairs and Spatial Development (BBSR) for German municipality and district codes, but does not provide crime data. `pksR` uses the BBSR transition keys [@bbsr_ref] directly, in their latest edition, extended with documented manual corrections and checked against the official lists of territorial changes of the Federal Statistical Office (Destatis). The R package `inkaR` [@inkaR] by the same author provides the regional indicators of the BBSR (INKAR), such as population and economic covariates for the same districts, and is used by the pipeline for census-corrected population figures. To our knowledge, no other open tool provides harmonized and validated district-level German crime statistics.

# Software design

The project follows the design of `nflverse-data` and `nflreadr` [@nflreadr]: data production is separated from data access.

`pksR-data` is a pipeline built with `targets` [@targets], so that only years whose source files or code changed are recomputed. All source URLs, checksums, crosswalk rows, offence mappings and methodological breaks live in plain CSV registries under version control, and every manual correction is a documented row with a reason. Extractors for the PDF and spreadsheet eras return one canonical schema in which missing variables are explicit `NA` values of the correct type. Territorial harmonization moves counts, never rates, with population or area weights for split districts, and flags estimated values. A validation gate checks schema, uniqueness, district coverage for the target boundary, agreement of district sums with the national tables, conservation of totals under harmonization, plausibility of counts and populations, and completeness of years. A scheduled GitHub Actions workflow downloads and verifies the sources, detects new reporting years and new crosswalk editions, and publishes a release only if every check passes; otherwise it opens an issue. Releases are immutable, and corrections produce a new version.

`pksR` is a small reader package with few dependencies. `pks_get()` downloads the requested release files, verifies their SHA-256 checksums against the release manifest, caches them in the user cache directory, and returns a tibble whose attributes record the data version, boundary year, weights and source URLs. Further functions recompute rates (`pks_rates()`), list offences and breaks (`pks_offences()`, `pks_breaks()`), validate any panel (`pks_validate()`), manage versions and the cache, and cite the package, the data release and the original sources (`pks_cite()`). Messages, offence labels and documentation are available in English and German.

# Research impact statement

`pksR` is an independent, voluntary open-source project of the author, developed to close a gap in the research infrastructure: no open, validated and citable source exists for German crime statistics at district level. Its significance lies in the following evidence, all of which is reproducible from the repositories.

1. **Verified extraction.** Every extracted value was compared with the original BKA files by code independent of the extractors: 63,795 cells of the PDF years 2003 to 2012 and 2,460,744 numeric cells of the spreadsheet years, with no mismatch.
2. **Errors found in hand-made data preparation.** Rebuilding an earlier set of project-specific scripts as tested software revealed errors that are typical of manual preparation and would otherwise go unnoticed: a total-crime series that switched definitions between years, different offence definitions mixed in one series, and rates that were too high by more than an order of magnitude for some merged or split districts. Each finding is documented in the repository with the affected years and districts and the size of the change.
3. **Transparent research decisions.** All 46 offence mappings and all 16 methodological breaks are stored as reviewed registry rows with their evidence, and every correction to the official BBSR crosswalk is a documented row with its source and reason, so that other researchers can inspect and challenge them.
4. **Readiness for reuse.** `pksR` passes `R CMD check --as-cran` without errors or warnings, has a test coverage of about 90 percent, follows the rOpenSci packaging guidelines, and is documented in English and German. The pipeline detects new reporting years and new crosswalk editions automatically, so the data stay current without manual work. The first public data release is in preparation.

# AI usage disclosure

Generative AI was used in the development of this software, its documentation and this paper. The author used Claude Code (Anthropic) with the model Claude Opus 5.5 as a coding assistant for three purposes: (1) language, namely wording and editing of English and German text in the documentation, vignettes, user messages, offence labels and this paper; (2) code generation, namely drafting functions, tests, continuous integration workflows and documentation of `pksR` and `pksR-data`; and (3) code optimization, namely reviewing, refactoring and improving the performance and robustness of existing code, including the review of the earlier scripts from which the pipeline was rebuilt.

All methodological decisions were made by the author. These include the choice of data sources, the territorial harmonization method and its weights, the treatment of mid-year district reforms, the offence key mappings, the census-corrected population, the classification of methodological breaks, and the content of the validation gate. Where the AI assistant drafted mappings, break descriptions or other research content, these were marked as drafts and reviewed, corrected and approved by the author before use.

The quality and correctness of AI-generated content were verified in four ways: automated tests for both repositories, including a regression test for every critical or major error found in the earlier scripts; the validation gate, which every data release must pass; a complete comparison of the extracted values with the original BKA files by independent code (see the research impact statement); and review of all code, documentation and registry changes by the author before they were committed. The author takes full responsibility for the software, the data and this paper.

# Acknowledgements

This work received no funding. It was developed voluntarily as open-source software. The author thanks the Bundeskriminalamt, the Federal Institute for Research on Building, Urban Affairs and Spatial Development (BBSR) and the Federal Statistical Office (Destatis) for publishing the data used here under open licences.

# References
