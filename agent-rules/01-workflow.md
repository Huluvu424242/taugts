# Workflow und Zusammenarbeit

## Kommunikation

- Die Kommunikation zwischen KI-Agenten und menschlichen Entwicklern erfolgt auf Deutsch. Technische Bezeichner, Code, Kommandos und unveränderte Fehlermeldungen dürfen englisch bleiben.
- Stories, Bugs, PR-Titel und PR-Beschreibungen werden auf Deutsch formuliert.
- Nach jeder Arbeit wird der menschliche Entwickler über Ergebnis, Prüfungen, offene Risiken und den nächsten sinnvollen Schritt informiert. Relevante GitHub-Artefakte werden direkt verlinkt.
- Technische Bezeichner folgen Dart- und Flutter-Konventionen. Englische Frameworkbegriffe und präzise deutschsprachige Fachbegriffe dürfen sinnvoll kombiniert werden; Begriffe werden nicht mechanisch übersetzt.

## Story-Workflow

Neue Funktionen und funktionale Änderungen werden grundsätzlich zuerst als Story mit dem Label `story` und prüfbaren Akzeptanzkriterien erfasst. Soll auf Wunsch ohne Story gearbeitet werden, ist vor der Implementierung wörtlich zu fragen: `Soll ich zunächst eine Story erstellen?`

Reihenfolge:

1. Bestand und fachlichen Kontext analysieren.
2. Anforderungen in eigenständig nutzbare Stories schneiden und Abhängigkeiten benennen.
3. Passende Milestones wiederverwenden oder bei erkennbarem Bedarf anlegen.
4. Ziel, Nutzen, Beschreibung, Akzeptanzkriterien, Abhängigkeiten und betroffene Bereiche dokumentieren.
5. Bei GUI-Änderungen ein einfaches Wireframe oder Mockup einschließlich wichtiger Leer-, Lade- und Fehlerzustände ergänzen.
6. Stories und empfohlene Reihenfolge verlinken.

## Fehlerbehebung

Ein gemeldeter Defekt wird nicht still repariert. Die Reihenfolge lautet:

**Analyse → Bug-Issue → eigener Branch → Implementierung → Prüfung → Pull Request → Rückmeldung**

Das Bug-Issue beschreibt Fehlerbild, Fehlermeldung, Analyse, vermutete Ursache, betroffene Komponenten und Lösungsansatz. Der PR verknüpft das Issue mit einem Closing-Keyword und nennt Ursache, Lösung, Prüfungen und Restunsicherheiten.

## Geschützte Branches

- Der Branch `master` und alle Branches mit dem Präfix `release/` werden auf GitHub stets als geschützte Branches geführt.
- Änderungen an diesen Branches erfolgen ausschließlich über Pull Requests. Direkte Änderungen, Löschungen und Force Pushes sind untersagt.
- Für die Aufnahme einer Änderung ist keine zustimmende Review verpflichtend, da das Repository als Einzelentwickler-Projekt geführt wird und GitHub die Freigabe eigener Pull Requests nicht zulässt. Offene Review-Diskussionen müssen vor dem Merge weiterhin aufgelöst sein.
- Das aktive, über die GitHub-Oberfläche importierbare Repository-Ruleset liegt unter `gh-rulesets/protected-branches.json`.
- Ändern sich die Schutzanforderungen, werden die betroffenen AGENTS-Regeln, die Ruleset-Datei und das auf GitHub aktive Ruleset gemeinsam aktualisiert.
- Neu angelegte Branches mit dem Präfix `release/` müssen ohne zusätzliche manuelle Konfiguration durch das Ruleset erfasst werden.

## Pull Requests und Branches

- `master` wird nur über Pull Requests verändert und niemals rebased oder per Force Push überschrieben.
- PRs enthalten Ziel, Änderungen, Tests, Dokumentationsstatus, Risiken und ein Closing-Keyword wie `Closes #123`.
- Arbeitsbranches dürfen auf den aktuellen `master` rebased werden. Geteilte Branches nur nach Abstimmung rebasen.
- Nach Rebase Prüfungen wiederholen. Veröffentlichte Arbeitsbranches ausschließlich mit `git push --force-with-lease` aktualisieren; `git push --force` ist verboten.
- Konflikte fachlich auflösen; bei Unsicherheit Rebase abbrechen statt Änderungen zu erraten.

## Gestapelter Merge

Der Workflow „Gestapelter Merge“ ist ein ausschließlich vom menschlichen Entwickler auslösbarer Ausnahmeprozess. Ein KI-Agent darf ihn niemals eigenmächtig beginnen, aus offenen oder vermeintlich fertigen Pull Requests ableiten, vorschlagen und zugleich ausführen oder aufgrund früherer Merge-Erlaubnisse wiederverwenden.

