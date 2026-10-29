# Harmonisierung: Methoden, Annahmen und Sensitivität

Die Kreise in Deutschland wurden seit 2003 mehrfach zusammengelegt und
geteilt, die meisten bei den Kreisreformen in Sachsen-Anhalt (2007),
Sachsen (2008) und Mecklenburg-Vorpommern (2011). Ein Kreisschlüssel von
2005 gibt es 2025 womöglich nicht mehr, und ein Kreis von 2025 kann
Teile mehrerer früherer Kreise umfassen. Ein Vergleich über die Zeit
braucht daher die Daten aller Jahre auf einem Gebietsstand. Diese
Vignette beschreibt, wie `pksR` und seine Pipeline das tun und auf
welchen Annahmen die Ergebnisse beruhen. Die englische Fassung ist
[`vignette("harmonization")`](https://ofurkancoban.github.io/pksR/articles/harmonization.md).

``` r

library(pksR)
```

## Der Umsteigeschlüssel

Die Zuordnung der Gebiete stammt aus den Umsteigeschlüsseln des
Bundesinstituts für Bau-, Stadt- und Raumforschung (BBSR). Für jedes
Jahr ordnen sie jeden Kreis zum 31. Dezember des Jahres *t* den Kreisen
zum 31. Dezember von *t + 1* zu, mit zwei Arten von Gewichten:

- **Bevölkerung**: der Anteil der Einwohner des Kreises, der zu jedem
  Nachfolger wechselt;
- **Fläche**: der Anteil seiner Fläche.

Jede Datenveröffentlichung enthält den verwendeten Umsteigeschlüssel,
`boundary_map.csv`, mit einer Zeile je Jahr, Ausgangskreis und
Zielkreis. Es gibt drei Arten von Zeilen:

| `source` | Bedeutung |
|----|----|
| `bbsr` | Zeile der BBSR-Datei, unverändert |
| `manual` | Ersetzt eine fehlerhafte BBSR-Zeile, mit Begründung (etwa ein Schlüsselfehler im BBSR-Blatt 2011-2012, wo ein Teil von Bernkastel-Wittlich `07231` unter Trier-Saarburg `07235` steht) |
| `destatis` | Eine Übertragung einer Gemeinde zwischen Kreisen, die im BBSR-Schlüssel fehlt, aus den Gebietsänderungslisten von Destatis, mit Begründung |

Manuelle und Destatis-Zeilen, die der Maintainer noch nicht geprüft hat,
tragen `status = "draft"`.

## Die Methode

Für einen Ziel-Gebietsstand *T* werden die jährlichen Schritte vom
Gebietsstand jedes Jahres bis *T* verkettet. Dann gilt je Jahr:

1.  **Fallzahlen werden übertragen, Quoten nicht.** Fälle, Versuche,
    aufgeklärte Fälle und Tatverdächtige jedes Ausgangskreises werden
    mit seinem Gewicht multipliziert und je Zielkreis summiert. Quoten
    lassen sich nicht übertragen: Die Häufigkeitszahl eines
    zusammengelegten Kreises ist weder Summe noch Mittel der alten
    Häufigkeitszahlen.
2.  **Quoten werden neu berechnet** für jeden veränderten Kreis aus den
    übertragenen Fallzahlen und der übertragenen Einwohnerzahl:
    `hz = cases / population * 1e5`,
    `clearance_rate = cleared / cases * 100`. Unveränderte Kreise
    behalten die veröffentlichten Werte.
3.  **Summen bleiben erhalten.** Die Bundessumme jeder Fallzahl und der
    Einwohnerzahl ist vor und nach der Harmonisierung gleich, geprüft
    für jedes Jahr und jeden Straftatenschlüssel.
4.  **Nur vorwärts.** Daten werden von älteren auf neuere Gebietsstände
    übertragen. Ein Ziel-Gebietsstand vor dem eigenen Gebietsstand eines
    Jahres wird abgelehnt.
5.  **Straftatenschlüssel** werden mit der Straftatenzuordnung der
    Veröffentlichung auf harmonisierte Schlüssel abgebildet
    ([`pks_offences()`](https://ofurkancoban.github.io/pksR/reference/pks_offences.md)).
    Ein veröffentlichter Schlüssel wird nie stillschweigend zu seinem
    über- oder untergeordneten Schlüssel addiert.

Zusammenlegungen sind exakt (Gewicht 1). Teilungen sind Schätzungen: Die
Gewichte unterstellen, dass sich die Fälle innerhalb des alten Kreises
wie die Einwohner (oder wie die Fläche) verteilen. Zeilen, die auf einem
solchen Anteil beruhen, tragen `estimated = TRUE`, ebenso die PDF-Jahre
2003 bis 2012, deren Fallzahlen aus den veröffentlichten Quoten
abgeleitet sind.

## Ziel-Gebietsstand und Gewichtung wählen

``` r

# Neuester Gebietsstand, Bevölkerungsgewichte: das veröffentlichte Panel
neuester <- pks_get(years = 2005:2015)

# Gebietsstand 2011, nach der Reform in Mecklenburg-Vorpommern
d2011 <- pks_get(years = 2005:2011, harmonize_to = 2011)

# Flächen- statt Bevölkerungsgewichte
flaeche <- pks_get(years = 2005:2015, weights = "area")
```

Der neueste Gebietsstand wird so gelesen, wie er veröffentlicht ist, und
ist am schnellsten. Andere Ziel-Gebietsstände werden in Ihrer Sitzung
aus den veröffentlichten Daten und dem Umsteigeschlüssel derselben
Veröffentlichung berechnet; für den neuesten Gebietsstand ergeben beide
Wege dasselbe Panel (geprüft auf 1e-10 für alle Jahre 2003 bis 2025).

## Sensitivität

Jedes harmonisierte Panel beruht auf zwei Entscheidungen: der Gewichtung
geteilter Kreise und der Harmonisierung selbst. Ergebnisse, die unter
jeder Wahl gelten, hängen weniger von den genannten Annahmen ab.

### Bevölkerungs- oder Flächengewichte

Die Gewichte unterscheiden sich nur dort, wo Kreise geteilt wurden.
[`pks_compare_weights()`](https://ofurkancoban.github.io/pksR/reference/pks_compare_weights.md)
stellt beide Fassungen eines Panels nebeneinander:

``` r

d <- pks_get(years = 2005:2012, offence = "insgesamt")
w <- pks_compare_weights(d)   # lädt dieselbe Abfrage mit Flächengewichten
w[abs(w$relative_difference) > 0.01, c("year", "ags", "region_name", "cases_population", "cases_area")]
```

Das Ergebnis enthält die Fälle und die neu berechnete HZ unter beiden
Gewichtungen, die Differenz und die relative Differenz. Zusammengelegte
und unveränderte Kreise sind gleich; die Bundessummen sind unter beiden
Gewichtungen dieselben. Eine Regression lässt sich zweimal schätzen,
einmal je Spalte, um zu sehen, ob sich ein Koeffizient bewegt:

``` r

w$log_hz_population <- log(w$hz_population)
w$log_hz_area <- log(w$hz_area)
# z. B. dasselbe Modell mit zweifach fixen Effekten auf log_hz_population und auf log_hz_area
```

### Harmonisiert oder wie veröffentlicht

Die dritte Möglichkeit ist, gar nicht zu harmonisieren.
`harmonize_to = NULL` liefert jedes Jahr mit seinen eigenen Kreisen, ein
unbalanciertes Panel: Zusammengelegte und geteilte Kreise tauchen auf
und verschwinden, und kein Wert ist geschätzt.

``` r

veroeffentlicht <- pks_get(years = 2005:2012, offence = "insgesamt", harmonize_to = NULL)
table(veroeffentlicht$year)    # die Zahl der Kreise ändert sich mit den Reformen
harmonisiert <- pks_get(years = 2005:2012, offence = "insgesamt")
table(harmonisiert$year)       # jedes Jahr dieselben 400 Kreise
```

Zwei übliche Wege mit den veröffentlichten Daten:

- **Unbalanciertes Panel:** alle Kreise wie veröffentlicht, mit
  Kreis-fixen Effekten. Ein reformierter Kreis wird nach der Reform zu
  einer neuen Einheit.
- **Balanciertes Panel unveränderter Kreise:** nur Kreise, deren
  Schlüssel und Gebiet sich im Zeitraum nicht geändert haben. Nichts ist
  geschätzt, aber die reformierten Regionen (große Teile Ostdeutschlands
  zwischen 2007 und 2011) fallen heraus; das kann Ergebnisse verzerren,
  wenn sich die Kriminalität dort anders entwickelt hat.

``` r

# Kreise, die in jedem Jahr des Zeitraums mit demselben Schlüssel vorkommen.
# Ein Kreis, der einen anderen aufnimmt, behält seinen Schlüssel (der
# Wartburgkreis 2021): auch solche Kreise anhand des Umsteigeschlüssels entfernen.
stabil <- Reduce(intersect, split(veroeffentlicht$ags, veroeffentlicht$year))
balanciert <- veroeffentlicht[veroeffentlicht$ags %in% stabil, ]
# Harmonisierte Zeilen, die auf Teilungsgewichten beruhen
sum(harmonisiert$estimated)
```

Der Vergleich einer Schätzung auf dem harmonisierten Panel
(Bevölkerungsgewichte), dem harmonisierten Panel (Flächengewichte), dem
unbalancierten Panel und dem balancierten Panel unveränderter Kreise
zeigt, wie stark sie von der Harmonisierung abhängt.

## Quoten mit eigener Einwohnerzahl

Die Einwohnerzahl für die Quoten ist die veröffentlichte, wo das BKA sie
angibt (PDF-Jahre und 2020), sonst aus Fallzahl und Häufigkeitszahl
abgeleitet. Eine amtliche Bevölkerungsreihe kann sie ersetzen:

``` r

d <- pks_example()
bev <- unique(data.frame(year = d$year, ags = d$ags, population = d$derived_population))
head(pks_rates(d, population = bev)[, c("year", "ags", "offence_key", "hz")])
#> # A tibble: 6 × 4
#>    year ags   offence_key     hz
#>   <int> <chr> <chr>        <dbl>
#> 1  2019 01001 ------       9628.
#> 2  2019 02000 ------      11231.
#> 3  2019 03159 ------       6349.
#> 4  2019 11000 ------      14086.
#> 5  2019 16063 ------       4397.
#> 6  2019 01001 890000       9312.
```
