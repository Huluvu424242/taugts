# Versioniertes JSON-Austauschformat

Taugt’s? verwendet für Sicherung und Datenaustausch ein eigenes, von der lokalen SQLite-Datenbank unabhängiges JSON-Format. Diese Dokumentation beschreibt **Schemaversion 1**. Die eigentliche Export- und Importfunktion wird in nachfolgenden Stories umgesetzt.

## Kennung und Versionierung

Jede Datei besitzt mindestens folgende Kopfdaten:

```json
{
  "format": "taugts-export",
  "schemaVersion": 1,
  "exportiertAm": "2026-09-02T16:15:00Z",
  "appVersion": "0.1.0+4"
}
```

- `format` ist dauerhaft `taugts-export` und verhindert die Verwechslung mit beliebigen JSON-Dateien.
- `schemaVersion` versioniert ausschließlich das Austauschformat. Sie ist unabhängig von der internen SQLite-Schemaversion und von der App-Version.
- `exportiertAm` ist ein UTC-Zeitstempel in ISO 8601 mit abschließendem `Z`.
- `appVersion` dokumentiert die Version der App, die die Datei erzeugt hat.
- Alle Dateien werden als UTF-8 geschrieben und gelesen.

Eine Änderung, die bestehende Felder inkompatibel umdeutet oder entfernt, benötigt eine neue `schemaVersion`. Ergänzende optionale Felder dürfen innerhalb derselben Version hinzukommen, solange vorhandene Bedeutung nicht verändert wird.

## Formales Schema und Fixtures

Das normative JSON Schema liegt unter:

- `schema/taugts-export.schema.json`

Beispieldaten liegen unter:

- `schema/fixtures/taugts-export-v1-gueltig.json`
- `schema/fixtures/taugts-export-v1-ungueltig.json`

Das gültige Fixture enthält dasselbe Produkt in zwei unterschiedlichen Restaurantbesuchen mit eigenständigen Erlebnispositionen, Preisbeobachtungen und Bewertungen. Damit wird ausdrücklich gezeigt, dass spätere Beobachtungen ältere Werte nicht überschreiben.

## Oberste Struktur

Alle fachlichen Sammlungen sind vorhanden, auch wenn sie leer sind:

| Feld | Inhalt |
| --- | --- |
| `profile` | lokale Herkunftsprofile |
| `objekte` | bewertbare Objekte und Produkte |
| `orte` | Gastronomie, Geschäfte, private und sonstige Orte |
| `erlebnisse` | Restaurantbesuche und Einkäufe |
| `erlebnisPositionen` | Produkte innerhalb eines konkreten Erlebnisses |
| `preisbeobachtungen` | historische Einzelpreise |
| `bewertungskriterien` | aktuell bekannte Kriterienkonfigurationen |
| `bewertungen` | historische einzelne Kriterienwerte für Produkt oder Ort |
| `ortsbewertungen` | eigenständige Ortsbewertung eines konkreten Erlebnisses einschließlich Notiz |
| `kategorien` | hierarchisch vorbereitete Kategorien |
| `kategorieZuordnungen` | Zuordnung einer Kategorie zu Objekt oder Ort |

Kategorien sind bereits im Austauschformat vorgesehen, auch wenn ihre Verwaltung erst mit der dafür vorgesehenen Fachstory vollständig in der App umgesetzt wird. Dadurch braucht das Austauschformat für die spätere Kategorisierung keinen strukturellen Bruch.

## IDs und Beziehungen

Fachliche Datensätze verwenden stabile UUIDs. Beziehungen werden ausschließlich über diese IDs dargestellt und nicht durch eingebettete Kopien von Stammdaten ersetzt.

Beispiele:

- ein Erlebnis verweist mit `herkunftProfilId` auf sein Profil und optional mit `ortId` auf einen Ort,
- eine Erlebnisposition verweist mit `erlebnisId` und `produktId` auf Erlebnis und Produkt,
- eine Preisbeobachtung verweist auf Erlebnis, Erlebnisposition, Produkt und optional Ort,
- eine Bewertung verweist auf Erlebnis, bewertetes Objekt, Herkunftsprofil und optional Erlebnisposition beziehungsweise Ortsbewertung,
- eine Ortsbewertung verweist auf genau das Erlebnis und den bewerteten Ort,
- Kategoriezuordnungen enthalten Kategorie- und Ziel-ID.

JSON Schema kann die Existenz einer referenzierten UUID in einer anderen Sammlung nicht vollständig ausdrücken. Die referenzielle Prüfung ist daher zusätzlich Aufgabe der Importvalidierung aus Story #17.

## Historische Erlebnisse

Ein Erlebnis besitzt einen stabilen `typ` und `status`:

- Typ: `restaurantbesuch` oder `einkauf`
- Status: `geplant`, `aktiv` oder `beendet`

Folgende Zeitinformationen bleiben getrennt:

- `geplanterTag`: Kalenderdatum im Format `YYYY-MM-DD`,
- `geplanteMinute`: optionale Minute des Tages von `0` bis `1439`, sodass ein Einkauf bewusst nur mit Datum geplant werden kann,
- `geplanteDauerMinuten`: optionale positive Dauer,
- `tatsaechlicherBeginn`: optionaler UTC-Zeitstempel,
- `tatsaechlichesEnde`: optionaler UTC-Zeitstempel.

Ein später bearbeitetes Erlebnis behält seine ID. Ein tatsächlich neues Erlebnis erhält eine neue ID.

## Erlebnispositionen und Preise