### Erteilung und Grenzen der Berechtigung

- Der menschliche Entwickler muss den Merge ausdrücklich beauftragen und die betroffene Menge eindeutig festlegen, beispielsweise durch konkrete PR-Nummern oder „alle offenen gestapelten PRs“.
- Erst dieser Auftrag erteilt dem KI-Agenten für genau diese Ausführung die **explizite, einmalige und temporäre Berechtigung**, die benannten gestapelten Pull Requests selbständig zu mergen. Die Berechtigung umfasst ausdrücklich auch notwendige Merges in `master`.
- Die Berechtigung gilt ausschließlich für die gezielte Durchführung des beauftragten gestapelten Merges. Sie erlaubt keine weiteren Merges, keine Änderungen außerhalb der betroffenen PR-Kette, kein Umgehen von Branchschutz, vorgeschriebenen Prüfungen oder offenen Review-Diskussionen und keine Änderungen an GitHub-Projekteinstellungen.
- Die Berechtigung endet automatisch und vollständig, sobald die Aufgabe erfolgreich abgeschlossen wurde oder aus irgendeinem Grund fehlschlägt, abgebrochen oder blockiert wird. Sie darf weder für einen Wiederholungsversuch noch für eine spätere Aufgabe als fortbestehend angenommen werden; dafür ist ein neuer ausdrücklicher menschlicher Auftrag erforderlich.

### Verbindlicher Ablauf

1. Umfang, Reihenfolge, Basen, Head-SHAs, offenen Zustand, Review-Status, Mergefähigkeit und vorgeschriebene erfolgreiche Prüfungen aller benannten PRs ermitteln.
2. Die Kette vom untersten PR zum obersten PR bearbeiten: zuerst den PR mergen, dessen Basis der geschützte Zielbranch ist.
3. Nach jedem Merge den tatsächlichen neuen Stand von `master` beziehungsweise des Zielbranches prüfen.
4. Den jeweils nächsten gestapelten PR auf den aktualisierten Zielbranch umstellen. Enthält sein Vergleich durch die frühere Stapelbasis bereits gemergte Änderungen erneut, den Arbeitsbranch konfliktfrei auf den aktuellen Zielbranch rebasen und ausschließlich mit einer abgesicherten Aktualisierung entsprechend `--force-with-lease` veröffentlichen.
5. Danach erneut prüfen, dass der PR nur seinen eigenen fachlichen Umfang enthält, konfliktfrei und mergefähig ist. Für den neuen exakten Head-SHA alle vorgeschriebenen Prüfungen erneut erfolgreich ausführen.
6. Den PR erst anschließend mit der projektüblichen Merge-Methode mergen und den Ablauf bis zum Ende der vorgegebenen Kette wiederholen.
7. Bei Konflikten, fehlgeschlagenen Prüfungen, verändertem Head-SHA, unklarem Umfang oder einer sonstigen Blockade nicht raten, keine Schutzregel umgehen und keine zusätzlichen PRs einbeziehen. Die Ausführung anhalten; damit ist die temporäre Berechtigung erloschen.

### Abschlussmeldung

Am Ende jeder Ausführung gibt der KI-Agent die übliche Zusammenfassung aus. Sie zählt mindestens die bearbeiteten PRs in ihrer tatsächlichen Reihenfolge, Retargeting- beziehungsweise Rebase-Schritte, ausgeführte Prüfungen und deren Ergebnis, jeden erfolgreichen oder fehlgeschlagenen Merge sowie den erreichten Endzustand des Zielbranches auf. Bei einer unvollständigen oder fehlerhaften Ausführung werden die Blockade und die nicht gemergten PRs eindeutig benannt. Die Meldung stellt außerdem klar, dass die einmalige temporäre Merge-Berechtigung mit Abschluss der Ausführung wieder entzogen ist.

## Abschlussdefinition

Eine Arbeit ist fertig, wenn Umfang und Akzeptanzkriterien erfüllt, relevante Tests erfolgreich, Formatierung und Analyse sauber, Dokumentation und Lizenzen geprüft sowie offene manuelle Prüfungen transparent benannt sind.

Die Abschlussmeldung unterscheidet verbindlich:

- `Implementiert, technische Prüfung ausstehend`: Mindestens eine vorgeschriebene automatisierte Prüfung konnte weder lokal noch über CI erfolgreich ausgeführt werden.
- `Geprüft und mergebereit`: Alle vorgeschriebenen automatisierten Prüfungen waren erfolgreich; noch offene manuelle Prüfungen sind transparent benannt und stehen dem Merge nach den Projektvorgaben nicht entgegen.
