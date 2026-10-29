# pksR: Polizeiliche Kriminalstatistik auf Kreisebene <img src="man/figures/logo.png" align="right" height="139" alt="pksR-Logo" />

[English](README.md) | **Deutsch**

<!-- badges: start -->
[![R-CMD-check](https://github.com/ofurkancoban/pksR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ofurkancoban/pksR/actions/workflows/R-CMD-check.yaml)
[![test-coverage](https://github.com/ofurkancoban/pksR/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/ofurkancoban/pksR/actions/workflows/test-coverage.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Project Status: WIP](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
<!-- badges: end -->

`pksR` stellt in R die Kreistabellen der Polizeilichen Kriminalstatistik (PKS) des Bundeskriminalamts (BKA) ab 2003 bereit: wie veröffentlicht oder harmonisiert auf einen Gebietsstand und eine Straftatenzuordnung, sodass sich Kreise über die Zeit vergleichen lassen.

Nicht zu verwechseln mit dem CRAN-Paket `pks` (probabilistische Wissensstrukturen).

## Warum pksR

Das BKA veröffentlicht die Kreistabellen einmal im Jahr: bis 2012 als PDF-Jahrbücher, ab 2013 als Tabellen, jeweils mit eigenem Aufbau und eigenem Gebietsstand. Kreise wurden mehrfach zusammengelegt und geteilt (Sachsen-Anhalt 2007, Sachsen 2008, Mecklenburg-Vorpommern 2011, Göttingen 2016, Eisenach 2021), und Straftatenschlüssel ändern sich. `pksR` erledigt diese Arbeit einmal, offen und reproduzierbar:

- **Eine Tabelle für alle Jahre.** Eine Zeile je Jahr, Kreis und Straftatenschlüssel, mit denselben Spalten und Datentypen in jedem Jahr.
- **Harmonisierte Gebietsstände.** Fallzahlen werden mit den Umsteigeschlüsseln des BBSR (Bevölkerungs- oder Flächengewichte) auf einen Gebietsstand übertragen; Quoten werden danach neu berechnet, nie gemittelt.
- **Geprüfte Veröffentlichungen.** Jede Datenveröffentlichung besteht vor der Veröffentlichung Konsistenzprüfungen (Bundessummen, Erhalt der Summen, Abdeckung, Plausibilität).
- **Herkunft.** Jede Datei hat eine Version und eine SHA-256-Prüfsumme, und jede Zeile lässt sich auf die BKA-Datei zurückführen, aus der sie stammt.
- **Deutsch und Englisch.** Meldungen, Bezeichnungen der Straftaten und Dokumentation in beiden Sprachen.

## Stand

Das Paket ist in Entwicklung und noch nicht auf CRAN. **Die erste Datenveröffentlichung wird vorbereitet.** Bis sie erscheint, hat `pks_get()` keine Daten zum Herunterladen; `pks_example()`, `pks_offences()` und `pks_breaks()` funktionieren schon, auch ohne Internet.

## Installation

```r
# install.packages("remotes")
remotes::install_github("ofurkancoban/pksR")
```

## Erste Schritte

```r
library(pksR)
options(pksR.lang = "de")   # Meldungen und Bezeichnungen auf Deutsch

# Straftaten insgesamt in allen Kreisen und Jahren, auf den neuesten Gebietsstand harmonisiert
insgesamt <- pks_get(offence = "insgesamt")

# Mehrere Straftaten auf einmal: per Kurzname, Straftatenschlüssel oder Bezeichnung
d <- pks_get(years = 2015:2025, offence = c("wohnungseinbruch", "730000", "Gewaltkriminalität"))

# Wie vom BKA veröffentlicht: jedes Jahr mit seinen eigenen Kreisen
veroeffentlicht <- pks_get(years = 2024:2025, harmonize_to = NULL)

# Auf den Gebietsstand 2016 harmonisiert, Flächengewichte für geteilte Kreise
d2016 <- pks_get(years = 2010:2015, harmonize_to = 2016, weights = "area")

# Eine feste Datenversion, für reproduzierbare Arbeiten
d <- pks_get(version = "2026.1", offence = "insgesamt")
```

Ohne Internet hilft das kleine Beispielpanel, das mit dem Paket ausgeliefert wird:

```r
d <- pks_example()
pks_rates(d, per = 1000)   # Quoten je 1.000 Einwohner
pks_validate(d)            # Konsistenzprüfungen
```

## Straftaten auswählen

`offence` nimmt für jedes Element eine der folgenden Formen:

| Form | Beispiel | Ergebnis |
|---|---|---|
| Straftatenschlüssel | `"435*00"` | dieser Schlüssel |
| Kurzname, deutsch oder englisch | `"wohnungseinbruch"`, `"residential_burglary"` | dieser Schlüssel |
| Vollständige Bezeichnung, in einer der beiden Sprachen | `"Wohnungseinbruchdiebstahl"` | dieser Schlüssel |
| Teil einer Bezeichnung | `"einbruch"` | alle passenden Schlüssel, mit einer Meldung, welche |

Groß- und Kleinschreibung, Leerzeichen und Umlaute spielen keine Rolle, und ein genauer Schlüssel, Name oder eine genaue Bezeichnung hat immer Vorrang vor einem Teil. `pks_offences()` listet alle Schlüssel:

```r
pks_offences("diebstahl")          # Suche nach Name oder Bezeichnung
pks_offences(lang = "en")          # englische Namen und Bezeichnungen
```

Einige häufige Kurznamen:

| Schlüssel | Deutsch | Englisch |
|---|---|---|
| `------` | `insgesamt` | `total` |
| `****00` | `diebstahl` | `theft` |
| `435*00` | `wohnungseinbruch` | `residential_burglary` |
| `210000` | `raub` | `robbery` |
| `892000` | `gewaltkriminalitaet` | `violent_crime` |
| `674000` | `sachbeschaedigung` | `criminal_damage` |
| `730000` | `rauschgiftdelikte` | `drug_offences` |
| `899000` | `strassenkriminalitaet` | `street_crime` |

## Was die Daten enthalten

- **Jahre:** 2003 bis 2025; neue Jahre fügt die Pipeline hinzu, sobald das BKA sie veröffentlicht.
- **Kreise:** alle Landkreise und kreisfreien Städte, 400 im neuesten Gebietsstand; Berlin und Hamburg in jedem Jahr.
- **Straftaten:** die 46 Straftatenschlüssel der Kreistabellen. Die Tabellen enthalten eine Auswahl von Schlüsseln, die sich über die Zeit ändert: 6 Schlüssel umfassen alle Jahre 2003 bis 2025, 37 Schlüssel die Jahre 2014 bis 2025.
- **Größen:** Fälle, Versuche, Häufigkeitszahl (HZ, Fälle je 100.000 Einwohner), aufgeklärte Fälle, Aufklärungsquote und Tatverdächtige.

Alle Spalten beschreibt `vignette("pksR-de")`.

## Was zu beachten ist

- **2003 bis 2012** stammen aus PDF-Jahrbüchern, die Quoten und Einwohnerzahlen, aber keine Fallzahlen enthalten. Die Fallzahlen dieser Jahre sind abgeleitet (`hz * population / 1e5`) und mit `estimated = TRUE` gekennzeichnet.
- **Geteilte Kreise** sind Schätzungen: Die Gewichte unterstellen, dass sich die Fälle wie die Einwohner (oder wie die Fläche) verteilen. Solche Zeilen tragen `estimated = TRUE`; Zusammenlegungen sind exakt.
- **Brüche:** Straftatendefinitionen, Gesetze und Erfassungspraxis ändern sich. Vor jeder Zeitreihe `pks_breaks()` prüfen.
- **Harmonisierte Daten sind veränderte Daten**, keine amtlichen Zahlen des BKA.

## Sprachen

`options(pksR.lang = "de")` stellt Meldungen und Bezeichnungen der Straftaten auf Deutsch um, `options(pksR.lang = "en")` auf Englisch; sonst gilt die Sprache der R-Sitzung. `pks_get()` und `pks_offences()` nehmen außerdem `lang = "de"` oder `lang = "en"`. Jede Hilfeseite hat einen Abschnitt „Deutsch“.

## Dokumentation

Die [Website des Pakets](https://ofurkancoban.github.io/pksR/) enthält die Referenz und drei Artikel, jeweils auf Deutsch und Englisch:

| Artikel | Deutsch | Englisch |
|---|---|---|
| Erste Schritte | [pksR-de](https://ofurkancoban.github.io/pksR/articles/pksR-de.html) | [pksR](https://ofurkancoban.github.io/pksR/articles/pksR.html) |
| Harmonisierung: Methoden, Annahmen und Sensitivität | [harmonization-de](https://ofurkancoban.github.io/pksR/articles/harmonization-de.html) | [harmonization](https://ofurkancoban.github.io/pksR/articles/harmonization.html) |
| Herkunft und Prüfung der Daten | [provenance-de](https://ofurkancoban.github.io/pksR/articles/provenance-de.html) | [provenance](https://ofurkancoban.github.io/pksR/articles/provenance.html) |

## Datenveröffentlichungen und Cache

Die Daten erstellt [pksR-data](https://github.com/ofurkancoban/pksR-data), eine Pipeline, die die Originaldateien des BKA herunterlädt, auswertet, harmonisiert und prüft und jedes Ergebnis als GitHub-Veröffentlichung bereitstellt.

- Jede Veröffentlichung hat eine Version (`2026.1`, `2026.2`, ...) und ändert sich nie; Korrekturen erscheinen als neue Version. `pks_versions()` listet sie, `pks_manifest()` zeigt die Dateien einer Veröffentlichung.
- `pks_get()` lädt nur die gewünschten Jahre und prüft jede Datei gegen die SHA-256-Prüfsumme im Manifest der Veröffentlichung.
- Downloads liegen im Cache unter `tools::R_user_dir("pksR", "cache")`; `pks_cache_info()` und `pks_cache_clear()` verwalten ihn.
- Jedes Ergebnis trägt seine Herkunft als Attribute: `data_version`, `retrieved_at`, `boundary_year`, `weights` und `source_urls`.

## Zitieren

Bitte zitieren Sie das Paket, die Datenversion und die Quellen. `pks_cite()` liefert alle Einträge, auch als BibTeX:

```r
pks_cite()
pks_cite(version = "2026.1")
```

## Quellen und Nutzungsbedingungen

Der Code des Pakets steht unter der MIT-Lizenz. Für die Daten gelten die Bedingungen ihrer Quellen:

- **PKS-Tabellen:** Bundeskriminalamt, [Datenlizenz Deutschland, Namensnennung, Version 2.0](https://www.govdata.de/dl-de/by-2-0). Quellenvermerk: „PKS Bundeskriminalamt“, Berichtsjahr, Version.
- **Umsteigeschlüssel:** [Bundesinstitut für Bau-, Stadt- und Raumforschung](https://www.bbsr.bund.de) (BBSR), Datenlizenz Deutschland, Namensnennung, Version 2.0. Quellenvermerk: „BBSR Bonn“.
- **Gebietsänderungen der Gemeinden:** Statistisches Bundesamt (Destatis), Gemeindeverzeichnis.
- **Logo:** Die Karte zeigt die 401 Kreise zum 1. Januar 2020, eingefärbt nach der veröffentlichten Häufigkeitszahl der Straftaten insgesamt 2020 (PKS Bundeskriminalamt 2020). Kreisgeometrien: [© GeoBasis-DE / BKG 2025 (Daten verändert)](https://www.bkg.bund.de), VG250, Datenlizenz Deutschland, Namensnennung, Version 2.0. Erstellt mit `data-raw/logo.R`.

## Verwandte Pakete

- [`inkaR`](https://CRAN.R-project.org/package=inkaR): Regionalindikatoren des BBSR (INKAR), etwa Bevölkerung und wirtschaftliche Kovariaten für dieselben Kreise.
- [`ags`](https://CRAN.R-project.org/package=ags): Umsteigeschlüssel des BBSR für deutsche Kreisschlüssel.

## Mitwirken

Fehlermeldungen und Vorschläge sind im [Issue-Tracker](https://github.com/ofurkancoban/pksR/issues) willkommen. Probleme mit den Daten selbst (ein falscher Wert, ein fehlender Kreis) gehören am besten in die [Issues von pksR-data](https://github.com/ofurkancoban/pksR-data/issues).

## Autor

Ömer Furkan Çoban
