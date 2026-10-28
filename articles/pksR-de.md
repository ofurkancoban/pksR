# Erste Schritte mit pksR

`pksR` liest die Kreistabellen der Polizeilichen Kriminalstatistik (PKS)
des Bundeskriminalamts (BKA) aus versionierten Datenveröffentlichungen.
Diese Vignette zeigt die wichtigsten Funktionen und beschreibt die
Spalten. Beispiele, die das Internet brauchen, werden gezeigt, aber hier
nicht ausgeführt; die übrigen verwenden
[`pks_example()`](https://ofurkancoban.github.io/pksR/reference/pks_example.md),
ein kleines Panel, das mit dem Paket ausgeliefert wird. Die englische
Fassung ist
[`vignette("pksR")`](https://ofurkancoban.github.io/pksR/articles/pksR.md).

``` r

library(pksR)
options(pksR.lang = "de")
```

## Daten abrufen

[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md)
lädt die gewünschten Jahre aus der neuesten Datenveröffentlichung, prüft
jede Datei gegen ihre SHA-256-Prüfsumme und speichert sie in einem
lokalen Cache:

``` r

# Straftaten insgesamt, auf den neuesten Gebietsstand harmonisiert (Voreinstellung)
insgesamt <- pks_get(offence = "insgesamt")

# Straftaten per Schlüssel, Kurzname oder Bezeichnung
einbruch <- pks_get(offence = c("wohnungseinbruch", "einbruch"))

# Zwei Jahre wie vom BKA veröffentlicht, alle Straftatenschlüssel
veroeffentlicht <- pks_get(years = 2024:2025, harmonize_to = NULL)

# Eine feste Datenversion, für reproduzierbare Arbeiten
d <- pks_get(years = 2015:2025, version = "2026.1")
```

Die drei Möglichkeiten für `harmonize_to`:

| `harmonize_to` | Ergebnis |
|----|----|
| `"latest"` (Voreinstellung) | Harmonisiert auf den Gebietsstand der Veröffentlichung, so gelesen, wie veröffentlicht |
| ein Jahr, etwa `2016` | Die Daten wie veröffentlicht, in Ihrer Sitzung auf den Gebietsstand dieses Jahres harmonisiert (nur vorwärts) |
| `NULL` | Wie veröffentlicht: jedes Jahr mit den Kreisen seines eigenen Gebietsstands |

Methoden und Annahmen beschreibt
[`vignette("harmonization-de")`](https://ofurkancoban.github.io/pksR/articles/harmonization-de.md).

## Straftaten auswählen

`offence` nimmt für jedes Element einen Straftatenschlüssel
(`"435*00"`), einen Kurznamen (`"wohnungseinbruch"` oder englisch
`"residential_burglary"`), eine vollständige Bezeichnung in einer der
beiden Sprachen oder einen Teil einer Bezeichnung (`"einbruch"` wählt
beide Schlüssel zum Wohnungseinbruch und meldet das). Groß- und
Kleinschreibung, Leerzeichen und Umlaute spielen keine Rolle, und ein
genauer Schlüssel, Name oder eine genaue Bezeichnung hat Vorrang vor
einem Teil.
[`pks_offences()`](https://ofurkancoban.github.io/pksR/reference/pks_offences.md)
listet alle Schlüssel mit ihren Namen; die Namen sind Entwürfe, bis der
Maintainer sie geprüft hat.

## Sprachen

Meldungen und Bezeichnungen der Straftaten kommen auf Deutsch oder
Englisch: `options(pksR.lang = "de")` oder `lang = "de"` in
[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md)
und
[`pks_offences()`](https://ofurkancoban.github.io/pksR/reference/pks_offences.md).
Ohne beides entscheidet die Sprache der R-Sitzung.

## Das Beispielpanel

``` r

d <- pks_example()
d[, c("year", "ags", "region_name", "offence_key", "cases", "hz", "harmonized")]
#> # A tibble: 70 × 7
#>     year ags   region_name   offence_key   cases     hz harmonized
#>    <int> <chr> <chr>         <chr>         <dbl>  <dbl> <lgl>     
#>  1  2019 01001 Flensburg     ------        8617   9628. FALSE     
#>  2  2019 02000 Hamburg       ------      206790  11231. FALSE     
#>  3  2019 03159 Göttingen     ------       20829   6349. FALSE     
#>  4  2019 11000 Berlin        ------      513426  14086. FALSE     
#>  5  2019 16063 Wartburgkreis ------        7264.  4397. TRUE      
#>  6  2019 01001 Flensburg     890000        8335   9312. FALSE     
#>  7  2019 02000 Hamburg       890000      199833  10854. FALSE     
#>  8  2019 03159 Göttingen     890000       20571   6270. FALSE     
#>  9  2019 11000 Berlin        890000      495091  13583. FALSE     
#> 10  2019 16063 Wartburgkreis 890000        7222.  4372. TRUE      
#> # ℹ 60 more rows
```

Jedes Ergebnis trägt seine Herkunft als Attribute:

``` r

attributes(d)[c("data_version", "boundary_year", "weights")]
#> $data_version
#> [1] "example"
#> 
#> $boundary_year
#> [1] 2025
#> 
#> $weights
#> [1] "population"
```

Bei Daten aus
[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md)
ist `data_version` die Datenversion, `retrieved_at` der Zeitpunkt des
Downloads und `source_urls` die Dateien der Veröffentlichung, aus denen
die Daten stammen.

## Spalten

| Spalte | Inhalt |
|----|----|
| `year` | Berichtsjahr |
| `ags` | Kreisschlüssel, fünfstellig mit führender Null, etwa `"02000"` für Hamburg |
| `region_name` | Name des Kreises wie veröffentlicht, bei veränderten Kreisen der Name im Ziel-Gebietsstand |
| `offence_key` | Straftatenschlüssel; in harmonisierten Daten der harmonisierte Schlüssel, siehe [`pks_offences()`](https://ofurkancoban.github.io/pksR/reference/pks_offences.md) |
| `offence_key_published` | Nur harmonisierte Daten: der veröffentlichte Schlüssel oder `"SCHLÜSSEL minus SCHLÜSSEL"` bei berechneten Schlüsseln |
| `offence_label` | Bezeichnung in der gewählten Sprache |
| `cases` | Erfasste Fälle (veröffentlicht; `NA` in den PDF-Jahren 2003 bis 2012) |
| `attempts` | Versuche |
| `hz` | Häufigkeitszahl: Fälle je 100.000 Einwohner |
| `cleared` | Aufgeklärte Fälle |
| `clearance_rate` | Aufklärungsquote in Prozent (0, wo die Fallzahl 0 ist, wie in den BKA-Tabellen) |
| `suspects` | Tatverdächtige (Personen; über Schlüssel nicht addierbar) |
| `cases_derived`, `cleared_derived` | Nur PDF-Jahre: `hz * population / 1e5`, weil diese Tabellen Quoten und Einwohnerzahlen, aber keine Fallzahlen enthalten |
| `population` | Veröffentlichte Einwohnerzahl (PDF-Jahre und 2020) |
| `derived_population` | `cases / hz * 1e5`, aus der veröffentlichten Quote abgeleitet; ein Wert je Kreis und Jahr |
| `source_format`, `source_file` | Format und Datei der BKA-Quelle |
| `boundary_year` | Gebietsstand der Zeile |
| `harmonized` | `TRUE`, wenn der Kreis durch die Harmonisierung verändert wurde |
| `weight_type` | `none`, `population` oder `area` |
| `estimated` | `TRUE` für Anteile geteilter Kreise und für abgeleitete Fallzahlen (PDF-Jahre) |

Fallzahlen in harmonisierten Daten sind Dezimalzahlen: Ein geteilter
Kreis gibt Bruchteile seiner Fälle an seine Nachfolger ab, und Runden
würde die Bundessummen verändern.

## Straftatenschlüssel und Brüche

``` r

pks_offences("Diebstahl")[, c("offence_key", "name", "label")]
#> # A tibble: 12 × 3
#>    offence_key name                     label                                   
#>    <chr>       <chr>                    <chr>                                   
#>  1 ****00      diebstahl                Diebstahl insgesamt                     
#>  2 ***100      kraftwagendiebstahl      Diebstahl insgesamt von Kraftwagen eins…
#>  3 ***200      kraftrad_diebstahl       Diebstahl insgesamt von Mopeds und Kraf…
#>  4 ***300      fahrraddiebstahl         Diebstahl insgesamt von Fahrrädern eins…
#>  5 *26*00      ladendiebstahl           Ladendiebstahl insgesamt                
#>  6 *50*00      diebstahl_an_aus_kfz     Diebstahl insgesamt an/aus Kraftfahrzeu…
#>  7 *90*00      taschendiebstahl         Taschendiebstahl insgesamt              
#>  8 3***00      einfacher_diebstahl      Diebstahl ohne erschwerende Umstände §§…
#>  9 326*00      einfacher_ladendiebstahl Einfacher Ladendiebstahl                
#> 10 4***00      schwerer_diebstahl       Diebstahl unter erschwerenden Umständen…
#> 11 435*00      wohnungseinbruch         Wohnungseinbruchdiebstahl §§ 244 Abs. 1…
#> 12 436*00      tageswohnungseinbruch    Tageswohnungseinbruchdiebstahl §§ 244 A…
```

Die Kreistabellen enthalten nur eine Auswahl von Straftatenschlüsseln,
und Schlüssel ändern sich über die Zeit. Vor jeder Zeitreihe die
bekannten methodischen Brüche prüfen:

``` r

b <- pks_breaks()
b[b$comparable == "no", c("first_year", "offence_key", "type")]
#> # A tibble: 8 × 3
#>   first_year offence_key                        type       
#>        <int> <chr>                              <chr>      
#> 1       2010 220000;222000                      key_change 
#> 2       2013 NA                                 denominator
#> 3       2024 NA                                 denominator
#> 4       2017 111000                             definition 
#> 5       2018 621020;621021;621100;621110;621120 key_change 
#> 6       2012 *50*00                             definition 
#> 7       2024 730000                             law_change 
#> 8       2016 980100                             definition
```

## Quoten, Prüfungen und Zitieren

Nach dem Filtern oder Harmonisieren die Quoten aus den Fallzahlen neu
berechnen und die Prüfungen laufen lassen:

``` r

r <- pks_rates(d, per = 1000)
head(r[, c("year", "ags", "offence_key", "cases", "rate")])
#> # A tibble: 6 × 5
#>    year ags   offence_key   cases  rate
#>   <int> <chr> <chr>         <dbl> <dbl>
#> 1  2019 01001 ------        8617   96.3
#> 2  2019 02000 ------      206790  112. 
#> 3  2019 03159 ------       20829   63.5
#> 4  2019 11000 ------      513426  141. 
#> 5  2019 16063 ------        7264.  44.0
#> 6  2019 01001 890000        8335   93.1
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
```

Arbeiten mit diesen Daten sollten das Paket, die Datenversion und die
Quellen zitieren.
[`pks_cite()`](https://ofurkancoban.github.io/pksR/reference/pks_cite.md)
liefert alle fünf Einträge, einschließlich der Lizenz der BKA-Daten
(Datenlizenz Deutschland, Namensnennung, Version 2.0):

``` r

pks_cite()
```

## Cache

Downloads liegen unter `tools::R_user_dir("pksR", "cache")`, ein Ordner
je Datenversion. Eine Veröffentlichung ändert sich nie; eine Datei im
Cache wird verwendet, bis ihre Prüfsumme nicht mehr stimmt.

``` r

pks_cache_info()
pks_cache_clear(version = "2026.1")
```
