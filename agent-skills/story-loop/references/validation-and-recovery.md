# Validierung, Fehlerbehandlung, Berechtigungen

- Ein PR ist nur **erfolgreich validiert**, wenn alle nach Harness und Branchregeln **vorgeschriebenen GitHub-Actions-Prüfungen** auf dem maßgeblichen PR-Stand erfolgreich ausgeführt wurden. Running, pending, skipped, cancelled, missing und unbekannt sind kein Erfolg.
- Unterscheide vorgeschriebene CI von optionalen Checks. Prüfe auch, ob der verwendete Workflow in der aktuell geltenden Version nach Harness tatsächlich freigegeben ist; keine unerlaubten Workflows triggern.
- Lokal ausgeführte Tests können helfen; sie ersetzen vorgeschriebene GitHub-Actions-Prüfungen nicht.
- Repair-Loop: Diagnose → minimal zulässige Korrektur → PR aktualisieren → Checks auf neuem SHA prüfen; normalerweise maximal drei Zyklen, sofern Harness keine abweichende Regel setzt.
- Vorübergehende Infrastrukturprobleme nicht als Codefehler behandeln. Ohne zulässigen Prüfnachweis verbleibt die Story als nicht validiert.
- Bei nicht behebbarer Störung: Ergebnis, Ursache, CI-Link, Head-SHA, Maßnahmen und Blockaden in PR/Issue nachvollziehbar machen, keine falsche Erfolgsmeldung, unabhängige Story aufnehmen.
- Bei fehlender Berechtigung: keine alternative Schnittstelle allein zum Umgehen der verweigerten Handlung nutzen; andere zulässige Stories bearbeiten. Fehlt grundsätzlich benötigter GitHub-Zugriff, Arbeitslauf beenden.
- Bei einem neuen Lauf GitHub-Issues, PRs, Checks, SHA und Abhängigkeiten erneut lesen. Grünen Zustand nicht aus dem vorherigen Chat übernehmen.
- Nach Plattform- oder Kontextgrenzen den zuletzt feststellbaren Zustand berichten. Ein Skill garantiert keine unbegrenzte Schleifenlaufzeit.
