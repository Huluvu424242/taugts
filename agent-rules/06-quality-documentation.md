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
