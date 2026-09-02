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

Kann eine Datei nicht geschrieben oder geteilt werden, zeigt Taugt’s? einen verständlichen Fehler an; der lokale Datenbestand bleibt unverändert. Import und Konfliktprüfung folgen in den nächsten Stories. Bis ein späterer Import ausdrücklich bestätigt wird, werden durch den Datenaustausch keine Daten eingelesen oder überschrieben.
