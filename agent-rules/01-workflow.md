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

## Autonomer Story-Schleifen-Workflow in ChatGPT Work

### Geltung, Start und Pflichtlektüre

Der im Repository versionierte [Skill `story-loop`](../agent-skills/story-loop/SKILL.md) und **alle vier** dort referenzierten Dateien sind gemäß [AGENTS.md](../AGENTS.md) vor jeder Repository-Arbeit von jedem KI-Agenten vollständig zu lesen. Dies bedeutet **nicht**, dass ein Story-Arbeitslauf automatisch gestartet werden darf. Für die Ausführung sind ein ausdrücklicher menschlicher Startauftrag, der tatsächlich installierte und freigegebene Skill in einer geeigneten ChatGPT-Work-Umgebung sowie die notwendige GitHub-Zugriffsberechtigung Voraussetzung. Die installierte Skill-Releaseversion wird vor dem Lauf geprüft und im Bericht angegeben; Repositorydateien allein belegen keine Installation oder Freigabe. Ein Skill ist kein Hintergrunddienst und garantiert keine unbegrenzte Laufzeit.

**Verbindlicher Startauftrag für Taugt's (bei ausdrücklichem Aufruf):**

> Führe mit dem bewusst installierten und freigegebenen ChatGPT-Skill **story-loop** einen vollständigen autonomen Story-Arbeitslauf aus.
>
> - **Zielrepository:** `Huluvu424242/taugts`
> - **Zielbranch:** `master`
> - **Maßgebliche Harness-Datei:** `AGENTS.md` (Repository-Stamm).
> - **Stories:** alle offenen Issues mit Label `story` ohne Label `human-only`; nach jeder Iteration frisch ermitteln.
> - **Laufende Story:** eigener Branch und PR, gegebenenfalls gestapelt; **keinen PR mergen**.
> - **Abschluss:** nur bei erfolgreich nachgewiesenen vorgeschriebenen GitHub-Actions-Prüfungen auf dem einschlägigen Commit.
> - **Fehler:** begrenzte Reparaturversuche, bei fortdauernder Blockade dokumentiert zurückstellen und unabhängige Stories weiterbearbeiten.
> - **Fortsetzung:** den tatsächlichen GitHub-Zustand einschließlich offener PRs, Abhängigkeiten und Checks rekonstruieren; erfolgreich validierte PRs unangetastet lassen.
> - **Ende:** erst wenn keine ausführbaren Stories mehr verbleiben oder die Work-Umgebung eine technische Grenze erreicht.
> - **Ergebnis:** ausführlicher Bericht mit Issue- und PR-Links, Checks, SHAs, Abhängigkeiten, Merge-Reihenfolge, Reparaturen, neuen Defect-Issues und Blockaden.
>
> Lies zunächst `AGENTS.md` und **alle darin verbindlich referenzierten Regel- und Skill-Dateien einschließlich ihrer Referenzen vollständig**. Halte die projektseitigen Berechtigungs-, Workflow- und Qualitätsregeln ein, insbesondere die ausdrücklichen Freigaben für konkrete GitHub-Action-Versionen. Bei Widersprüchen in Arbeitsregeln hat der Harness Vorrang, ohne Sicherheits- oder Berechtigungsgrenzen zu überschreiten. Stelle keine wiederholten Routine-Rückfragen; falls eine Aktion nicht autorisiert ist, stelle die betroffene Story zurück.
>
> Dieser Startauftrag erteilt **keine** Berechtigung zum Mergen, Verändern von Repository-Einstellungen oder Ausführen nicht freigegebener Werkzeugketten.

### Verbindlicher Ablauf nach dem Start

1. Den aktuellen GitHub-Zustand statt früherer Chat-Erinnerungen rekonstruieren: Zielbranch, offene Stories, Labels, Kommentare, zugehörige Branches und PRs, Head-SHAs, Abhängigkeiten, Workflow-Versionen, Berechtigungen und Checks. Vorhandene geprüfte PRs nicht unnötig verändern.
2. Ausschließlich offene **Issues** im Zielrepository mit `story` und ohne `human-only` auswählen; nach **jeder** Story-Iteration neu suchen. Abhängigkeiten belegen, zulässige unabhängige Stories bevorzugen, gesperrte Voraussetzungen respektieren. Auswahlregeln: [Story-Auswahl](../agent-skills/story-loop/references/story-selection.md).
3. Pro Story eigenen ungeschützten Arbeitsbranch und PR erstellen beziehungsweise einen bereits vorhandenen unvollständigen Story-PR fortsetzen; unabhängige PRs gegen `master`, abhängige PRs bei Bedarf gestapelt gegen den vorherigen Arbeitsbranch. PR-Zuordnung, Closing-Keyword, Risiken und Stapelbeziehung dokumentieren. [PR-Abhängigkeiten](../agent-skills/story-loop/references/dependencies-and-prs.md) beachten. **Kein Merge, kein Auto-Merge**, auch nicht bei grünen Checks. Der separat geregelte, nur ausdrücklich beauftragbare Prozess „Gestapelter Merge“ wird dadurch nicht gestartet.
4. Nur die nach [Sicherheit und Werkzeugketten](05-security-tooling.md) **für die exakte unveränderte Version und den konkreten Trigger** freigegebenen GitHub Actions verwenden oder indirekt auslösen. Vor jedem Push/PR/Kommentar mögliche Trigger prüfen. Pflichtprüfungen inklusive Formatierung, Analyse, Tests und erforderlichem `mkdocs build --strict` entsprechend [Qualität und Dokumentation](06-quality-documentation.md) sowie Branchschutz auf dem **einschlägigen aktuellen SHA** nachweisen. Pending, fehlend, übersprungen, abgebrochen oder fehlgeschlagen bedeutet **nicht validiert**; bei geänderter Basis erforderliche Nachprüfungen beachten.
5. Bei Fehlern Diagnose, minimal zulässige Reparatur, neuen SHA und Checks durchführen; höchstens **drei** Reparaturzyklen, sofern eine speziellere Harness-Regel nichts anderes vorsieht. Fehlende Rechte oder Werkzeugfreigaben nicht umgehen; blockierte Story mit Versuchen und CI-Links dokumentiert zurückstellen und unabhängige Stories fortsetzen. Eigenständige Defects nach dem Bug-Issue-Prozess behandeln, Duplikate vermeiden. [Validierung und Wiederaufnahme](../agent-skills/story-loop/references/validation-and-recovery.md).
6. Schleife fortführen, bis keine zulässig ausführbare Story mehr besteht oder eine tatsächliche technische Grenze der Work-Umgebung erreicht ist; zurückgestellte Stories im selben Lauf nicht endlos erneut versuchen. Zum Abschluss einen vollständigen [Bericht](../agent-skills/story-loop/references/reporting.md) mit Issue-/PR-Links, Branches, Basen, Head-SHAs, präzisen Check-Links und geprüften SHAs, Merge-Reihenfolge (nur als **Empfehlung**), Reparaturen, neu erfassten Defects, Blockaden, Risiken und notwendigen manuellen Schritten liefern.

Dieser Workflow ist eine **Arbeitsanweisung und kein Freigabeverzeichnis**. Bei jeder Kollision mit Sicherheits-, Berechtigungs- oder Plattformgrenzen gelten die strengeren Grenzen; nicht autorisierte Aktionen unterbleiben. Die Integration dieses Workflows in den Harness startet weder die Story-Schleife noch zusätzliche GitHub Actions.
