# Manuelle Dart-Formatierung auf Arbeitsbranches

## Status und Freigabe

Die GitHub Action `Dart-Formatierung Arbeitsbranch` liegt unter `.github/workflows/kiagent-dart-format-branch.yml`. **Ihre bloße Bereitstellung ist keine Ausführungsfreigabe.** Sie darf erst nach menschlicher Prüfung und Merge dieses Werkzeugketten-PRs und anschließend gesonderter ausdrücklicher Freigabe nach [AGENTS / Sicherheit](../../agent-rules/05-security-tooling.md) verwendet werden. Die bestehende freigegebene Action `Flutter-Prüfungen` bleibt unverändert.

## Bedienkonzept

Nach gesonderter Freigabe wird die Action über **Actions → Dart-Formatierung Arbeitsbranch → Run workflow** gestartet. Als **Workflow-Quellbranch** ist `master` zu wählen; das separate Pflichtfeld `branch` gibt den vorhandenen **Ziel-Arbeitsbranch** an (z. B. `bug/234-json-schema-version-3`). Optional kann der erwartete Commit-SHA als `expected_sha` angegeben werden. Ein anderer Workflow-Quellbranch oder ein unzulässiger Zielbranch wird abgewiesen.

Erlaubte Zielbranch-Präfixe sind `story/`, `bug/`, `feature/`, `fix/`, `docs/` und `chore/`. `master`, `release/*` und beliebige andere Branches werden nicht beschrieben. Der Workflow formatiert nur vorhandene Dart-Dateien in `lib/` und `test/`. Ohne Änderung entsteht kein Commit. Andernfalls entsteht genau ein Commit `style: Dart-Formatierung (automatisiert)` auf dem gewählten Branch. Danach muss weiterhin die unabhängige Action **Flutter-Prüfungen** erfolgreich durchlaufen.

## Sicherheits- und Bedrohungsanalyse

| Risiko | Maßnahme |
| --- | --- |
| Workflow-Manipulation über den gewählten Branch | Die Workflow-Definition wird ausschließlich vom `master`-Ref gestartet; `github.ref` wird zur Laufzeit auf `refs/heads/master` geprüft |
| Direkte Änderung geschützter Branches | Strikte Zielbranch-Präfixliste, Git-Ref-Validierung und Ausschluss geschützter Branches bereits vor dem Checkout |
| Injection über Branch-Eingabe | Übertragung als Umgebungsvariable, reguläre Ausdrucksprüfung und `git check-ref-format` vor Git-Befehlen; keine direkte Skriptinterpolation |
| Weitergabe von Schreibrechten an Projektinhalte | `actions/checkout` mit `persist-credentials: false`; keine Projektskripte, kein `flutter pub get`, keine Tests; das `GITHUB_TOKEN` wird erst im abschließenden Push-Schritt als Umgebungsvariable übergeben |
| Unerwünschte Dateiveränderung | Formatter auf `lib test` beschränkt, nur nachweislich geänderte versionierte `.dart`-Dateien unter diesen Verzeichnissen werden aufgenommen |
| Überschreiben fremder Änderungen | Optionaler erwarteter Ausgangs-SHA, Vergleich mit Remote direkt vor Push, normaler Fast-forward-Push ohne Force; konkurrierende Updates führen zum Abbruch |
| Wiederholungsschleife | Ausschließlich `workflow_dispatch`, kein `push`- oder `pull_request`-Trigger; bei unverändertem Arbeitsbaum kein Commit |
| Berechtigungsausweitung | Workflow-Standard `permissions: {}`, nur im Formatter-Job `contents: write`; keine eigenen Secrets oder weiteren Scopes |

**Restrisiken:** Es handelt sich bewusst um einen schreibenden Workflow. Die vom GitHub-Runner ausgeführte, versionsfixierte Flutter-Toolchain und die referenzierten externen Actions sind Supply-Chain-Abhängigkeiten. Eine Person mit Berechtigung zum manuellen Workflowstart und Branch-Schreibzugriff kann Formatierungscommits auf erlaubte Arbeitsbranches veranlassen. Fork-Branches werden nicht unterstützt. Der GitHub-Lauf benötigt weiterhin die Rechte, im Zielrepository schreiben zu dürfen. Der Nutzer prüft den Commit im PR. Bei neuen Toolchain-Versionen, veränderten Actions, Berechtigungen oder Triggern ist gemäß AGENTS eine erneute Freigabe notwendig.

## Technische Festlegungen

- **Repository:** `Huluvu424242/taugts`
- **Workflow:** `.github/workflows/kiagent-dart-format-branch.yml`, `Dart-Formatierung Arbeitsbranch`
- **Trigger:** ausschließlich manueller `workflow_dispatch` auf `master`
- **Inputs:** `branch` (Pflicht), `expected_sha` (optional)
- **Runner und Laufzeit:** `ubuntu-latest`, maximal 20 Minuten; regulär nur wenige Minuten. Nutzung des GitHub-Actions-Kontingents gemäß Tarif
- **Toolchain:** `subosito/flutter-action` v2 auf unveränderlichen Action-SHA `1a449444c387b1966244ae4d4f8c696479add0b2`, Flutter `3.47.7` (Stable); `actions/checkout` v6 auf SHA `d23441a48e516b6c34aea4fa41551a30e30af803`
- **Berechtigungen:** nur Job `contents: write`; sonst keine
- **Daten:** Repository-Quelltext und GitHub-provided `GITHUB_TOKEN` nur im Push-Schritt; keine projektspezifischen Secrets, keine fremden Netzziele als Teil der Fachlogik
- **Ausgabe:** Action-Logs, Job-Zusammenfassung, optional exakt ein Commit; keine eigenen Artefakte und keine Release-Dateien
- **Aufbewahrung:** Standardmäßige GitHub-Log-Aufbewahrung des Repositorys; keine Zusatzspeicherung
- **Audit:** Workflowversion, Ausführender, Branch-Input, verwendeter SHA, Commit und CI-Status über Actions/PR prüfbar

## Deaktivierung und Rollback

Bis zur ausdrücklich erteilten Freigabe bleibt der Workflow ungenutzt. Für eine Deaktivierung oder Anpassung der Werkzeugkette ist der reguläre Story-/PR-Weg erforderlich. Ein unerwünschter Formatierungscommit wird über einen eigenen, nachvollziehbaren Revert-Commit auf dem Arbeitsbranch rückgängig gemacht, nicht per Force-Push. Die bestehende read-only-CI wird hiervon nicht verändert.
