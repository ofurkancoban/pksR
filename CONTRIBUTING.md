# Contributing to pksR

**English** \| [Deutsch](#deutsch)

Thank you for helping to improve pksR. Bug reports, questions and pull
requests are welcome.

## Where to report what

- **The package** (an error, a confusing message, a missing feature):
  open an issue at <https://github.com/ofurkancoban/pksR/issues>. Please
  include a small example that shows the problem and the output of
  [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html).
- **The data** (a wrong value, a missing district or year, a wrong
  offence label): open an issue at
  <https://github.com/ofurkancoban/pksR-data/issues>. Please name the
  data version (`attr(d, "data_version")`), year, district code (`ags`)
  and offence key, and if you can, the value in the original BKA table.

## Pull requests

1.  Open an issue first for anything larger than a typo, so we can agree
    on the approach.
2.  Fork the repository and create a branch from `main`.
3.  Add or update tests in `tests/testthat/`. Tests run offline: they
    use the fixture release in `tests/testthat/fixtures/release` and
    never contact GitHub or the BKA.
4.  Run `devtools::document()`, `devtools::test()` and
    `devtools::check()` before you push.
5.  Use [Conventional
    Commits](https://www.conventionalcommits.org/en/v1.0.0/) for commit
    messages and the pull request title, for example
    `fix(api): keep Berlin in the example panel`. Types: `feat`, `fix`,
    `data`, `docs`, `test`, `refactor`, `perf`, `build`, `ci`, `chore`,
    `revert`.

## Style

- Code, comments, commit messages and file names are in English.
- Call functions of other packages with `pkg::fun()`.
- Messages go through `cli` and are wrapped in `tr()`. After adding or
  changing a message, run `Rscript data-raw/translations.R` and add the
  German text to `inst/i18n/de.po`.
- Documentation is bilingual: every help page has a `@section Deutsch:`,
  and each vignette has a German version (`*-de.Rmd`).
- Do not use em dashes or en dashes; use colons, commas or parentheses.

## Code of conduct

Please be kind and constructive. We follow the [rOpenSci Code of
Conduct](https://ropensci.org/code-of-conduct/).

## Deutsch

Danke, dass Sie pksR verbessern möchten.

- **Fehler im Paket** melden Sie unter
  <https://github.com/ofurkancoban/pksR/issues>, mit einem kleinen
  Beispiel und
  [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html).
- **Fehler in den Daten** melden Sie unter
  <https://github.com/ofurkancoban/pksR-data/issues>, mit Datenversion,
  Jahr, Kreisschlüssel (`ags`), Straftatenschlüssel und, wenn möglich,
  dem Wert in der BKA-Tabelle.
- **Pull Requests:** zuerst ein Issue öffnen, Tests ergänzen (sie laufen
  ohne Internet), vor dem Push `devtools::check()` ausführen,
  Commit-Nachrichten nach Conventional Commits. Code und Commits sind
  auf Englisch; Meldungen bekommen ihre deutsche Übersetzung in
  `inst/i18n/de.po`, Hilfeseiten einen Abschnitt `Deutsch`.
