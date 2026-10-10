# Qualität und Dokumentation

## Codestyle und Prüfungen

- Dart-/Flutter-Konventionen und `analysis_options.yaml` einhalten: Klassen `UpperCamelCase`, Variablen und Funktionen `lowerCamelCase`, Dateien `snake_case.dart`.
- Vor Abschluss mindestens ausführen, soweit das Flutter-SDK verfügbar ist:

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

- Plattform- oder UI-Änderungen zusätzlich auf der betroffenen Zielplattform manuell prüfen. Für Android vor dem Merge nach Möglichkeit `flutter clean`, `flutter analyze`, `flutter test` und `flutter run` ausführen.
- Ein Pull Request mit geändertem Dart- oder Flutter-Code darf nur dann als technisch geprüft und mergebereit gemeldet werden, wenn `dart format`, `flutter analyze` und `flutter test` erfolgreich ausgeführt wurden.
- Fehlt das Flutter-SDK in der Arbeitsumgebung, darf vor dem Abschluss ausschließlich eine nach [Sicherheit und Werkzeugketten](05-security-tooling.md#strikter-erlaubnisvorbehalt-für-github-actions-und-externe-werkzeugketten) freigegebene CI-Prüfung verwendet werden. Ist keine entsprechend freigegebene Prüfung verfügbar, wird der PR ausdrücklich als `Implementiert, technische Prüfung ausstehend` und nicht als mergebereit gemeldet.
- Nicht ausgeführte Prüfungen und der Grund dafür werden ausdrücklich genannt.

## KI-Agenten: Formatierung auf Arbeitsbranches

Bei Änderungen an Dart-Code unter `lib/` oder `test/` ist **vor der abschließenden technischen Prüfung** die Dart-Formatierung auf dem tatsächlichen Arbeitsbranch sicherzustellen. Ein KI-Agent formatiert vorrangig lokal mit dem zum Projekt passenden Dart-SDK und kontrolliert den unveränderten Arbeitsbaum nach `dart format`.

Steht dafür kein geeignetes lokales Flutter-/Dart-SDK zur Verfügung, ist die GitHub Action [`Dart-Formatierung Arbeitsbranch`](../docs/entwicklung/branch-formatierung.md) (`.github/workflows/kiagent-dart-format-branch.yml`) der vorgesehene Weg – **aber ausschließlich, wenn genau diese Workflow-Version für die beabsichtigte Ausführung nach [Sicherheit und Werkzeugketten](05-security-tooling.md) zuvor ausdrücklich freigegeben und im Freigabeverzeichnis eingetragen wurde**. Die Aufnahme dieser Regel ist **keine Freigabe**; ohne gültige Freigabe darf die Action weder direkt noch indirekt gestartet werden. Stattdessen sind die ausstehenden Prüfungen transparent zu melden.

Bei gültiger Freigabe ist der Ablauf verbindlich:

1. Bestehenden ungeschützten Arbeitsbranch und dessen tatsächlichen Head-SHA feststellen; ausschließlich einen nach der Workflow-Definition zulässigen Branch verwenden. Der Workflow wird von `master` aus manuell mit dem Eingabefeld `branch` und dem ermittelten `expected_sha` gestartet, wenn die konkrete Ausführung von der Freigabe gedeckt ist.
2. Den Lauf und seine tatsächlichen Ausgaben prüfen. Bei unverändertem Code darf kein Commit entstehen; bei Formatierungsbedarf darf nur der vorgesehene einzelne Formatierungscommit auf dem Arbeitsbranch entstehen. Änderungen an anderen Dateien, ein zwischenzeitlich veränderter Branch oder ein gescheiterter Lauf sind als Blockade zu behandeln, nicht durch Force-Push oder unautorisierte Ersatz-Actions zu umgehen.
3. Nach einem Formatierungscommit den **neuen Head-SHA** des Arbeitsbranches ermitteln. Auf diesem exakten Stand müssen die bereits freigegebenen `Flutter-Prüfungen` einschließlich Formatierungs-Diff, statischer Analyse und Tests erfolgreich abgeschlossen sein. Ein vorheriger grüner Lauf auf einem anderen SHA reicht nicht aus.
4. Erst danach den PR als `Geprüft und mergebereit` melden, sofern auch alle anderen Anforderungen erfüllt sind. Bis dahin `Implementiert, technische Prüfung ausstehend` verwenden.

Der Formatter ersetzt weder die Codeprüfung noch den Pull-Request-Prozess und darf nur im dokumentierten Berechtigungsrahmen verwendet werden. Details zu Ein- und Ausgaben sowie Sicherheitsprüfungen stehen in der [Entwicklerdokumentation](../docs/entwicklung/branch-formatierung.md).

## Dokumentation und Lizenzen

- `README.md` enthält Zweck, Voraussetzungen, Setup, Start und Tests.
- Unter `docs/` werden Architektur-, Entwickler- und Benutzerdokumentation als klar getrennte, gepflegte Dokumentationsbereiche geführt.
- Die Dokumentation unter `docs/` bleibt Markdown als einzige fachlich gepflegte Quelle. MkDocs erzeugt daraus die statische HTML-Dokumentationswebsite; generiertes HTML wird nicht eingecheckt oder separat gepflegt.
- Die MkDocs-Konfiguration und ihre Build-Abhängigkeiten werden reproduzierbar im Repository versioniert. Die veröffentlichte Website bietet nachvollziehbare Einstiege in Benutzer-, Entwickler- und Architekturdokumentation.
- Für die GitHub-Pages-Erzeugung und -Veröffentlichung wird verbindlich `.github/workflows/ghpage-generator.yml` verwendet. Der Workflow unterliegt den [Sicherheits- und Freigaberegeln für Werkzeugketten](05-security-tooling.md).
- Architekturentscheidungen mit aktuellem Nutzen werden unter `docs/` als Markdown dokumentiert; Diagramme bevorzugt als Mermaid und Architekturübersichten nach C4.
- Die Benutzerdokumentation ist für Endnutzer verständlich formuliert, bildet die tatsächlich ausgelieferte Bedienung ab und ist über die projektspezifische GitHub-Pages-URL öffentlich zugänglich.
- Änderungen an Architektur, Persistenz, Import/Export oder Plattformintegration aktualisieren die technische Dokumentation im selben PR; Änderungen am Nutzerverhalten oder an sichtbaren Funktionen aktualisieren die Benutzerdokumentation im selben PR.
- Lizenzrelevante ausgelieferte Frameworks, Laufzeitabhängigkeiten, Logos, Bilder, Schriften und Assets werden mit Herkunft, Rechteinhaber, Lizenz und Verwendung in `ATTRIBUTIONS.md` dokumentiert, sobald sie hinzukommen.
- `CHANGELOG.md` wird nach Keep a Changelog gepflegt.
- **Jeder Pull Request mit Änderungen unter `docs/`, in `mkdocs.yml` oder in den Dokumentationsabhängigkeiten benötigt vor dem Merge einen erfolgreichen `mkdocs build --strict` auf genau dem zu mergenden Commit.** Die Prüfung muss vor dem Merge erfolgen; ein erst auf `master` ausgelöster GitHub-Pages-Build genügt nicht als Vorabprüfung. Ist sie nicht möglich, ist die technische Prüfung ausdrücklich ausstehend und der PR nicht als geprüft und mergebereit zu kennzeichnen.
- Relative Markdown-Links innerhalb der MkDocs-Dokumentation müssen sich auf Dateien unter `docs/` beziehen. Dateien außerhalb des MkDocs-`docs_dir` (z. B. das Repository-`CHANGELOG.md`) werden über kanonische HTTPS-Repositorylinks referenziert; Traversal mit `../` über `docs/` hinaus ist unzulässig. Interne Anker müssen auf tatsächlich vorhandene Überschriften zeigen.
- Die Prüfung wird durch einen lokalen strikten Build oder ausschließlich eine gesondert freigegebene, lesende CI durchgeführt; eine neue oder veränderte GitHub Action darf hierfür nicht ohne die Freigabe nach `05-security-tooling.md` benutzt werden.
