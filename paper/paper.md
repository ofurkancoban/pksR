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

<!-- Skeleton for the JOSS submission. Sections marked TODO are to be written
by the author. JOSS asks for 250 to 1000 words in total. -->

# Summary

<!-- TODO: two or three paragraphs for a non-specialist reader. -->

The German Police Crime Statistics (*Polizeiliche Kriminalstatistik*, PKS) of the Bundeskriminalamt (BKA) are the main source of recorded crime in Germany at the level of the about 400 districts (Kreise) [@bka_pks]. The BKA publishes one table per year, as PDF yearbooks up to 2012 and as spreadsheets from 2013, each on the district boundaries and with the offence keys of its year. `pksR` gives R users these tables from 2003 onwards in one schema, either as published or harmonized to one territorial boundary and one offence classification, from versioned and validated data releases with checksums and provenance.

# Statement of need

<!-- TODO: who needs this and why, with examples from regional economics and
criminology. Points to cover: -->

- Researchers who study crime across German districts over time must first assemble the yearly tables, extract the PDF years, and move counts across the district reforms of Sachsen-Anhalt (2007), Sachsen (2008), Mecklenburg-Vorpommern (2011), Göttingen (2016) and Eisenach (2021). This is usually done once per project, by hand and without documentation.
- Harmonization choices (population or area weights for split districts, harmonizing at all) can change econometric results; `pks_compare_weights()` and the harmonization vignette make them explicit.
- Each data release passes a validation gate (schema, uniqueness, coverage, national totals, conservation of totals, plausibility) and is immutable; corrections produce a new version that can be cited.

# State of the field

<!-- TODO: compare with existing tools. -->

- Manual downloads of the BKA tables, the common practice.
- The R package `ags` [@ags] provides crosswalks of the Federal Institute for Research on Building, Urban Affairs and Spatial Development (BBSR) for German municipality and district codes; `pksR` uses the BBSR transition keys with documented manual corrections and uses `ags` only as an independent cross-check in tests.
- The R package `inkaR` [@inkaR] provides regional indicators of the BBSR (INKAR), such as population and economic covariates for the same districts.
- The two-repository design (a pipeline that publishes releases and a small reader package) follows `nflverse-data` and `nflreadr`.

# Software design

<!-- TODO: short description of pksR-data (targets pipeline, registry,
validation gate, GitHub releases) and pksR (pks_get(), cache, SHA-256
checks, provenance attributes, bilingual messages and documentation). -->

# AI usage disclosure

<!-- TODO: to be written by the author, based on notes/ai-usage.md. -->

# Acknowledgements

<!-- TODO -->

# References
