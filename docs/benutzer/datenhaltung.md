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

Mit **Export speichern** wird zunächst der Systemdialog für das Speicherziel geöffnet. Wird dieser abgebrochen, passiert nichts. Unter Android kann die erzeugte Datei außerdem mit **Export teilen** an eine installierte App übergeben werden. Das Erzeugen des Exports benötigt keinen Server und verändert die lokalen Daten nicht.

Historische Daten bleiben eigenständige Datensätze: Ein neuer Preis oder eine neue Bewertung desselben Produkts beziehungsweise Ortes überschreibt frühere Beobachtungen nicht. Geldbeträge werden ohne Gleitkomma-Rundungsfehler gespeichert.

Importdateien werden vor einer späteren Übernahme vollständig geprüft. Anschließend kann zwischen **Bestand ersetzen**, **Import bevorzugen** und **Lokalen Bestand bevorzugen** gewählt werden. Die Vorschau zeigt, wie viele Datensätze hinzugefügt, aktualisiert, behalten oder entfernt würden. Bei **Bestand ersetzen** warnt Taugt’s? ausdrücklich vor Datenverlust und bietet vorher einen Sicherungsexport an.

Erkennt Taugt’s? abweichende Versionen, widersprüchliche historische Identitäten oder mögliche fachliche Dubletten, können diese Konflikte einzeln betrachtet werden. Unterschiede zwischen lokaler und importierter Version werden gegenübergestellt. Je Konflikttyp stehen nur zulässige Entscheidungen zur Verfügung; bei einem Identitätswiderspruch wird **Beide behalten** beispielsweise nicht angeboten. Eine Entscheidung kann auf weitere Konflikte derselben Art und Datensammlung übertragen und jederzeit vor der späteren Ausführung geändert werden.

Die Konfliktentscheidung bleibt Teil der Vorschau. Auch ein Wechsel zurück zur Importvorschau verändert keine lokalen Daten. Das tatsächliche Zusammenführen von Dubletten und die atomare Ausführung des Imports werden in nachfolgenden Ausbaustufen ergänzt.

Kann eine Datei nicht geschrieben, geteilt oder geprüft werden, zeigt Taugt’s? einen verständlichen Fehler an; der lokale Datenbestand bleibt unverändert. Bis ein späterer Import ausdrücklich bestätigt wird, werden durch den Datenaustausch keine Daten eingelesen oder überschrieben.
