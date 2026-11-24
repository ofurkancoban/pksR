# Get district-level police crime statistics

Downloads the district (Kreis) tables of the German Police Crime
Statistics (PKS) from a versioned data release, as published by the
Bundeskriminalamt or harmonized to one territorial boundary and offence
classification. Files are cached and checked against the SHA-256
checksums of the release manifest.

## Usage

``` r
pks_get(
  years = NULL,
  offence = NULL,
  harmonize_to = "latest",
  weights = c("population", "area"),
  version = "latest",
  source = c("release", "bka"),
  cache = TRUE,
  lang = NULL
)
```

## Arguments

- years:

  Integer vector of reporting years, or `NULL` (default) for all years
  of the release.

- offence:

  Offences to return, or `NULL` (default) for all. Each element can be
  an offence key (`"435*00"`), a short name in English or German
  (`"residential_burglary"`, `"wohnungseinbruch"`), a full label
  (`"Wohnungseinbruchdiebstahl"`) or a part of a label (`"einbruch"`,
  which selects both burglary keys). An exact key, name or label wins
  over a part. Capitals, spaces and umlauts do not matter. See
  [`pks_offences()`](https://ofurkancoban.github.io/pksR/reference/pks_offences.md)
  for all keys and names. For the data as published, the published keys
  that feed the selected keys are returned.

- harmonize_to:

  Target boundary year (Gebietsstand). `"latest"` (default) is the
  boundary of the release, read as released; another year harmonizes the
  data as published with the crosswalk of the release (forward only, so
  `years` must not be later than the target); `NULL` returns the data as
  published.

- weights:

  Weights for districts that were split: `"population"` (default) or
  `"area"`. Ignored for `harmonize_to = NULL`.

- version:

  Data version such as `"2026.1"`, or `"latest"` (default).

- source:

  `"release"` (default) reads a data release. `"bka"`, which will
  rebuild the spreadsheet years from the original BKA files, is not
  available yet.

- cache:

  Keep downloaded files in the cache (default `TRUE`). With `FALSE`,
  files go to a temporary directory and are removed with the R session.

- lang:

  Language of the offence labels in column `offence_label` and of the
  messages: `"de"` or `"en"`. `NULL` (default) uses
  `options(pksR.lang)`, otherwise the language of the R session.
  Harmonized data get the label of the harmonized key; data as published
  keep the published German label, or get the English label of the
  matching harmonized key.

## Value

A tibble with one row per year, district (`ags`) and offence key.
Columns are described in
[`vignette("pksR")`](https://ofurkancoban.github.io/pksR/articles/pksR.md).
Attributes: `data_version`, `retrieved_at`, `boundary_year`, `weights`
and `source_urls`.

## Deutsch

Lädt die Kreistabellen der Polizeilichen Kriminalstatistik (PKS) aus
einer versionierten Datenveröffentlichung, wie vom Bundeskriminalamt
veröffentlicht oder auf einen Gebietsstand und eine Straftatenzuordnung
harmonisiert. Jede Datei wird gegen die SHA-256-Prüfsumme des Manifests
geprüft und im Cache abgelegt.

- `years`: Berichtsjahre, `NULL` für alle.

- `offence`: Straftaten als Schlüssel (`"435*00"`), Kurzname auf Deutsch
  oder Englisch (`"wohnungseinbruch"`, `"residential_burglary"`),
  vollständige Bezeichnung oder Teil einer Bezeichnung (`"einbruch"`).
  Groß- und Kleinschreibung, Leerzeichen und Umlaute spielen keine
  Rolle; eine genaue Übereinstimmung hat Vorrang. Übersicht:
  [`pks_offences()`](https://ofurkancoban.github.io/pksR/reference/pks_offences.md).

- `harmonize_to`: `"latest"` (Gebietsstand der Veröffentlichung), ein
  Jahr (Harmonisierung nur vorwärts) oder `NULL` (wie veröffentlicht).

- `weights`: Gewichtung geteilter Kreise, `"population"` oder `"area"`.

- `version`: Datenversion, etwa `"2026.1"`, oder `"latest"`.

- `lang`: Sprache der Bezeichnungen und Meldungen, `"de"` oder `"en"`;
  Voreinstellung `options(pksR.lang)`, sonst die Sprache der R-Sitzung.

Ergebnis: ein Tibble mit einer Zeile je Jahr, Kreis und
Straftatenschlüssel und den Attributen `data_version`, `retrieved_at`,
`boundary_year`, `weights` und `source_urls`.

## See also

Other data:
[`pks_example()`](https://ofurkancoban.github.io/pksR/reference/pks_example.md)

## Examples

``` r
if (FALSE) { # interactive()
# Total offences, harmonized to the latest boundary
total <- pks_get(offence = "total")

# Theft in total and both burglary keys, German labels
theft <- pks_get(offence = c("diebstahl", "einbruch"), lang = "de")

# As published by the BKA, two years
published <- pks_get(years = 2024:2025, harmonize_to = NULL)
}
```
