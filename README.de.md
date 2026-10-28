# pksR: Polizeiliche Kriminalstatistik auf Kreisebene

[English](README.md)

`pksR` stellt R-Nutzerinnen und -Nutzern die Kreistabellen der Polizeilichen Kriminalstatistik (PKS) des Bundeskriminalamts ab 2003 bereit: wie veröffentlicht oder harmonisiert auf einen Gebietsstand und eine Straftatenzuordnung.

Die Daten stammen aus versionierten, geprüften Veröffentlichungen von [pksR-data](https://github.com/ofurkancoban/pksR-data), der Pipeline, die die Originaldateien des BKA herunterlädt, auswertet, harmonisiert und jede Veröffentlichung prüft. `pksR` lädt nur die gewünschten Jahre, speichert sie in einem lokalen Cache und prüft jede Datei gegen die SHA-256-Prüfsummen der Veröffentlichung.

Nicht zu verwechseln mit dem CRAN-Paket `pks` (probabilistische Wissensstrukturen).

## Installation

```r
# install.packages("remotes")
remotes::install_github("ofurkancoban/pksR")
```

## Verwendung

```r
library(pksR)
options(pksR.lang = "de")   # Meldungen und Bezeichnungen auf Deutsch

# Straftaten insgesamt in allen Kreisen, auf den neuesten Gebietsstand harmonisiert
insgesamt <- pks_get(offence = "insgesamt")

# Straftaten per Schlüssel, Kurzname oder Bezeichnung, deutsch oder englisch
einbruch <- pks_get(offence = c("wohnungseinbruch", "435*00", "Wohnungseinbruchdiebstahl"))

# Wie vom BKA veröffentlicht, zwei Jahre
veroeffentlicht <- pks_get(years = 2024:2025, harmonize_to = NULL)

# Auf einen anderen Gebietsstand harmonisiert, Flächengewichtung für geteilte Kreise
d <- pks_get(years = 2010:2015, harmonize_to = 2016, weights = "area")

# Quoten nach der Harmonisierung neu berechnen, auch mit eigener Einwohnerzahl
quoten <- pks_rates(d)

pks_offences("Diebstahl")   # Schlüssel, Kurznamen und Bezeichnungen
pks_breaks()                # bekannte methodische Brüche
pks_validate(d)             # Konsistenzprüfungen
pks_versions()              # verfügbare Datenversionen
pks_cite()                  # Zitierangaben für Paket, Daten und Quellen
```

## Sprachen

Meldungen, Fehlermeldungen und Bezeichnungen der Straftaten gibt es auf Deutsch und Englisch. `options(pksR.lang = "de")` wählt Deutsch, sonst gilt die Sprache der R-Sitzung. `pks_get()` und `pks_offences()` nehmen außerdem `lang = "de"` oder `lang = "en"`. Die Vignetten und diese Seite gibt es in beiden Sprachen; die Hilfeseiten haben einen Abschnitt „Deutsch“.

## Datenversionen

Jede Datenveröffentlichung hat eine Version (`2026.1`, `2026.2`, ...) und ändert sich nie; Korrekturen erscheinen als neue Version. `pks_get(version = "2026.1")` liefert jederzeit dieselben Daten. Vor jeder Veröffentlichung wird geprüft: Schema, eine Zeile je Jahr, Kreis und Straftatenschlüssel, die erwartete Zahl der Kreise, Bundessummen, Erhalt der Summen bei der Harmonisierung und Plausibilität. Einzelheiten in der [README von pksR-data](https://github.com/ofurkancoban/pksR-data).

## Quellen und Nutzungsbedingungen

Der Code des Pakets steht unter der MIT-Lizenz. Für die Daten gelten die Bedingungen ihrer Quellen:

- PKS-Tabellen: Bundeskriminalamt, [Datenlizenz Deutschland, Namensnennung, Version 2.0](https://www.govdata.de/dl-de/by-2-0). Quellenvermerk: „PKS Bundeskriminalamt“, Berichtsjahr, Version.
- Umsteigeschlüssel: [Bundesinstitut für Bau-, Stadt- und Raumforschung](https://www.bbsr.bund.de) (BBSR), Datenlizenz Deutschland, Namensnennung, Version 2.0. Quellenvermerk: „BBSR Bonn“.
- Gebietsänderungen der Gemeinden: Statistisches Bundesamt (Destatis), Gemeindeverzeichnis.

Die harmonisierten Daten sind veränderte Daten und keine amtlichen Zahlen des BKA. `pks_cite()` liefert die vollständigen Zitierangaben.

## Autor

Ömer Furkan Çoban
