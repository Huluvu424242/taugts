# Versioniertes JSON-Austauschformat

Taugt’s? verwendet für Sicherung und Datenaustausch ein eigenes, von der lokalen SQLite-Datenbank unabhängiges JSON-Format. Diese Dokumentation beschreibt die aktuelle **Schemaversion 3** auf `master`. Der vollständige Export, die sichere Importvalidierung, die Konfliktvorschau und die bestätigte atomare Importausführung sind implementiert. Die Version des Austauschformats ist unabhängig von der lokalen SQLite-Schemaversion (derzeit 4).

## Kennung und Versionierung

Jede Datei besitzt mindestens folgende Kopfdaten:

```json
{
  "format": "taugts-export",
  "schemaVersion": 3,
  "exportiertAm": "2026-09-05T18:15:00Z",
  "appVersion": "0.1.0+8"
}
```

- `format` ist dauerhaft `taugts-export` und verhindert die Verwechslung mit beliebigen JSON-Dateien.
- `schemaVersion` versioniert ausschließlich das Austauschformat. Sie ist unabhängig von der internen SQLite-Schemaversion und von der App-Version.
- `exportiertAm` ist ein UTC-Zeitstempel in ISO 8601 mit abschließendem `Z`.
- `appVersion` dokumentiert die Version der App, die die Datei erzeugt hat.
- Alle Dateien werden als UTF-8 geschrieben und gelesen.

Eine Änderung, die bestehende Felder inkompatibel umdeutet oder entfernt, benötigt eine neue `schemaVersion`. Ergänzende optionale Felder dürfen innerhalb derselben Version hinzukommen, solange vorhandene Bedeutung nicht verändert wird.

Schemaversion 2 führte die Felder `wert` und `textWert` zur getrennten Speicherung numerischer und textueller Bewertungswerte ein. **Version 3** ersetzt bei Erlebnissen die früheren Status- und Plan-/Ist-Zeitfelder durch die beiden optionalen Felder `beginn` und `ende`. Eine weitere Umstellung der Bewertungskriterien ist damit nicht verbunden.

## Formales Schema und Fixtures

Die formale JSON-Schema-Datei liegt unter:

- `schema/taugts-export.schema.json`

