# Statistik-Excel-Export

Der Statistikexport ist ein bewusst ausgelöster, vollständig lokaler Datenaustauschweg. Er verwendet keine Netzwerkverbindung und verändert den lokalen Datenbestand nicht.

## Verantwortlichkeiten

Die Implementierung trennt vier Verantwortungsbereiche:

1. `SqliteStatistikExportService` liest die für den Export benötigten historischen Daten aus SQLite und bildet fachliche Kennzahlen.
2. `StatistikExportDaten` und seine Teilmodelle transportieren die aggregierten Produkt-, Orts- und Verlaufsdaten ohne Abhängigkeit von Flutter oder dem Excel-Format.
3. `StatistikExcelService` erzeugt aus diesen Modellen die `.xlsx`-Arbeitsmappe einschließlich Formatierung und Liniendiagramm.
4. `BinaerExportZielService` kapselt den plattformspezifischen Speicherdialog. Die Oberfläche kennt weder SQLite noch die konkrete Dateisystem-API.

Dadurch bleiben Aggregation, Dateiformat, Oberfläche und Plattformintegration unabhängig testbar.

## Fachliche Aggregation

Für Qualitätskennzahlen werden ausschließlich numerische Kriterienwerte mit dem historischen Eingabetyp `wertung` verwendet. Der beim Bewertungsdatensatz gespeicherte Snapshot des Eingabetyps hat Vorrang; nur für ältere Datensätze ohne Snapshot wird auf den aktuellen Kriterien-Datensatz zurückgefallen. Andere Eingabetypen werden nicht als Qualitätswert interpretiert.

### Produktbewertungen

Produktwerte werden über die Erlebnisposition mit dem Produkt verknüpft. Der Ort stammt aus dem zugehörigen Erlebnis in der Reihenfolge Konsumort, Kaufort, allgemeiner Ort. Fehlt ein Ort, wird die fachliche Gruppe `Ohne Ort` verwendet. Pro Produkt/Ort-Kombination entstehen Minimum, Maximum, arithmetischer Mittelwert und Anzahl der einbezogenen Wertungen. Nicht vorhandene Kombinationen existieren im Exportmodell nicht und bleiben deshalb in der Excel-Matrix leer.

### Ortsbewertungen

Ortswerte werden ausschließlich über `ortsbewertungen` verknüpft. Pro Ort entstehen Minimum, Maximum, arithmetischer Mittelwert und Anzahl aller einbezogenen Qualitätswertungen.

### Ortsverlauf

Ein Verlaufspunkt entspricht einer einzelnen historischen `ortsbewertung`. Sind darin mehrere Qualitätskriterien gespeichert, wird für diesen Bewertungszeitpunkt deren arithmetischer Mittelwert gebildet. Damit repräsentiert die Linie den jeweiligen historischen Gesamtstand der Ortsbewertung und keine Zeitreihe eines einzelnen Kriteriums. Historische Kriterien-Snapshots einschließlich ihrer Version bleiben unverändert in der Datenbank erhalten; der Excel-Export schreibt sie für diese Gesamtlinie nicht zu einer gemeinsamen Einzelkriterienreihe um.

## XLSX-Erzeugung

Für die lokale Arbeitsmappenerzeugung wird `excel_community` verwendet. Die Abhängigkeit ist in `ATTRIBUTIONS.md` dokumentiert. Die Arbeitsmappe enthält:

- `Produktbewertungen` mit zweistufigen Ortsüberschriften und drei Kennzahlspalten je Ort,
- `Ortsbewertungen` mit bester, schlechtester und durchschnittlicher Bewertung je Ort,
- `Ortsverlauf` mit tabellarischen Verlaufsdaten und einem Liniendiagramm mit einer Serie je Ort.

Beste und schlechteste Werte erhalten zusätzlich eine grüne beziehungsweise rote Hintergrundmarkierung. Die Bedeutung bleibt über die ausgeschriebenen Spaltenüberschriften unabhängig von Farbe erkennbar. Kopfzeilen beziehungsweise die erste Spalte werden soweit sinnvoll fixiert; fehlende Werte bleiben leere Zellen.

## Fehler- und Speicherverhalten

Die Datei wird zunächst vollständig im Speicher erzeugt und erst danach an den System-Speicherdialog übergeben. Ein Abbruch des Dialogs gilt als neutraler Nutzerabbruch. Fehler beim Lesen, Erzeugen oder Speichern werden an der Oberfläche verständlich gemeldet. Während eines laufenden Exports ist die Aktion gegen Mehrfachauslösung gesperrt. Da der Export ausschließlich liest, bleiben die lokalen Daten in allen Fehlerfällen unverändert.