Eine Erlebnisposition besitzt eine eigene UUID und referenziert genau ein Produkt sowie ein Erlebnis. Die `anzahl` ist eine positive Ganzzahl und bleibt von Produktmenge oder Gebinde getrennt.

Preisbeobachtungen sind eigene historische Datensätze. Sie enthalten:

- `id`,
- `produktId`,
- `erlebnisId`,
- `erlebnisPositionId`,
- optional `ortId`,
- `beobachtetAm`,
- `betragMinor`,
- `waehrung`.

Geldwerte werden **nicht als Gleitkommazahl** exportiert. `betragMinor: 450` mit `waehrung: "EUR"` bedeutet 4,50 EUR. Dadurch entstehen keine binären Rundungsfehler.

Eine Korrektur derselben Preisbeobachtung behält deren ID. Ein Preis bei einem anderen Erlebnis oder eine fachlich neue Beobachtung erhält eine neue ID.

## Dezimalwerte

Nicht-monetäre Dezimalwerte wie Alkoholgehalt, Koordinaten und Bewertungswerte werden als kanonische Dezimalstrings gespeichert, zum Beispiel:

```json
{
  "alkoholgehalt": "4.9",
  "breitengrad": "50.8323",
  "wert": "3.5"
}
```

Verbindlich sind:

- Dezimalpunkt statt Komma,
- keine Tausendertrennzeichen,
- keine Exponentialschreibweise,
- keine lokalisierte Darstellung.

Damit ist die textuelle Zahl unabhängig von Sprache und Gleitkommaimplementierung eindeutig reproduzierbar.

## Bewertungen und Kriterienhistorie

`bewertungen` enthält atomare historische Kriterienwerte. Jeder Eintrag besitzt eine eigene stabile ID und unterscheidet mit `zielart` zwischen `produkt` und `ort`.

Für Produktbewertungen wird das Produkt über `objektId` direkt referenziert; die konkrete `erlebnisPositionId` kann den bewerteten Eintrag innerhalb des Erlebnisses zusätzlich festhalten. `ortId` hält den verfügbaren Ortskontext fest.

Ortsbewertungen besitzen zusätzlich einen Datensatz in `ortsbewertungen`. Dessen ID gruppiert die zu diesem Erlebnis gehörenden Ortswerte und bewahrt die optionale Bewertungsnotiz. Die einzelnen Kriterienwerte verweisen über `ortsbewertungId` darauf.

Jeder Bewertungswert enthält neben der Kriterien-ID einen **historischen Kriterium-Snapshot** mit mindestens:

- Name,
- Eingabetyp,
- Reihenfolge,
- Version,
- Auswahlskala beziehungsweise `auswahlwerte`,
- optional Beschreibung.

Damit bleibt eine frühere Bewertung auch dann interpretierbar, wenn das aktive Kriterium später umbenannt, umsortiert, deaktiviert oder mit einer anderen Skala versehen wird. Die Sammlung `bewertungskriterien` beschreibt zusätzlich die aktuell im Export vorhandenen Kriterienkonfigurationen.

`bewertetAm` ist der fachliche Bewertungszeitpunkt. Für bestehende Produktbewertungen, bei denen die lokale Persistenz bisher keinen getrennten Bewertungszeitpunkt besitzt, entspricht er beim Export dem ursprünglichen Erstellungszeitpunkt der Bewertung. Die spätere Import-/Exportimplementierung muss diese Abbildung konsistent beibehalten.

## Herkunft

Profile besitzen eine stabile UUID. Erlebnisse und Bewertungen referenzieren ihre `herkunftProfilId`. Beim Datenaustausch darf diese ID nicht durch die aktuell lokale Profil-ID ersetzt werden. Dadurch bleiben eigene und importierte Daten unterscheidbar.

## Optionale und unbekannte Felder

Ein optionaler bekannter Wert darf als `null` übertragen werden, wenn das Schema dies für das konkrete Feld zulässt. Erforderliche Sammlungen werden dagegen immer als Array ausgegeben und nicht weggelassen.

JSON Schema erlaubt in Schemaversion 1 zusätzliche, nicht bekannte Felder. Das ist eine bewusste Vorwärtskompatibilitätsregel: Ein Leser von Version 1 darf unbekannte **optionale** Felder ignorieren, muss aber zuerst Formatkennung und Schemaversion prüfen. Eine Datei mit einer unbekannten neueren `schemaVersion` darf nicht still wie Version 1 behandelt werden.

Unbekannte Felder dürfen niemals bekannte IDs, Beziehungen oder Bedeutungen überschreiben. Die konkrete sichere Behandlung beim Import wird in Story #17 implementiert und getestet.

## Korrektur und neue Historie

Die Identität eines historischen Datensatzes wird durch seine stabile ID bestimmt:

- dieselbe ID mit korrigierten Feldern bedeutet eine Korrektur desselben historischen Datensatzes,
- eine andere ID bedeutet eine eigenständige Beobachtung,
- gleiches Produkt, gleicher Ort oder gleicher Preis allein bedeutet **keine** Identität.

Dadurch können dasselbe Produkt und derselbe Ort über die Zeit beliebig viele eigenständige Preise und Bewertungen besitzen.

## Abgrenzung zu den Folgestories

Diese Story definiert das Austauschformat. Sie implementiert noch keinen Dateidialog und verändert noch keine lokalen Daten.

Die nachfolgenden Stories übernehmen darauf aufbauend:

- #16: Exportdatei erzeugen, speichern und teilen,
- #17: Datei, Schema, Beziehungen und Migrationen sicher validieren,
- #18 bis #22: Vorschau, Konfliktbehandlung und atomare Importausführung.
