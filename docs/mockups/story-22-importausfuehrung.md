# Story #22: Atomare Importausführung

Das textuelle Wireframe dokumentiert die für die Importausführung wesentlichen Zustände auf kleinen Bildschirmen. Alle Bereiche liegen in einem scrollbaren Inhalt; Statusänderungen werden als Live-Region ausgegeben.

## Bereit zur Ausführung

```text
Importvorschau
Noch nicht importiert …

[Importstrategie                 v]
[Konflikte einzeln entscheiden]
[Import verbindlich ausführen]
```

Die Ausführung ist erst verfügbar, wenn die Datei gültig ist und alle Konflikte entschieden wurden.

## Laufender Import

```text
Import wird atomar ausgeführt …
[Fortschrittsanzeige]

[Importdatei auswählen und prüfen]  deaktiviert
[Export speichern]                  deaktiviert
[Export teilen]                     deaktiviert
```

Währenddessen kann keine zweite Aktion gestartet werden.

## Erfolg

```text
Import erfolgreich abgeschlossen.

Letztes Importergebnis
Erlebnisse                    …
Positionen                    …
Preisbeobachtungen            …
Produktbewertungen            …
Ortsbewertungen               …
Bewertungswerte zu Orten      …
Gesamt                        …

Importprotokoll
Import erfolgreich · Zeitpunkt · Strategie · Zähler
```

Jede Ergebniszeile nennt hinzugefügte, aktualisierte, übersprungene, zusammengeführte und fehlerhafte Datensätze.

## Abbruch und Rollback

```text
Dateiauswahl abgebrochen.
```

Ein Abbruch der Dateiauswahl verändert keine Daten und legt keinen Ausführungsprotokolleintrag an.

```text
Import fehlgeschlagen. Alle fachlichen Änderungen wurden zurückgerollt.

Importprotokoll
Import zurückgerollt · Zeitpunkt · Strategie · Zähler
```

Nach einem Ausführungsfehler bleibt die geprüfte Vorschau für einen erneuten Versuch erhalten.
