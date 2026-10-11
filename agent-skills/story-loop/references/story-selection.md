# Story-Auswahl und Ablauf

- Im **angegebenen** Repository offene Issues mit Label `story` und ohne Label `human-only` auswählen. Keine Pull Requests als Issues behandeln.
- Die Auswahl nach **jeder Story-Iteration** frisch abrufen. Neue zulässige Stories im selben Work-Lauf berücksichtigen.
- Zur Auswahl Graph aus ausdrücklich dokumentierten und zuverlässig belegten Abhängigkeiten bilden. Unsichere Abhängigkeiten nicht erfinden.
- Bevorzugt verfügbare, unabhängige beziehungsweise nach Voraussetzungen umsetzbare Stories wählen. Mehrere Stories nicht unbemerkt im selben PR zusammenfassen.
- Vorhandener PR ist noch kein Erfolgsnachweis. Anhand Issue/PR-Verknüpfung, Branch, Status und Head-SHA entscheiden, ob eine Story fortzusetzen oder bereits technisch validiert ist.
- `human-only` bleibt auch dann gesperrt, wenn andere Stories davon abhängen. Betroffene Nachfolger zurückstellen.
- Einzelfehler oder fehlende Rechte begrenzt behandeln und pro Lauf Rückstellliste führen; diese allein ist kein separater persistenter Status. Bei Neustart Zustand frisch aus GitHub ermitteln.
- Bei keinen ausführbaren Stories mit geordnetem Bericht enden; nicht auf Merge oder zukünftige Nutzerhandlungen warten.
