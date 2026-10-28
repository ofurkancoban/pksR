# Herkunft und Prüfung der Daten

Jede Zahl, die `pksR` liefert, lässt sich auf eine vom Bundeskriminalamt
veröffentlichte Datei zurückführen, und jede Datenveröffentlichung wird
vor der Veröffentlichung geprüft. Diese Vignette beschreibt den Weg von
den BKA-Dateien zu einer Datenveröffentlichung und wie Sie die Herkunft
Ihrer Daten prüfen. Die englische Fassung ist
[`vignette("provenance")`](https://ofurkancoban.github.io/pksR/articles/provenance.md).

``` r

library(pksR)
```

## Von den BKA-Dateien zur Datenveröffentlichung

Die Datenveröffentlichungen erstellt
[pksR-data](https://github.com/ofurkancoban/pksR-data), eine Pipeline
auf GitHub Actions:

1.  **Quellen.** Jede Quelldatei hat eine Zeile in einem Register, mit
    genauer URL, der BKA-Seite, die sie verlinkt, ihrer
    SHA-256-Prüfsumme und der Tabellenversion des BKA. URLs werden nie
    aus Vorlagen gebaut. Ein Download, dessen Prüfsumme vom Register
    abweicht, wird nicht verwendet; stimmen zwei Downloads in einer
    neuen Prüfsumme überein, meldet die Pipeline eine neu
    veröffentlichte Datei, statt zu veröffentlichen.
2.  **Auswertung.** Die PDF-Jahrbücher (2003 bis 2012) und die Tabellen
    (ab 2013) werden in ein gemeinsames Schema mit festen Datentypen
    überführt. Spalten, die einem Jahr fehlen, sind als `NA` vorhanden.
3.  **Harmonisierung.** Gebiets- und Straftatenharmonisierung wie in
    [`vignette("harmonization-de")`](https://ofurkancoban.github.io/pksR/articles/harmonization-de.md)
    beschrieben.
4.  **Prüfung.** Die Veröffentlichung entsteht nur, wenn alle Prüfungen
    bestanden sind (siehe unten).
5.  **Veröffentlichung.** Die Dateien erscheinen als unveränderliche
    GitHub-Veröffentlichung `v<Jahr>.<n>` mit einem Manifest.

## Das Manifest

Das Manifest einer Veröffentlichung hält fest, was sie enthält und wie
sie entstanden ist:

``` r

m <- pks_manifest("2026.1")
m                                  # Dateien mit SHA-256, Größe und Zeilen
meta <- attr(m, "manifest")
meta$pipeline_commit               # der Code der Pipeline, der sie erstellt hat
meta$target_boundary_year          # Gebietsstand des harmonisierten Panels
meta$validation                    # Ergebnis der Prüfung
meta$attribution                   # Quellen, Lizenzen, Quellenvermerke
```

[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md)
prüft jede heruntergeladene Datei gegen die SHA-256-Prüfsumme im
Manifest und lehnt eine Datei ab, die nicht passt. Veröffentlichungen
ändern sich nie: `version = "2026.1"` liefert jederzeit dieselben Daten,
und eine Korrektur erscheint als neue Version.

Die Register einer Veröffentlichung (`sources.csv`, `boundary_map.csv`,
`offence_map.csv`, `known_breaks.csv` und die Quellenlisten der
Bundestabellen, des Umsteigeschlüssels und der Gebietsänderungen) sind
ebenfalls Dateien der Veröffentlichung; jede Zuordnung, die in die Daten
eingegangen ist, lässt sich nachlesen.

## Die Prüfung vor jeder Veröffentlichung

Vor jeder Veröffentlichung prüft die Pipeline:

| Prüfung | Regel |
|----|----|
| Schema | Alle Spalten mit ihren Datentypen vorhanden |
| Eindeutigkeit | Eine Zeile je Jahr, Kreis und Straftatenschlüssel |
| Abdeckung | Die erwartete Zahl der Kreise für den Gebietsstand; Berlin und Hamburg in jedem Jahr |
| Bundessummen | Die Summe über die Kreise passt zur Bundestabelle desselben Jahres und Schlüssels, mit dokumentierter Toleranz für Fälle ohne bekannten Tatort |
| Erhalt | Die Harmonisierung verändert die Bundessumme keiner Fallzahl und nicht die Einwohnerzahl |
| Plausibilität | Keine negativen Zahlen; nicht mehr Versuche als Fälle; Median der Kreiseinwohnerzahl zwischen 50.000 und 400.000 |
| Vollständigkeit | Jedes registrierte Jahr liefert Daten |

Scheitert eine Prüfung, wird nichts veröffentlicht, und ein Issue mit
dem Bericht wird eröffnet. Das Ergebnis der Prüfung steht im Manifest
(`validation`).

## Eigene Daten prüfen

[`pks_validate()`](https://ofurkancoban.github.io/pksR/reference/pks_validate.md)
führt die Prüfungen aus, die nur das Panel selbst brauchen, etwa nach
dem Filtern oder Verknüpfen von Daten:

``` r

d <- pks_example()
pks_validate(d)
#> Prüfung: 6 bestanden, 0 Warnungen, 0 nicht bestanden.
#> # A tibble: 6 × 4
#>   check       status problems details
#>   <chr>       <chr>     <int> <chr>  
#> 1 schema      pass          0 ""     
#> 2 uniqueness  pass          0 ""     
#> 3 city_states pass          0 ""     
#> 4 coverage    pass          0 ""     
#> 5 counts      pass          0 ""     
#> 6 population  pass          0 ""

# Ein fehlerhaftes Panel: Berlin entfernt
pks_validate(d[d$ags != "11000", ])
#> Prüfung: 5 bestanden, 0 Warnungen, 1 nicht bestanden.
#> ! city_states: 2019: 11000 fehlt; 2020: 11000 fehlt; 2021: 11000 fehlt; 2022:
#>   11000 fehlt; 2023: 11000 fehlt; 2024: 11000 fehlt; 2025: 11000 fehlt
#> # A tibble: 6 × 4
#>   check       status problems details                                           
#>   <chr>       <chr>     <int> <chr>                                             
#> 1 schema      pass          0 ""                                                
#> 2 uniqueness  pass          0 ""                                                
#> 3 city_states fail          7 "2019: 11000 fehlt; 2020: 11000 fehlt; 2021: 1100…
#> 4 coverage    pass          0 ""                                                
#> 5 counts      pass          0 ""                                                
#> 6 population  pass          0 ""
```

## Was die Daten nicht sind

Die harmonisierten Daten sind veränderte Daten: Werte veränderter Kreise
sind aus den veröffentlichten berechnet und keine amtlichen Zahlen des
BKA. Die Fallzahlen der PDF-Jahre sind aus gerundeten Quoten abgeleitet.
Die Kreistabellen enthalten nur eine Auswahl von Straftatenschlüsseln,
und Erfassungspraxis, Straftatendefinitionen und Bezugsbevölkerung
ändern sich über die Zeit
([`pks_breaks()`](https://ofurkancoban.github.io/pksR/reference/pks_breaks.md)).

## Nutzungsbedingungen und Zitieren

Die PKS-Tabellen und der BBSR-Umsteigeschlüssel stehen unter der
Datenlizenz Deutschland, Namensnennung, Version 2.0
(<https://www.govdata.de/dl-de/by-2-0>), die die Nennung der Quelle
(„PKS Bundeskriminalamt“, Berichtsjahr, Version) und einen Hinweis auf
Veränderungen verlangt. Das Gemeindeverzeichnis von Destatis darf mit
Quellenvermerk wiedergegeben werden.
[`pks_cite()`](https://ofurkancoban.github.io/pksR/reference/pks_cite.md)
liefert Zitierangaben für das Paket, die Datenversion und alle drei
Quellen.
