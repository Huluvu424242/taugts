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
7. Fachliche Regeln für Erlebnisstatus, Zeitkombinationen, Anzahl, Preise, Währung, Kriterienversionen und typisierte Kriterienwerte prüfen.
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

Die aktuelle Austauschformatversion ist `2`. Dateien mit einer höheren Version werden abgewiesen, statt still wie eine unterstützte ältere Version interpretiert zu werden.

Es bestehen zwei explizite Vorwärtsmigrationen:

- **0 → 1:** Die Vorabversion 0 kann die damals noch nicht vorbereiteten Sammlungen `kategorien` und `kategorieZuordnungen` weglassen. Die Migration ergänzt beide als leere Arrays und setzt `schemaVersion` auf `1`.
- **1 → 2:** Historische Bewertungen erhalten das neue Feld `textWert` mit `null`. Der vorhandene numerische `wert` bleibt unverändert erhalten. Dadurch werden alte Bewertungen nicht umgedeutet oder verworfen.

Die Migrationen finden ausschließlich im Arbeitsspeicher statt und verändern weder die Eingabedatei noch lokale Daten.

Jede künftige Schemaversion benötigt eine explizite, getestete Migration von der jeweils unterstützten Vorgängerversion. Fehlt eine notwendige Migrationsstufe, wird die Datei abgewiesen.

## Typisierte Bewertungswerte

Ab Austauschformat 2 wird zusätzlich zum historischen Kriterium-Snapshot geprüft, ob der gespeicherte Wert zum Eingabetyp passt:

- `wertung` und `intensitaet` verwenden das numerische Feld `wert` im vorgesehenen Bereich von 1 bis 5,
- `jaNein` verwendet `wert` mit `1` für Ja oder `0` für Nein,
- `zahl` verwendet eine endliche kanonische Dezimalzahl,
- `auswahl` verwendet `textWert`, der in den historischen `auswahlwerte`n enthalten sein muss,
- `freitext` verwendet einen nicht leeren `textWert` mit höchstens 500 Zeichen.

Eine Bewertung darf nicht gleichzeitig einen numerischen und einen textuellen Wert besitzen. Ebenso ist eine Bewertung ohne einen der beiden Werte ungültig. Historische Version-1-Dokumente behalten bei der Migration ihre bisherigen numerischen Werte unverändert.

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

Die vorhandenen historischen Fixtures bleiben erhalten und werden über die Vorwärtsmigration auf Format 2 geprüft:

- `schema/fixtures/taugts-export-v0-migrierbar.json`: unterstützte Vorabversion mit Migration über Version 1 auf Version 2,
- `schema/fixtures/taugts-export-v1-gueltig.json`: gültiges Version-1-Dokument, das auf Version 2 migriert wird,
- `schema/fixtures/taugts-export-v1-verwaist.json`: syntaktisch korrekter Datensatz mit fehlenden Referenzzielen,
- `schema/fixtures/taugts-export-v1-fachlich-ungueltig.json`: ungültige Kombination aus Erlebnisstatus und Zeitangaben.

Die Tests prüfen außerdem beschädigtes JSON, eine zu neue Schemaversion, ungültige Preis-/Währungswerte, Kriterienversionen, typisierte textuelle Auswahlwerte, Vorwärtskompatibilität unbekannter optionaler Felder sowie Größen- und Tiefengrenzen.
