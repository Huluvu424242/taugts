# Sichere Importvalidierung

Importdateien gelten grundsätzlich als nicht vertrauenswürdig. `ImportValidierungsService` analysiert einen Text vollständig, bevor eine spätere Importstory daraus Änderungen am lokalen Bestand ableiten darf. Die Validierung selbst besitzt deshalb keinerlei Schreibzugriff auf die SQLite-Datenbank.

## Reihenfolge der Prüfung

Die Prüfung erfolgt bewusst von außen nach innen:

1. UTF-8-Bytegröße begrenzen.
2. JSON syntaktisch dekodieren.
3. Verschachtelungstiefe und Gesamtzahl der JSON-Knoten begrenzen.
4. Wurzelobjekt, Formatkennung `taugts-export` und Schemaversion prüfen.
5. Unterstützte ältere Versionen ausschließlich im Speicher vorwärts migrieren.
6. Pflichtsammlungen, Datensatzformen, IDs, Datentypen, Enumwerte, Zeitstempel und Dezimaldarstellungen prüfen.
7. Fachliche Regeln für Erlebnisstatus, Zeitkombinationen, Anzahl, Preise, Währung und Kriterienversionen prüfen.
8. Erst danach alle Referenzen zwischen Profilen, Objekten, Orten, Erlebnissen, Positionen, Preisen, Bewertungen, Ortsbewertungen und Kategorien prüfen.

Ein ungültiger Import liefert strukturierte Fehler mit Code, JSON-Pfad und verständlicher Nachricht. Ein normalisiertes Dokument wird nur zurückgegeben, wenn keine Fehler vorliegen.

## Sicherheitsgrenzen

Standardmäßig gelten folgende Grenzen:

| Grenze | Wert |
| --- | ---: |
| Dateigröße | 10 MiB |
| maximale JSON-Tiefe | 40 Ebenen |
| maximale JSON-Knoten | 250.000 |
| Einträge je fachlicher Sammlung | 50.000 |

Die Werte verhindern, dass offensichtlich unangemessen große oder extrem verschachtelte Eingaben ungeprüft weiterverarbeitet werden. Sie sind als `ImportValidierungsGrenzen` testbar konfigurierbar.

## Versionierung und Migration

Die aktuelle Austauschformatversion ist `1`. Dateien mit einer höheren Version werden abgewiesen, statt still wie Version 1 interpretiert zu werden.

Für die vor der ersten veröffentlichten Austauschformatversion verwendete Vorabversion `0` besteht eine explizite Vorwärtsmigration. Version 0 entspricht strukturell dem späteren Version-1-Dokument, kann aber die damals noch nicht vorbereiteten Sammlungen `kategorien` und `kategorieZuordnungen` weglassen. Die Migration ergänzt beide als leere Arrays und setzt `schemaVersion` auf `1`. Sie findet ausschließlich im Arbeitsspeicher statt und verändert weder die Eingabedatei noch lokale Daten.

Jede künftige Schemaversion benötigt eine explizite, getestete Migration von der jeweils unterstützten Vorgängerversion. Fehlt eine notwendige Migrationsstufe, wird die Datei abgewiesen.

## Referenzielle Konsistenz

Die Validierung prüft unter anderem:

- Herkunftsprofile von Erlebnissen und Bewertungen existieren.
- Erlebnispositionen referenzieren ein vorhandenes Erlebnis und ein vorhandenes Produkt.
- Preisbeobachtungen referenzieren vorhandene Erlebnisposition, Erlebnis, Produkt und optional einen vorhandenen Ort; die IDs müssen zueinander passen.
- Produktbewertungen referenzieren das passende Produkt und die passende Erlebnisposition.
- Ortsbewertungen und ihre atomaren Kriterienwerte referenzieren dasselbe Erlebnis und denselben Ort.
- Kriterium-Snapshots besitzen eine interpretierbare Version und referenzieren ein im Export enthaltenes Kriterium.
- Kategorie-Eltern und Kategoriezuordnungen referenzieren vorhandene Ziele.

Verwaiste Beobachtungen werden damit abgewiesen, bevor sie eine Importvorschau oder spätere Persistenz erreichen.

## Historische Daten

Duplikaterkennung basiert in dieser Stufe ausschließlich auf stabilen IDs innerhalb derselben Sammlung. Zwei Preisbeobachtungen oder Bewertungen mit unterschiedlichen IDs bleiben eigenständige historische Datensätze, auch wenn sie dasselbe Produkt, denselben Ort oder einen ähnlichen Zeitraum betreffen. Die fachliche Konflikt- und Dublettenanalyse folgt in Story #18.

## Vorwärtskompatibilität

Zusätzliche unbekannte optionale Felder innerhalb einer unterstützten Schemaversion werden ignoriert. Bekannte Pflichtfelder, IDs, Beziehungen und Bedeutungen müssen dagegen weiterhin den Regeln der unterstützten Version entsprechen. Eine unbekannte neuere `schemaVersion` wird nie auf diese Weise toleriert.

## Test-Fixtures

Neben den Fixtures aus der Formatdefinition werden folgende Fälle automatisiert geprüft:

- `schema/fixtures/taugts-export-v0-migrierbar.json`: unterstützte Vorabversion mit Migration auf Version 1,
- `schema/fixtures/taugts-export-v1-verwaist.json`: syntaktisch korrekter Datensatz mit fehlenden Referenzzielen,
- `schema/fixtures/taugts-export-v1-fachlich-ungueltig.json`: ungültige Kombination aus Erlebnisstatus und Zeitangaben.

Die Tests prüfen außerdem beschädigtes JSON, eine zu neue Schemaversion, ungültige Preis-/Währungswerte, Kriterienversionen, Vorwärtskompatibilität unbekannter optionaler Felder sowie Größen- und Tiefengrenzen.
