# Datenschutz und Datenhaltung

Taugt’s? ist offline-first ausgelegt. Fachliche Daten werden lokal in einer SQLite-Datenbank auf dem Gerät gespeichert.

## Keine verpflichtende Cloud

Die aktuelle Version enthält keine Telemetrie, keine versteckte Synchronisation und keinen Cloud-Dienst. Für die Kernfunktionen ist kein Benutzerkonto erforderlich.

## Kamera und Standort

Kamera und Standort werden erst nach einer bewussten Nutzeraktion verwendet. Es gibt kein Hintergrund-Tracking. Die manuelle Orts- und Koordinateneingabe funktioniert ohne Netzwerkverbindung.

Für das Laden optionaler OpenStreetMap-Kartenkacheln ist eine Netzwerkverbindung erforderlich. Die lokale Erfassung bleibt davon unabhängig.

## Bug-Meldungen

Eine Bug-Meldung wird lokal vorbereitet und anschließend im Browser zur Prüfung geöffnet. Die App sendet den Bericht nicht selbständig ab und hängt keine lokalen Nutzerdaten oder Diagnoselogs automatisch an.

## Import und Export

Über **Import/Export** auf der Startseite kann der vollständige lokale Datenbestand als versionierte JSON-Datei exportiert werden. Die Datei trägt die Kennung `taugts-export`, eine unabhängige Schemaversion, Exportzeitpunkt und die tatsächlich installierte App-Version.

Mit **Export speichern** wird zunächst der Systemdialog für das Speicherziel geöffnet. Wird dieser abgebrochen, passiert nichts. Die Exportdatei wird direkt über den vom System bereitgestellten Speicherweg geschrieben; eine allgemeine Android-Dateisystemberechtigung ist dafür nicht erforderlich. Unter Android kann die erzeugte Datei außerdem mit **Export teilen** an eine installierte App übergeben werden. Das Erzeugen des Exports benötigt keinen Server und verändert die lokalen Daten nicht.

Historische Daten bleiben eigenständige Datensätze: Ein neuer Preis oder eine neue Bewertung desselben Produkts beziehungsweise Ortes überschreibt frühere Beobachtungen nicht. Geldbeträge werden ohne Gleitkomma-Rundungsfehler gespeichert.

Importdateien werden vor der Übernahme vollständig geprüft. Anschließend kann zwischen **Bestand ersetzen**, **Import bevorzugen** und **Lokalen Bestand bevorzugen** gewählt werden. Die Vorschau zeigt, wie viele Datensätze hinzugefügt, aktualisiert, behalten oder entfernt würden. Bei **Bestand ersetzen** warnt Taugt’s? ausdrücklich vor Datenverlust und bietet vorher einen Sicherungsexport an.

Erkennt Taugt’s? abweichende Versionen, widersprüchliche historische Identitäten oder mögliche fachliche Dubletten, können diese Konflikte einzeln betrachtet werden. Unterschiede zwischen lokaler und importierter Version werden gegenübergestellt. Je Konflikttyp stehen nur zulässige Entscheidungen zur Verfügung; bei einem Identitätswiderspruch wird **Beide behalten** beispielsweise nicht angeboten. Eine Entscheidung kann auf weitere Konflikte derselben Art und Datensammlung übertragen und jederzeit vor der Ausführung geändert werden.

Bei einer fachlichen Dublette von Produkten oder Orten kann **Zusammenführen** gewählt werden. Dabei bleibt die bereits lokale UUID die kanonische Identität. Für widersprüchliche Stammdaten kann pro Feld festgelegt werden, ob der lokale oder der importierte Wert verwendet werden soll. Referenzen des importierten Datensatzes werden im fertig geplanten Import auf die kanonische Identität umgeschrieben. Die frühere importierte UUID wird lokal als Alias zur kanonischen UUID gespeichert. Bei späteren Importen wird dieser Alias bereits vor der Konfliktanalyse wiedererkannt, sodass dasselbe reale Produkt oder derselbe reale Ort nicht erneut als Dublette angelegt wird.

Beim Produkt-Merge werden Erlebnispositionen, Preisbeobachtungen und Produktbewertungen auf die kanonische Produkt-ID bezogen. Beim Orts-Merge werden Erlebnisse, ortsbezogene Preise sowie Produkt- und Ortsbewertungen auf die kanonische Orts-ID bezogen. Historische IDs, Zeitpunkte, Preise, Bewertungswerte und Kriterienkontexte bleiben dabei eigenständige historische Beobachtungen.

Die Konfliktentscheidung und das Zusammenführen bleiben bis zur ausdrücklichen Importbestätigung Teil der Vorschau. Erst **Import verbindlich ausführen** schreibt die geprüften Daten. Während dieser Ausführung sind weitere Import- und Exportaktionen in der Oberfläche gesperrt. Zusätzlich verhindert der Importdienst selbst eine zweite gleichzeitige beziehungsweise reentrante Ausführung für dieselbe lokale Datenbank und gibt diese Sperre nach Erfolg oder Fehler zuverlässig wieder frei.

Die Speicherung erfolgt atomar in einer Datenbanktransaktion. Scheitert ein Datensatz oder das Speichern einer neuen Aliasreferenz, werden alle fachlichen Änderungen dieses Importversuchs einschließlich der neuen Aliaszuordnung zurückgerollt. Ein wiederholter Import derselben stabilen oder bereits als Alias bekannten IDs erzeugt keine zusätzlichen technischen Datensätze. Erlebnisse, Positionen, Preisbeobachtungen, Produktbewertungen und Ortsbewertungen werden im Importergebnis getrennt ausgewiesen. Da eine Ortsbewertung mehrere einzelne Kriterienwerte enthalten kann, erscheinen diese Werte zusätzlich als eigener Zähler und werden nicht fälschlich den Produktbewertungen zugerechnet.

Taugt’s? führt außerdem ein lokales Importprotokoll. Es enthält nur Zeitpunkt, Erfolgs- beziehungsweise Rollbackstatus, gewählte Strategie und Zähler für hinzugefügte, aktualisierte, übersprungene, zusammengeführte und fehlerhafte Datensätze. Importierte Fachinhalte wie Namen, Notizen, Preise oder Bewertungswerte werden nicht in das Protokoll kopiert.

Kann eine Datei nicht geschrieben, geteilt oder geprüft werden, zeigt Taugt’s? einen verständlichen Fehler an. Scheitert die eigentliche Importausführung, weist die App ausdrücklich auf den Rollback hin; der vorherige fachliche Datenbestand bleibt erhalten.

## Hinweis für Daten aus 0.1.0+6 und früher

Mit 0.1.0+7 wurde die während der Vorabentwicklung entstandene SQLite-Migrationshistorie auf eine neue produktive Baseline konsolidiert und anschließend für typisierte Kriterienwerte weiterentwickelt. Dieser Baseline-Stand gilt auch für 0.1.0+8. Lokale Datenbanken aus älteren Vorabständen, insbesondere aus 0.1.0+6 und davor, besitzen keinen direkten Datenbank-Upgradepfad auf den aktuellen Stand.

Wer Daten aus einer solchen älteren Vorabversion behalten möchte, sollte **vor dem Update** einen vollständigen JSON-Export erstellen und sicher aufbewahren. Die Wiederherstellung dieses Exports in einer frisch angelegten aktuellen Datenbank muss vor dem Löschen der alten App-Daten geprüft werden. Ein Update von 0.1.0+7 auf 0.1.0+8 führt keine neue Datenbank-Baseline ein.
