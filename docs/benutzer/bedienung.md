# Bedienung und Funktionen

Taugt’s? dient dazu, Produkte, Orte und Erlebnisse lokal zu erfassen und zu bewerten.

**Versionshinweis:** Diese Seite erläutert den aktuellen Entwicklungsstand auf `master`. Die zusätzlichen Änderungen seit dem offiziellen Release 0.1.0+8 sind unter [`[Unreleased]`](https://github.com/Huluvu424242/taugts/blob/master/CHANGELOG.md) dokumentiert und stehen nicht automatisch in der veröffentlichten APK zur Verfügung.

## Startseite

Die mobile Startseite bietet die zentralen Aktionen **Jetzt bewerten**, **Erlebnis registrieren** und **Alle Erlebnisse**. Zusätzlich führt die Navigation zu Produkte, Orte, Bewertungen, Suche, Import/Export und Einstellungen. Noch nicht umgesetzte Bereiche zeigen eine verständliche Informationsseite statt einer funktionslosen Aktion.

Erlebnisse können in der Übersicht geöffnet und nachträglich bearbeitet werden. Der aktuelle Entwicklungsstand verwendet statt getrennten Planungs- und Durchführungsstatus einen gemeinsamen, bei Bedarf korrigierbaren Zeitraum.

Die Kachel **Suche** öffnet denselben globalen Suchbereich wie der Eintrag **Suche** in der unteren Navigation. Die Kachel **Bewertungen** öffnet ebenfalls diesen Suchbereich, setzt ihn aber direkt auf **Bewertungen und Preise**, sodass historische Produkt-, Gaststätten- und Geschäftsbewertungen sowie Preisbeobachtungen unmittelbar durchsucht und weiter nach Historienart gefiltert werden können.

## Produkte

Produkte wie Getränke, Speisen und andere Dinge können lokal angelegt, gesucht und bearbeitet werden. Produkte lassen sich anhand typabhängiger, lokal konfigurierbarer Kriterien bewerten. Bereits bekannte Produkte können aus Produktliste, Produktdetails und Bewertungsverlauf erneut bewertet werden, ohne ihre Stammdaten neu anzulegen.

EAN-, GTIN- und UPC-Barcodes können nach einer bewussten Nutzeraktion mit der Kamera gescannt, bestätigt und einem vorhandenen oder neuen Produkt zugeordnet werden. Beim Anlegen und Bearbeiten eines Produkts steht dafür direkt am Feld **EAN / Barcode** ein Scan-Symbol zur Verfügung. Ein bestätigter Scan übernimmt den Code in das Feld, ohne andere bereits eingegebene Produktdaten zu verändern; bei einem Abbruch bleibt auch der bisherige EAN-/Barcode-Wert unverändert. Die manuelle Eingabe bleibt jederzeit möglich.

## Bewertungskriterien und Eingabetypen

Bewertungskriterien legen fest, welche Eigenschaften eines Produkts oder Ortes bei einer Bewertung erfasst werden. Beim Anlegen eines eigenen Kriteriums bestimmt der **Eingabetyp**, welche Art von Antwort erfasst wird. Die Typen unterscheiden bewusst zwischen subjektiven Qualitätsurteilen, der Stärke einer Eigenschaft und beschreibenden oder objektiven Angaben.

| Eingabetyp | Bedeutung | Beispiele |
| --- | --- | --- |
| **Wertung** | Ein subjektives Qualitätsurteil: Wie gut oder schlecht ist etwas aus deiner Sicht? | **Geschmack** oder **Preis-Leistung**. Eine hohe Wertung bedeutet eine hohe wahrgenommene Qualität. |
| **Intensität** | Die Stärke oder Ausprägung einer Eigenschaft, ohne sie als gut oder schlecht zu beurteilen. Die Skala reicht von **1 – sehr gering** über **3 – mittel** bis **5 – sehr stark**. | **Bitterkeit** eines Bieres. Ein sehr bitteres Bier kann trotzdem sehr gut schmecken und daher gleichzeitig eine hohe Geschmackswertung erhalten. |
| **Ja/Nein** | Eine Eigenschaft, die entweder zutrifft oder nicht. | **Alkoholfrei?** oder **Außenbereich vorhanden?** |
| **Zahl** | Ein numerischer Mess-, Mengen- oder anderer Zahlenwert ohne Qualitätswertung. | **Wartezeit** in Minuten oder ein anderer fachlich sinnvoller Messwert. |
| **Auswahl** | Genau einer der beim Kriterium vorher festgelegten Auswahlwerte wird gewählt. | **Farbe:** hell, bernstein, dunkel oder **Andrang:** leer, normal, voll. |
| **Freitext** | Eine frei formulierte Beschreibung für Angaben, die sich nicht sinnvoll auf eine feste Skala oder Auswahl begrenzen lassen. | **Besonderheiten:** „Röstmalzig, etwas rauchig, langer Abgang.“ |

### So erscheinen die Typen im Bewertungsformular

Die gewählte Kriterienart bestimmt unmittelbar das Eingabefeld in Produkt-, Gaststätten- und Geschäftsbewertungen:

- **Wertung** wird als Auswahl von **1 – taugt gar nicht** bis **5 – taugt sehr** angeboten.
- **Intensität** wird als Auswahl von **1 – sehr gering** bis **5 – sehr stark** angeboten.
- **Ja/Nein** bietet **Ja**, **Nein** oder **Nicht bewertet** an.
- **Zahl** ist ein freies Zahlenfeld. Dezimalzahlen können mit Komma oder Punkt eingegeben werden und sind nicht auf den Bereich 1 bis 5 begrenzt.
- **Auswahl** bietet ausschließlich die Werte an, die beim Kriterium hinterlegt wurden. Sind keine Auswahlwerte hinterlegt, kann dieses Kriterium nicht bewertet werden, bis seine Definition ergänzt wurde.
- **Freitext** ist ein freies Textfeld mit maximal 500 Zeichen.

Alle Kriterien bleiben optional. Eine Bewertung kann gespeichert werden, sobald mindestens ein Kriterium oder die Bewertungsnotiz ausgefüllt ist. Ungültige Zahleneingaben werden am Feld und zusätzlich im Fehlersammler angezeigt.

### Wertung oder Intensität?

Diese beiden Typen sehen ähnlich aus, beantworten aber unterschiedliche Fragen:

- **Wertung:** „Wie gut finde ich diese Eigenschaft?“
- **Intensität:** „Wie stark ist diese Eigenschaft ausgeprägt?“

Beispielsweise beschreibt **Bitterkeit = 5 – sehr stark** zunächst nur, dass ein Bier sehr bitter ist. Ob dir diese Bitterkeit gefällt, sagt der Intensitätswert nicht aus. **Geschmack = hohe Wertung** kann deshalb gleichzeitig zutreffen.

Diese Unterscheidung ist auch für Auswertungen wichtig: Qualitätsdurchschnitte werden ausschließlich aus Kriterien vom Typ **Wertung** derselben Kriterien-ID und Kriterienversion gebildet. Intensität, Ja/Nein, Zahl, Auswahl und Freitext werden nicht in einen gemeinsamen Qualitätswert eingerechnet. Weitere Einzelheiten stehen unter [Auswertungen](auswertungen.md).

## Orte

Orte können mit Typ, optionaler Adresse, Koordinaten, OpenStreetMap-Referenz und Notiz gespeichert werden. Der aktuelle Standort kann ausschließlich nach Nutzeraktion ermittelt und vor der Übernahme geprüft werden.

Koordinaten lassen sich optional auf einer OpenStreetMap-Karte kontrollieren und korrigieren. Die manuelle Orts- und Koordinateneingabe bleibt auch ohne Netzwerkverbindung verfügbar.

Für nicht private Orte kann über **Adresse aus Koordinaten vorschlagen** ausdrücklich eine Online-Anreicherung gestartet werden. Erst dann werden die aktuell eingegebenen Koordinaten an OpenStreetMap/Nominatim übertragen. Name und Adresse erscheinen nur als Vorschlag und werden erst nach Bestätigung in das Formular übernommen; beide Angaben können anschließend korrigiert werden. Für Orte vom Typ **Privater Ort** überträgt Taugt’s? keine exakten Koordinaten an den Adressdienst. Fehlendes Netz, kein Treffer oder ein Fehler des Dienstes verhindern das manuelle Speichern des Ortes nicht.

## Suche

Die globale Suche arbeitet vollständig auf dem lokalen Datenbestand. Sie kann gemeinsam oder gezielt Produkte, Orte, Erlebnisse sowie historische Bewertungen und Preisbeobachtungen durchsuchen. Je nach Suchbereich stehen zusätzliche Filter wie Erlebnistyp oder Historienart zur Verfügung. Historische Treffer führen ihren gespeicherten Erlebnis-, Produkt- oder Ortskontext mit.

## Erlebnisse und Bewertungen

Restaurantbesuche und Einkäufe können im Voraus erfasst oder nachgetragen, in der Erlebnisübersicht wiedergefunden und jederzeit bearbeitet werden. Für jedes Erlebnis gibt es nur **einen** gemeinsamen Zeitraum mit optionalem Beginn und Ende. Beide Angaben sind jederzeit veränderbar – ohne Trennung zwischen Planung und tatsächlichem Besuch. Die Übersicht zeigt alle Erlebnisse zusammen mit Zeitkontext, Ort und Positionsanzahl.

Ein Restaurantbesuch führt seine Produkte als Bestellung. Mengen, Einzelpreise und Bewertungsstatus sind direkt sichtbar und bearbeitbar. Ein Einkauf verwendet denselben Erlebnisweg als Einkaufsliste, kann auch ohne Termin geplant werden und zeigt eine Summe ausschließlich aus Positionen mit erfasstem Preis; fehlende Preise werden ausdrücklich ausgewiesen.\n\nBeim Hinzufügen oder Bearbeiten einer Erlebnisposition kann ein vorhandenes Produkt ausgewählt, direkt über **Produkt bearbeiten** in der zentralen Produktpflege ergänzt oder korrigiert und über **Neues Produkt** neu angelegt werden. Nach erfolgreichem Speichern kehrt Taugt’s? zur Erlebnisposition zurück und behält das bearbeitete beziehungsweise neue Produkt ausgewählt. Wird die Produktbearbeitung abgebrochen, bleiben die bisherige Produktauswahl sowie bereits eingegebene Anzahl und Preisangaben unverändert.

Bei einem Restaurantbesuch können die Produkte und die Gaststätte im selben Vorgang, aber als getrennte Bewertungen erfasst werden. Bei einem Einkauf kann entsprechend das Geschäft getrennt von Einkaufsliste und Produktbewertungen bewertet werden. Eine ausgefüllte Gaststätten- oder Geschäftsbewertung wird beim allgemeinen **Speichern** des Erlebnisses automatisch mitgespeichert, wenn sie seit dem letzten Speichern geändert wurde. Innerhalb des Erlebnisses gibt es für die Ortsbewertung keinen zweiten Speichern-Button: Der allgemeine Button **Speichern** übernimmt die geänderte Ortsbewertung. In der eigenständigen Bewertungsansicht kann weiterhin separat gespeichert werden. Frühere Bewertungen werden dadurch nicht überschrieben.

**Gaststätten und Geschäfte können auch ohne ein einziges Produkt bewertet werden.** Wähle im Erlebnis zuerst den Ort, klappe **Gaststätte bewerten** beziehungsweise **Geschäft bewerten** auf und erfasse mindestens einen Kriterienwert oder eine Bewertungsnotiz. Anschließend genügt der allgemeine Button **Speichern**. Die Bewertung wird dem Erlebnis und dem Ort zugeordnet und ist beim erneuten Öffnen wieder vorhanden. Produkte lassen sich unabhängig davon später ergänzen.

**Auch ohne Kauf, Bestellung oder Bewertung lässt sich ein tatsächlicher Besuch dokumentieren.** Wähle im Erlebnis zuerst die Gaststätte beziehungsweise das Geschäft und anschließend **Spontanen Besuch jetzt erfassen** im Abschnitt *Zeitraum*. Taugt’s? setzt dadurch den Besuchsbeginn auf den aktuellen Zeitpunkt. Du kannst den Zeitpunkt bei Bedarf über **Beginn** korrigieren und das Erlebnis mit **Speichern** sichern. Ein geplanter Termin ist dafür nicht notwendig. Später lässt sich dieselbe Gaststätte oder dasselbe Geschäft im Erlebnis bewerten, ohne dass Produkte erfasst werden müssen.\n\nVöllig kontextlose neue Erlebnisse werden nicht gespeichert. Ein tatsächlicher Besuch mit gewähltem Ort und Besuchszeit, eine Ortsbewertung, eine Produktposition, eine Notiz oder eine bewusst angelegte Planung sind hingegen jeweils fachlich verwertbar. Ein ausgewählter Ort ohne Besuchszeit oder weiteren Inhalt allein dokumentiert noch keinen stattgefundenen Besuch.

## Historien

Produkt- und Ortsverläufe zeigen historische Bewertungen mit Einzelwerten sowie – soweit vorhanden – Preisen, Mengen, Orten und Erlebniszeiten. Der konkrete Erlebniszusammenhang sowie Bewertungs- und Preisbeobachtungszeitpunkte, damalige Anzahl und damaliger Preis bleiben nachvollziehbar. Dadurch werden mehrere Bewertungen desselben Produkts oder Ortes zu unterschiedlichen Zeitpunkten nicht mit aktuellen Stammdaten vermischt.

## Support und Dokumentation

Über das Support-Menü stehen **Bug melden** und **Über** zur Verfügung. Der Über-Dialog zeigt die installierte Releaseversion und verlinkt die Projektseite, die veröffentlichte Benutzerdokumentation und die offline enthaltene Barrierefreiheitserklärung. Fehler beim Öffnen externer Ziele werden in der App verständlich angezeigt.

Der Bugreport wird im Browser zur Prüfung geöffnet und nicht von der App selbständig abgesendet.


## Produkte und Orte löschen

Produkte und Orte können in ihren Übersichten über die Aktion **Löschen** aus dem aktiven Bestand entfernt werden. Vorher erklärt ein Bestätigungsdialog die Folgen; mit **Abbrechen** bleibt der Datenbestand unverändert.

Das Löschen entfernt **keine historischen Erlebnisse, Bewertungen, Preise oder Mengen**. Historische Einträge bleiben erhalten. Ist ihr früheres Produkt oder ihr früherer Ort gelöscht, zeigt Taugt’s? die Zuordnung als **Nicht zugeordnet** statt einer internen ID an.

Eine fehlende Zuordnung kann später korrigiert werden: Öffne das betroffene Erlebnis beziehungsweise die Erlebnisposition und wähle über **Produkt auswählen** oder **Ort auswählen** einen vorhandenen Stammdatensatz. Über dieselbe Auswahl kann bei Bedarf zuerst ein neues Produkt oder ein neuer Ort angelegt werden. Beim Speichern wird nur die Zuordnung geändert; Zeitpunkt, Bewertung, Preis, Menge und die übrigen historischen Angaben bleiben erhalten.


### Gemeinsames Speichern von Erlebnissen

Beim Erfassen oder Bearbeiten eines Restaurantbesuchs oder Einkaufs können zunächst Produkte, Mengen, Preise und Produktbewertungen ergänzt werden. Diese Änderungen sind **bis zum allgemeinen Button „Speichern“ nur ein Entwurf**. Die Aktionen in den Unterformularen übernehmen Eingaben in den Entwurf und speichern den Erlebnis-Gesamtstand nicht selbst. Der gemeinsame Speichervorgang umfasst Basisdaten, Produktpositionen, Preise sowie vorhandene Orts- und Produktbewertungen atomar: Entweder werden alle Änderungen übernommen oder bei einem Fehler keine davon. In diesem Fall bleibt der Entwurf auf dem Bildschirm erhalten und kann korrigiert und erneut gespeichert werden.

Ein spontaner Besuch mit Ort und Besuchszeit lässt sich auch ohne Produkte oder Bewertungen speichern. Eine gültige Planung ist ebenfalls ohne Produkte möglich. Beginn und Ende sind jederzeit direkt bearbeitbar; erst der gemeinsame Button **Speichern** übernimmt den aktuellen Zeitraum dauerhaft. Beim Verlassen ohne diese Aktion werden Änderungen nicht übernommen. **Produkt anlegen/bearbeiten** pflegt dagegen eigenständige Stammdaten mit einem separaten Speicherweg; die übrigen ungespeicherten Erlebnisangaben bleiben erhalten.
