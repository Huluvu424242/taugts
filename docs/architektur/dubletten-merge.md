# Dubletten kontrolliert zusammenführen

## Ziel

Eine fachliche Dublette besitzt eine andere stabile UUID, beschreibt aber dasselbe reale Produkt oder denselben realen Ort. Beim Zusammenführen bleibt die bereits lokale UUID kanonisch. Die importierte UUID wird als Aliasreferenz lokal gespeichert, damit spätere Importe denselben realen Datensatz wiedererkennen.

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

`ImportDublettenMergeErgebnis` enthält zusätzlich zum umgeschriebenen Importdokument eine `ImportAliasReferenz` mit importierter Alias-ID und kanonischer lokaler ID. Bei der bestätigten Importausführung wird diese Referenz in `import_aliases` innerhalb derselben Datenbanktransaktion wie die Fachdaten gespeichert. Schlägt die Aliasprüfung oder eine andere Schreiboperation fehl, werden Fachdaten und neue Aliasreferenzen gemeinsam zurückgerollt.

Vor einer späteren Konfliktanalyse lädt `ImportAliasRepository` die bekannten lokalen Aliasreferenzen und normalisiert importierte Produkt- und Orts-IDs sowie die davon abhängigen Erlebnis-, Preis- und Bewertungsbezüge auf die jeweils kanonische ID. Dadurch erzeugt eine bereits zusammengeführte frühere UUID bei einem erneuten Import keine neue technische Dublette.

Alias-Ketten werden bis zur endgültigen kanonischen ID aufgelöst. Widersprüchliche Zuordnungen und Zyklen werden abgewiesen. Die Aliasdaten bleiben ausschließlich lokal und werden nicht als fachliche Bewertungs- oder Nutzungsdaten behandelt.
