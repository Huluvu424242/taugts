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

Import und Export sind in Version 0.1.0+3 noch nicht enthalten. Deshalb sollte eine Deinstallation derzeit nur erfolgen, wenn ein möglicher Verlust der lokal gespeicherten Fachdaten akzeptiert wird.
