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

Das zukünftige Datenaustauschformat ist bereits als versioniertes, menschenlesbares JSON-Format definiert. Es trägt die Kennung `taugts-export`, eine unabhängige Schemaversion, Exportzeitpunkt und App-Version und bewahrt die Beziehungen zwischen Profilen, Produkten, Orten, Erlebnissen, Preisen und Bewertungen.

Historische Daten bleiben dabei eigenständige Datensätze: Ein neuer Preis oder eine neue Bewertung desselben Produkts beziehungsweise Ortes überschreibt frühere Beobachtungen nicht. Geldbeträge werden ohne Gleitkomma-Rundungsfehler gespeichert.

Die eigentliche Funktion zum Erzeugen, Speichern und Einlesen solcher Dateien ist in Version 0.1.0+4 noch nicht enthalten und wird in nachfolgenden Stories umgesetzt. Deshalb sollte eine Deinstallation derzeit nur erfolgen, wenn ein möglicher Verlust der lokal gespeicherten Fachdaten akzeptiert wird.
