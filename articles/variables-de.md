# Detailspalten und Anwendungsfälle

Ab der Datenveröffentlichung 2026.2 liefert
[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md)
mehr als Fallzahlen und Häufigkeitszahlen: den amtlichen Namen jedes
Kreises, die Kreisart, Fälle mit Schusswaffe sowie Tatverdächtige nach
Geschlecht und Staatsangehörigkeit. Diese Vignette beschreibt die
Spalten, die Regeln für ihre Verwendung und einige typische
Auswertungen. Alle ausführbaren Beispiele verwenden
[`pks_example()`](https://ofurkancoban.github.io/pksR/reference/pks_example.md),
ein kleines Panel, das mit dem Paket ausgeliefert wird (fünf Kreise,
zwei Straftatenschlüssel, 2019 bis 2025), und laufen daher ohne
Internet.

``` r

d <- pksR::pks_example()
```

## Die Spalten

| Spalte | Inhalt | Jahre |
|----|----|----|
| `region_name_official` | Name des Kreises im BBSR-Umsteigeschlüssel zum Gebietsstand der Zeile; in einem harmonisierten Panel ein Name je Kreis | alle |
| `district_type` | Kreisart wie veröffentlicht: `KfS` (kreisfreie Stadt), `LK` (Landkreis), `K` (Kreis), `SK` (Stadtkreis), `RV` (Regionalverband) | ab 2013 |
| `firearm_threatened` | Fälle, in denen mit einer Schusswaffe gedroht wurde | ab 2013 |
| `firearm_fired` | Fälle, in denen geschossen wurde | ab 2013 |
| `suspects_male`, `suspects_female` | Tatverdächtige nach Geschlecht; zusammen ergeben sie `suspects` | ab 2013 |
| `suspects_non_german` | Nichtdeutsche Tatverdächtige | ab 2013 |

Die Jahrbücher 2003 bis 2012 veröffentlichen keines der Detailfelder,
dort sind sie `NA`. Bei Datenveröffentlichungen vor 2026.2 sind alle
Detailspalten `NA`, und
[`pks_get()`](https://ofurkancoban.github.io/pksR/reference/pks_get.md)
weist einmal je Sitzung darauf hin. Die in den BKA-Tabellen gedruckten
Anteile (Anteil der Versuche, Anteil nichtdeutscher Tatverdächtiger)
sind nicht enthalten: Sie folgen aus den Zahlen, und ein Anteil lässt
sich nicht mit Gewichten des Umsteigeschlüssels auf einen anderen
Gebietsstand übertragen, eine Zahl dagegen schon.

`region_name` bleibt der Name wie veröffentlicht, dessen Schreibweise
sich zwischen den Jahren ändert (“SK Mülheim a.d.Ruhr”, “KfS Mülheim an
der Ruhr”). `region_name_official` ist für einen Kreis in jedem Jahr
eines harmonisierten Panels gleich und eignet sich besser für Tabellen
und Karten:

``` r

unique(d[, c("ags", "region_name", "region_name_official", "district_type")])
#> # A tibble: 5 × 4
#>   ags   region_name   region_name_official          district_type
#>   <chr> <chr>         <chr>                         <chr>        
#> 1 01001 Flensburg     Flensburg, Stadt              KfS          
#> 2 02000 Hamburg       Hamburg, Freie und Hansestadt KfS          
#> 3 03159 Göttingen     Göttingen                     LK           
#> 4 11000 Berlin        Berlin, Stadt                 KfS          
#> 5 16063 Wartburgkreis Wartburgkreis                 LK
```

## Regeln für die Detailspalten

1.  **Tatverdächtige sind Personen, keine Fälle.** Wer des Diebstahls
    und des Betrugs verdächtigt wird, zählt unter beiden Schlüsseln.
    Tatverdächtige dürfen daher nie über Straftatenschlüssel summiert
    werden. Innerhalb eines Schlüssels gilt:
    `suspects_male + suspects_female` ergibt `suspects`. Für Schlüssel,
    die als Differenz zweier veröffentlichter Schlüssel berechnet werden
    (`890000` im Jahr 2014), sind die Tatverdächtigenspalten `NA`.
2.  **Tatverdächtige sind keine Täter.** Tatverdächtig ist, wen die
    Polizei am Ende der Ermittlungen für hinreichend verdächtig hält.
    Über Anklagen oder Verurteilungen sagt die PKS nichts.
3.  **Nichtdeutsche Tatverdächtige sind nicht nur Einwohner.** Dazu
    gehören Personen ohne Wohnsitz in Deutschland (Touristen, Pendler,
    reisende Täter) und Delikte, die nur Nichtdeutsche begehen können,
    etwa Verstöße gegen das Aufenthalts- und das Asylgesetz (Schlüssel
    `725000`). Schlüssel `890000` (Straftaten insgesamt ohne diese)
    nimmt den zweiten Teil heraus. Eine Bevölkerung nach
    Staatsangehörigkeit veröffentlicht die PKS nicht; solche Nenner
    müssen aus anderen Quellen kommen, etwa aus INKAR über das Paket
    [`inkaR`](https://CRAN.R-project.org/package=inkaR).
4.  **Harmonisierte Werte können Bruchzahlen sein.** Wo ein Kreis
    geteilt wurde, werden Zahlen mit Bevölkerungs- oder Flächengewichten
    aufgeteilt, und die Zeile hat `estimated = TRUE`. Durch die
    Harmonisierung veränderte Kreise erhalten ihre Kreisart in der
    neuesten Tabelle.
5.  **Raten werden neu berechnet, nie gemittelt.**
    [`pks_rates()`](https://ofurkancoban.github.io/pksR/reference/pks_rates.md)
    berechnet die HZ für `cases` neu. Raten der Detailzahlen entstehen
    genauso: erst die Zahlen summieren, dann durch die Bevölkerung
    derselben Zeilen teilen.

## Anwendungsfall 1: Städte und Landkreise

Vergleich der Kriminalität in kreisfreien Städten (`KfS`) und
Landkreisen (`LK`). Die Rate einer Gruppe ist die Summe ihrer Fälle
geteilt durch die Summe ihrer Bevölkerung, nicht der Mittelwert der
Kreisraten:

``` r

tot <- d[d$offence_key == "------", ]
tot$pop <- dplyr::coalesce(tot$population, tot$derived_population)
by_type <- dplyr::summarise(
  dplyr::group_by(tot, year, district_type),
  cases = sum(cases), pop = sum(pop), .groups = "drop"
)
by_type$hz <- by_type$cases / by_type$pop * 1e5
by_type[by_type$year == 2025, ]
#> # A tibble: 2 × 5
#>    year district_type  cases     pop     hz
#>   <int> <chr>          <dbl>   <dbl>  <dbl>
#> 1  2025 KfS           720003 5644156 12757.
#> 2  2025 LK             30786  482985  6374.
```

In einem vollständigen Panel ergibt derselbe Code die Reihen für Städte
und Landkreise in ganz Deutschland ab 2013.

## Anwendungsfall 2: Geschlecht der Tatverdächtigen

Der Anteil weiblicher Tatverdächtiger nach Kreis und Jahr:

``` r

tot$female_share <- round(tot$suspects_female / tot$suspects * 100, 1)
tot[tot$year %in% c(2019, 2025), c("year", "region_name_official", "suspects", "female_share")]
#> # A tibble: 10 × 4
#>     year region_name_official          suspects female_share
#>    <int> <chr>                            <dbl>        <dbl>
#>  1  2019 Flensburg, Stadt                 3450          23.5
#>  2  2019 Hamburg, Freie und Hansestadt   66216          22.5
#>  3  2019 Göttingen                        8774          24.8
#>  4  2019 Berlin, Stadt                  136704          26.4
#>  5  2019 Wartburgkreis                    3605.         23.5
#>  6  2025 Flensburg, Stadt                 3650          26.5
#>  7  2025 Hamburg, Freie und Hansestadt   64045          24  
#>  8  2025 Göttingen                        9703          25.4
#>  9  2025 Berlin, Stadt                  132281          25.9
#> 10  2025 Wartburgkreis                    3459          26.3
```

## Anwendungsfall 3: Nichtdeutsche Tatverdächtige mit und ohne ausländerrechtliche Verstöße

Der Anteil nichtdeutscher Tatverdächtiger hängt davon ab, ob Verstöße
gegen das Aufenthalts- und das Asylgesetz mitgezählt werden. Der
Vergleich von `------` (alle Straftaten) mit `890000` (ohne diese)
zeigt, wie stark:

``` r

y25 <- d[d$year == 2025, ]
y25$non_german_share <- round(y25$suspects_non_german / y25$suspects * 100, 1)
wide <- merge(
  y25[y25$offence_key == "------", c("region_name_official", "non_german_share")],
  y25[y25$offence_key == "890000", c("region_name_official", "non_german_share")],
  by = "region_name_official", suffixes = c("_all", "_without_725000")
)
wide
#>            region_name_official non_german_share_all
#> 1                 Berlin, Stadt                 47.3
#> 2              Flensburg, Stadt                 35.8
#> 3                     Göttingen                 33.4
#> 4 Hamburg, Freie und Hansestadt                 52.9
#> 5                 Wartburgkreis                 22.0
#>   non_german_share_without_725000
#> 1                            43.3
#> 2                            34.5
#> 3                            32.3
#> 4                            47.4
#> 5                            21.9
```

Ein Anteil an den Tatverdächtigen ist keine Kriminalitätsrate einer
Bevölkerungsgruppe: Dafür müsste die Zahl der nichtdeutschen
Tatverdächtigen durch die nichtdeutsche Bevölkerung geteilt werden, die
die PKS nicht veröffentlicht, und die Einschränkungen aus Regel 3
gelten.

## Anwendungsfall 4: Fälle mit Schusswaffe

Fälle mit Schusswaffe sind selten, einzelne Kreisjahre schwanken daher
stark. Vor der Berechnung einer Rate je 100.000 Einwohner sollten
mehrere Jahre zusammengefasst werden:

``` r

pooled <- dplyr::summarise(
  dplyr::group_by(tot, region_name_official),
  threatened = sum(firearm_threatened), fired = sum(firearm_fired),
  person_years = sum(pop), .groups = "drop"
)
pooled$fired_per_100k <- pooled$fired / pooled$person_years * 1e5
pooled
#> # A tibble: 5 × 5
#>   region_name_official          threatened  fired person_years fired_per_100k
#>   <chr>                              <dbl>  <dbl>        <dbl>          <dbl>
#> 1 Berlin, Stadt                     2564   2427      25758774            9.42
#> 2 Flensburg, Stadt                    80     50        646022            7.74
#> 3 Göttingen                          154    115       2286819            5.03
#> 4 Hamburg, Freie und Hansestadt      913    649      13001128            4.99
#> 5 Wartburgkreis                       30.0   61.9     1115339.           5.55
```

## Mit den vollständigen Daten

Dieselben Spalten kommen ab der Veröffentlichung 2026.2 mit jeder
Abfrage, wie veröffentlicht und harmonisiert:

``` r

# Alle Kreise, Straftaten insgesamt, 2013 bis 2025, auf den neuesten Gebietsstand harmonisiert
panel <- pksR::pks_get(years = 2013:2025, offence = "total")

# Wie veröffentlicht: die Kreise und Namen des jeweiligen Jahres
published <- pksR::pks_get(years = 2013:2025, offence = "total", harmonize_to = NULL)

# Auf einen anderen Gebietsstand harmonisiert: die Detailzahlen werden wie die
# Fallzahlen mit den Gewichten des Umsteigeschlüssels übertragen
p2016 <- pksR::pks_get(years = 2013:2016, offence = "total", harmonize_to = 2016)
```

[`pks_validate()`](https://ofurkancoban.github.io/pksR/reference/pks_validate.md)
prüft ein Panel; für die Detailspalten sollte zusätzlich geprüft werden,
dass `suspects_male + suspects_female` gleich `suspects` ist und dass
`suspects_non_german` und die Schusswaffenfälle ihre Gesamtzahlen nicht
übersteigen. Die Pipeline veröffentlicht keine Daten, wenn eine dieser
Bedingungen verletzt ist.

## Ohne R

Die Parquet-Dateien einer Veröffentlichung enthalten alle Spalten. Die
CSV-Dateien je Jahr behalten die Spalten der Veröffentlichung 2026.1 und
haben eine Zwillingsdatei `pks_kreis_<Jahr>_<Variante>_details.csv.gz`
mit `year`, `ags`, `offence_key` und den Detailspalten in derselben
Zeilenfolge; beide werden über diese drei Spalten verbunden. Die
amtlichen Namen stehen in `boundary_map.csv` der Veröffentlichung
(Spalte `to_name` der letzten Periode für den neuesten Gebietsstand).
