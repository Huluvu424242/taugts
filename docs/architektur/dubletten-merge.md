# Dubletten kontrolliert zusammenführen

## Ziel

Eine fachliche Dublette besitzt eine andere stabile UUID, beschreibt aber dasselbe reale Produkt oder denselben realen Ort. Beim Zusammenführen bleibt die bereits lokale UUID kanonisch. Die importierte UUID wird als Aliasreferenz im Importplan erhalten, damit Story #22 sie bei der atomaren Übernahme persistieren und spätere Importe wiedererkennen kann.

## Stammdaten

Vergleichbare Felder werden vor dem Merge gegenübergestellt. Für jedes widersprüchliche Feld kann unabhängig entschieden werden, ob der lokale oder der importierte Wert in den kanonischen Datensatz eingeht. Nicht ausdrücklich ausgewählte Felder behalten den lokalen Wert. Die UUID selbst ist nicht auswählbar; sie bleibt die kanonische lokale UUID.

### Produkte

- Ein identischer Barcode ist ein starkes Dublettensignal. Unterschiedliche nicht-leere Barcodes werden niemals automatisch vereinigt; die Auswahl muss bewusst erfolgen.
- Ohne Barcode basiert die Dublettenerkennung auf normalisiertem Namen und Produkttyp. Der Name wird nicht automatisch überschrieben.
- Beim Merge werden `erlebnisPositionen.produktId`, `preisbeobachtungen.produktId`, `bewertungen.objektId` und produktbezogene Kategoriezuordnungen von der Import-UUID auf die kanonische UUID umgeschrieben.

### Orte

- Orte werden nur als mögliche Dublette erkannt, wenn normalisierter Name, Ortstyp und Adresse zusammenpassen.
- Abweichende Adress-, Koordinaten-, OSM- oder Notizwerte bleiben sichtbare Stammdatenkonflikte und werden nicht still überschrieben.
- Beim Merge werden Ortsbezüge in Erlebnissen, Preisbeobachtungen, Produktbewertungen und Ortsbewertungen auf die kanonische UUID umgeschrieben.

## Historie bleibt unverändert

Der Merge ersetzt ausschließlich Referenzen auf den zusammengeführten Stammdatensatz. IDs, Zeitpunkte, Werte und Kriterienkontext historischer Erlebnisse, Positionen, Preisbeobachtungen sowie Produkt- und Ortsbewertungen bleiben unverändert. Unterschiedliche Preise oder Bewertungen werden weder verdichtet noch überschrieben.

## Alias und spätere Wiedererkennung

`ImportDublettenMergeErgebnis` enthält zusätzlich zum umgeschriebenen Importdokument eine `ImportAliasReferenz` mit importierter Alias-ID und kanonischer lokaler ID. Die eigentliche persistente Speicherung dieser Aliasreferenz gehört zusammen mit allen anderen Schreiboperationen zur atomaren Importausführung in Story #22. Bis dahin bleibt der gesamte Merge ein unverbindlicher Plan und verändert keine lokalen Daten.
