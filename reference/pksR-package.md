# pksR: District-Level German Police Crime Statistics

Access to the district (Kreis) tables of the German Police Crime
Statistics ('Polizeiliche Kriminalstatistik', PKS) published by the
Bundeskriminalamt, from 2003 onwards. Data come from versioned,
validated releases of the 'pksR-data' pipeline, either as published or
harmonized to a common territorial boundary and offence classification.
Downloads are cached and checked against SHA-256 checksums; rates can be
recomputed after harmonization, panels validated, and data releases
cited.

## Language

Messages, warnings, errors and offence labels are available in English
and German. The language is `options(pksR.lang = "en")` or
`options(pksR.lang = "de")`, otherwise the language of the R session.
[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md)
and
[`pks_offences()`](https://ofurkancoban.github.io/pksR/reference/pks_offences.md)
also take a `lang` argument.

## Deutsch

pksR liefert die Kreistabellen der Polizeilichen Kriminalstatistik (PKS)
des Bundeskriminalamts ab 2003, wie veröffentlicht oder auf einen
Gebietsstand und eine Straftatenzuordnung harmonisiert, aus
versionierten und geprüften Datenveröffentlichungen. Meldungen und
Bezeichnungen gibt es auf Deutsch und Englisch:
`options(pksR.lang = "de")` wählt Deutsch, sonst gilt die Sprache der
R-Sitzung. Einstieg:
[`vignette("pksR-de")`](https://ofurkancoban.github.io/pksR/articles/pksR-de.md).

## See also

Useful links:

- <https://github.com/ofurkancoban/pksR>

- <https://ofurkancoban.github.io/pksR/>

- <https://github.com/ofurkancoban/pksR-data>

- Report bugs at <https://github.com/ofurkancoban/pksR/issues>

## Author

**Maintainer**: Ömer Furkan Çoban <ofurkancoban@gmail.com> \[copyright
holder\]
