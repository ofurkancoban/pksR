# Design decisions: pksR

## 2026-10-28: Phase 4 start

1. Name check (brief Section 4.2): `available::available("pksR")` on 2026-10-28: valid name, free on CRAN, Bioconductor and GitHub. The unrelated CRAN package `pks` exists; the title says "District-Level German Police Crime Statistics".
2. Data source: published GitHub releases `v<year>.<n>` of `ofurkancoban/pksR-data` only; drafts and prereleases are dry runs and are ignored. The repository is an option (`pksR.repo`) for tests and forks.
3. Files: always the per-year CSV.gz assets, for both the harmonized panels and the data as published (added to pksR-data for this, commit `1958c01`). `arrow` is not a dependency at all: a request for a few years downloads only those years, and `Imports` stays within the brief's list.
4. Harmonization to a boundary other than the release's: `pks_get(harmonize_to = <year>)` harmonizes the data as published with the crosswalk and offence map of the same release (`R/pks_harmonize.R`, ported from pksR-data). Check on 2026-10-28 against a local build of pksR-data: harmonizing all years 2003 to 2025 to 2025 in the package gives the released panel exactly (233,600 rows, all columns equal within 1e-10) for population and area weights. Forward only: years whose boundary is later than the target are refused, not dropped.
5. `pks_offences()` and `pks_breaks()` read snapshots in `R/sysdata.rda` (built by `data-raw/sysdata.R` from the pksR-data registry), so they work offline; `pks_get()` uses the offence map of the data release itself.
6. Exceptions to "every exported function returns a tibble" (brief Section 8): `pks_cite()` returns a `utils::bibentry()` (printable and convertible to BibTeX), and `pks_manifest()` returns the file table as a tibble with the other manifest fields as attribute `manifest`.
7. Added exports beyond the brief's list: `pks_example()`, a 70-row example panel in `inst/extdata` (built by `data-raw/example.R` from pksR-data commit 785ac02, labelled `data_version = "example"`, not a release), for examples, tests and vignettes without internet.
8. Network examples use `@examplesIf interactive()`: `R CMD check --as-cran` runs `\donttest{}` examples, which would fail offline.
9. `source = "bka"` is not implemented yet and stops with a clear message; it needs the extraction code of pksR-data and `readxl`.

## 2026-10-28: Choosing offences and two languages

1. `offence` replaces `offence_keys` in `pks_get()` (breaking change, decided by the maintainer: a call like `offence_keys = "------"` is hard to read). Each element may be an offence key, a short name (`alias_en`, `alias_de` in `offence_map.csv` of pksR-data, 46 names with `status = "draft"`), a full label in either language, or a part of a label. Matching ignores case, spaces and umlauts (`normalize_name()`).
2. Order of matching: an exact key, short name or label wins over a part search, so `"Diebstahl"` gives `****00` only; a part search (`"einbruch"`) selects every matching key and says which, never silently.
3. Two languages, German and English, chosen by the maintainer for everything user-facing: messages and errors, offence labels in the data, help pages (a `Deutsch` section per page), README (`README.de.md`) and vignettes (`*-de.Rmd`). Code, comments, commit messages and file names stay English (global rule).
4. Language: argument `lang` of `pks_get()` and `pks_offences()`, otherwise `options(pksR.lang)`, otherwise the session language (`LANGUAGE`, then `LC_MESSAGES`); anything not German is English.
5. Own translation table (`inst/i18n/de.po`, read by `tr()`) instead of R's gettext: gettext ignores `LANGUAGE` in the C locale (as on CRAN check machines) and cannot switch language within a session for one call. The file keeps the `.po` format, so it can later move to `po/` if that is preferred. `test-lang.R` checks that every `tr()` text has a translation with the same placeholders.
6. Harmonized data get `offence_label` in the chosen language from the offence map. Data as published keep the published German label for `lang = "de"` and get the English label of the mapped harmonized key for `lang = "en"` (`NA` where the published key has no mapping).