**Formaler Schema-Vertrag:** Seit der Korrektur in [Bug #234](https://github.com/Huluvu424242/taugts/issues/234) deklariert `schema/taugts-export.schema.json` die Austauschformatversion **3**. Die Erlebniseigenschaften `beginn` und `ende` sind darin bereits abgebildet. Weitergehende fachliche Prüfungen (beispielsweise Zeitreihenfolge und referenzielle Konsistenz) erfolgen ergänzend im `ImportValidierungsService`.

Die vorhandenen Fixtures unter `schema/fixtures/` bleiben bewusst als historische Version-0- und Version-1-Beispiele erhalten. Sie dienen vor allem dazu, die unterstützten Vorwärtsmigrationen, verwaiste Referenzen und fachlich ungültige Status-/Zeitkombinationen zu prüfen. Details stehen unter [Sichere Importvalidierung](importvalidierung.md).

Das bisherige gültige Version-1-Fixture enthält dasselbe Produkt in zwei unterschiedlichen Restaurantbesuchen mit eigenständigen Erlebnispositionen, Preisbeobachtungen und Bewertungen. Damit wird ausdrücklich gezeigt, dass spätere Beobachtungen ältere Werte nicht überschreiben. Beim Import wird es über die definierten Zwischenschritte auf die aktuelle Schemaversion 3 migriert.

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

Kategorien, Klassifikation und Kategorie-Kriteriensets sind im lokalen Fachmodell bereits umgesetzt. Das Austauschformat bildet die vorgesehenen Sammlungen und ihre Referenzen ab; ihre Versionsentwicklung bleibt unabhängig von der SQLite-Tabellenstruktur.

## IDs und Beziehungen

Fachliche Datensätze verwenden stabile UUIDs. Beziehungen werden ausschließlich über diese IDs dargestellt und nicht durch eingebettete Kopien von Stammdaten ersetzt.

Beispiele:

- ein Erlebnis verweist mit `herkunftProfilId` auf sein Profil und optional mit `ortId` auf einen Ort,
- eine Erlebnisposition verweist mit `erlebnisId` und `produktId` auf Erlebnis und Produkt,
- eine Preisbeobachtung verweist auf Erlebnis, Erlebnisposition, Produkt und optional Ort,
- eine Bewertung verweist auf Erlebnis, bewertetes Objekt, Herkunftsprofil und optional Erlebnisposition beziehungsweise Ortsbewertung,
- eine Ortsbewertung verweist auf genau das Erlebnis und den bewerteten Ort,
- Kategoriezuordnungen enthalten Kategorie- und Ziel-ID.

JSON Schema kann die Existenz einer referenzierten UUID in einer anderen Sammlung nicht vollständig ausdrücken. Deshalb prüft `ImportValidierungsService` die referenzielle Konsistenz zusätzlich und weist verwaiste oder widersprüchliche Beobachtungen ab.

## Erlebniszeitraum in Version 3

Ein Erlebnis behält seine stabile ID und seinen Typ (`restaurantbesuch` oder `einkauf`). **Ein gespeicherter Status ist in der aktuellen Version nicht mehr vorhanden.** Statt der getrennten Planungs- und Durchführungszeiten verwendet es:

- `beginn`: optionaler UTC-Zeitstempel für den vereinheitlichten Beginn,
- `ende`: optionaler UTC-Zeitstempel für das Ende.

Ein gesetztes Ende benötigt einen Beginn und darf zeitlich nicht vor diesem liegen. Ein neuer Besuch kann auch ohne Produktpositionen erfasst werden, sofern der fachliche Kontext aus Ort und Besuchsbeginn ausreichend ist.

Bei der Migration älterer JSON-Dateien **2 → 3** hat der frühere `tatsaechlicherBeginn` Vorrang. Fehlt dieser, wird aus `geplanterTag` und `geplanteMinute` (ohne Uhrzeit: 00:00 UTC) ein Beginn gebildet. Die frühere tatsächliche Endzeit wird nur übernommen, wenn ein tatsächlicher Beginn vorhanden war. Alte Felder wie `status`, `istEntwurf`, `geplanterTag`, `geplanteMinute`, `geplanteDauerMinuten`, `tatsaechlicherBeginn` und `tatsaechlichesEnde` entfallen danach aus dem normalisierten Importdokument; die Ursprungsdatei bleibt unverändert.

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

Beim Import werden nicht nur die einzelnen IDs geprüft. Erlebnisposition, Erlebnis und Produkt einer Preisbeobachtung müssen auch zueinander passen; verwaiste oder widersprüchliche Preisbeobachtungen werden abgewiesen.

## Dezimalwerte

Nicht-monetäre Dezimalwerte wie Alkoholgehalt, Koordinaten und numerische Bewertungswerte werden als kanonische Dezimalstrings gespeichert, zum Beispiel:

```json
{
  "alkoholgehalt": "4.9",
  "breitengrad": "50.8323",
  "wert": "12.5"
}
```

Verbindlich sind:

- Dezimalpunkt statt Komma,
- keine Tausendertrennzeichen,
- keine Exponentialschreibweise,
- keine lokalisierte Darstellung.

Damit ist die textuelle Zahl unabhängig von Sprache und Gleitkommaimplementierung eindeutig reproduzierbar. Die Importvalidierung lehnt abweichende Darstellungen ab.

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

### Typisierte Kriterienwerte

Schemaversion 2 bildet die sechs Eingabetypen wie folgt ab:

| Eingabetyp | Exportfeld | Inhalt |
| --- | --- | --- |
| `wertung` | `wert` | numerischer Qualitätswert 1 bis 5 |
| `intensitaet` | `wert` | numerische Intensität 1 bis 5 |
| `jaNein` | `wert` | `1` für Ja, `0` für Nein |
| `zahl` | `wert` | freie endliche Zahl |
| `auswahl` | `textWert` | genau einer der im historischen Snapshot enthaltenen `auswahlwerte` |
| `freitext` | `textWert` | frei erfasster Text mit höchstens 500 Zeichen |

`wert` und `textWert` sind im JSON beide vorhanden; **genau eines der beiden Felder ist nicht `null`**. Dadurch bleibt die Bedeutung ohne numerische Hilfscodierung von Auswahl- oder Textwerten erhalten.

Beispiel für einen Auswahlwert:

```json
{
  "wert": null,
  "textWert": "Dunkel"
}
```

Beispiel für einen Zahlenwert:

```json
{
  "wert": "12.5",
  "textWert": null
}
```

`bewertetAm` ist der fachliche Bewertungszeitpunkt. Für bestehende Produktbewertungen, bei denen die lokale Persistenz bisher keinen getrennten Bewertungszeitpunkt besitzt, entspricht er beim Export dem ursprünglichen Erstellungszeitpunkt der Bewertung. Export und Validierung behalten diese Abbildung konsistent bei.

Die Importvalidierung verlangt für jeden historischen Wert einen vollständigen Snapshot und prüft seine Kriterien-ID sowie die Versionsbeziehung. Bei Version 2 wird zusätzlich geprüft, dass numerischer oder textueller Wert zum historischen Eingabetyp passt. Dadurch bleibt jede akzeptierte historische Bewertung eindeutig interpretierbar.

## Herkunft

Profile besitzen eine stabile UUID. Erlebnisse und Bewertungen referenzieren ihre `herkunftProfilId`. Beim Datenaustausch darf diese ID nicht durch die aktuell lokale Profil-ID ersetzt werden. Dadurch bleiben eigene und importierte Daten unterscheidbar.

## Optionale und unbekannte Felder

Ein optionaler bekannter Wert darf als `null` übertragen werden, wenn das Schema dies für das konkrete Feld zulässt. Erforderliche Sammlungen werden dagegen immer als Array ausgegeben und nicht weggelassen.

JSON Schema erlaubt auch in Schemaversion 3 zusätzliche, nicht bekannte Felder. Das ist eine bewusste Vorwärtskompatibilitätsregel: Ein Leser einer unterstützten Version darf unbekannte **optionale** Felder ignorieren, muss aber zuerst Formatkennung und Schemaversion prüfen. Eine Datei mit einer unbekannten neueren `schemaVersion` darf nicht still wie eine bekannte Version behandelt werden.

`ImportValidierungsService` setzt diese Regel um: unbekannte zusätzliche Felder innerhalb einer unterstützten Version werden ignoriert; Pflichtfelder, bekannte IDs und Beziehungen werden weiterhin streng geprüft. Eine unbekannte neuere Schemaversion wird abgewiesen.

## Unterstützte Vorwärtsmigrationen

Die aktuelle Version **3** unterstützt die älteren Versionen **0, 1 und 2**:

- **0 → 1:** Die vor der ersten Austauschformatversion optional fehlenden Sammlungen `kategorien` und `kategorieZuordnungen` werden leer ergänzt.
- **1 → 2:** Historische Bewertungen erhalten zusätzlich `textWert: null`. Der bisherige numerische `wert` bleibt unverändert erhalten.
- **2 → 3:** Die bisherigen Plan-/Ist-Angaben werden wie oben beschrieben in `beginn` und `ende` überführt, der frühere Erlebnisstatus und die alten Zeitfelder entfernt.

Damit bleiben ältere Exportdateien über explizite Vorwärtsmigrationen einlesbar. Typisierte Auswahl- und Freitextwerte werden seit Schemaversion 2 unterstützt.

Migrationen laufen ausschließlich auf einer Kopie des dekodierten Dokuments im Arbeitsspeicher. Die Eingabedatei und lokale SQLite-Daten werden dabei nicht verändert. Jede künftige Versionsstufe benötigt eine eigene getestete Vorwärtsmigration.

## Korrektur und neue Historie

Die Identität eines historischen Datensatzes wird durch seine stabile ID bestimmt:

- dieselbe ID mit korrigierten Feldern bedeutet eine Korrektur desselben historischen Datensatzes,
- eine andere ID bedeutet eine eigenständige Beobachtung,
- gleiches Produkt, gleicher Ort oder gleicher Preis allein bedeutet **keine** Identität.

Dadurch können dasselbe Produkt und derselbe Ort über die Zeit beliebig viele eigenständige Preise und Bewertungen besitzen. Die Importvalidierung weist nur tatsächlich mehrfach verwendete IDs innerhalb derselben Sammlung als Duplikat ab.

## Sicherheitsgrenzen

Vor der fachlichen Analyse begrenzt die Importvalidierung die Eingabe standardmäßig auf 10 MiB, 40 Verschachtelungsebenen und 250.000 JSON-Knoten. Jede fachliche Sammlung darf höchstens 50.000 Einträge enthalten. Details und Begründung stehen unter [Sichere Importvalidierung](importvalidierung.md).

## Implementierter Importablauf

Die Oberfläche bietet drei deutlich getrennte Modi. **Ergänzen** ist der sichere Standard: neue Datensätze werden übernommen, identische Datensätze anhand ihrer stabilen ID übersprungen und bei einfachen abweichenden Versionen zunächst lokale Werte behalten. **Import bevorzugen** belegt geeignete Versionskonflikte zugunsten des Imports vor, entfernt aber keine ausschließlich lokal vorhandenen Datensätze. **Gesamten lokalen Datenbestand ersetzen** entfernt hingegen nach gesonderter Bestätigung die importierbaren lokalen Fachdaten und spielt ausschließlich den validierten Importbestand ein; sonstige App-Einstellungen und externe Dateien sind davon nicht umfasst.

Automatische Vorbelegungen sind keine unbemerkten fachlichen Zusammenführungen: Identitäts- und Referenzkonflikte sowie mögliche fachliche Dubletten bleiben bei Bedarf entscheidungspflichtig. Zulässige Einzelentscheidungen können vor der Ausführung verändert werden. Ein konfliktfreier Import benötigt dagegen keine manuellen Klicks pro Datensatz. Die Ersatzvorschau benennt den Datenverlust und bietet vor der gesonderten Bestätigung einen Sicherungsexport an; ein leerer fachlicher Importbestand ist im Ersatzmodus gesperrt. Löschung und Neuimport erfolgen innerhalb **derselben** SQLite-Transaktion; ein Fehler setzt beide Teile zurück.

Der aktuelle Export und Import umfassen zusätzlich zu den historischen Grundsammlungen auch Kategorien, Zuordnungen, Klassifikationsmerkmale, Kriterienset-Regeln und -Zuordnungen sowie den Löschstatus von Produkten und Orten. Ältere gültige Austauschdateien ohne die nachträglich ergänzten optionalen Sammlungen können weiterhin eingelesen werden; fehlende Sammlungen werden als leer behandelt. Das ist eine Erweiterung des gültigen Austauschumfangs und **keine neue JSON-Schemaversion**: Auf `master` bleibt Version **3** maßgeblich. Details zur bedienbaren Vorschau, zur Datensicherung und zu Verlustfolgen stehen in der [Benutzerdokumentation](../benutzer/datenhaltung.md#import-und-export).

Die Vorvalidierung ist schreibfrei. Danach bietet die App eine Importvorschau mit den Strategien **Bestand ersetzen**, **Import bevorzugen** und **Lokalen Bestand bevorzugen**. Identitätskonflikte und mögliche fachliche Dubletten können einzeln geprüft werden. Produkt- und Ortsdubletten können unter Beibehaltung einer kanonischen lokalen UUID und einer dauerhaften Aliasreferenz zusammengeführt werden. Erst **Import verbindlich ausführen** übernimmt den geprüften Import in einer Datenbanktransaktion; ein Fehler führt zum Rollback. Das lokale Importprotokoll hält nur Status und Zähler, keine importierten Fachinhalte.

