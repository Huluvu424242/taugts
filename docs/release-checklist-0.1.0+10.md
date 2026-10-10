# Release-Checkliste 0.1.0+10

Vorbereitung vom 10. Oktober 2026. Keine automatische APK-Veröffentlichung.

## Vorbereitung
- [x] Version 0.1.0+10 in `pubspec.yaml`.
- [x] Changelog und Vergleichslinks fortgeschrieben.
- [x] In-App-Änderungshistorie verwendet weiterhin das eingebettete `CHANGELOG.md`.
- [x] Release Notes und aktuelle Dokumentation aktualisiert.
- [ ] Versionshinweise repositoryweit abschließend auf aktuelle und historische Bedeutung prüfen.
- [ ] Tatsächlich zuletzt veröffentlichten GitHub Release prüfen.

## Automatisierte Prüfungen
- [ ] `dart format --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Freigegebene Flutter-Prüfungen auf dem exakten PR-Head erfolgreich.

## Manuelle Prüfungen
- [ ] Versionsanzeige 0.1.0+10 und offline Änderungshistorie.
- [ ] JSON-Import: Vorschau, Ergänzen, Konflikte, Bestandsersatz, Sicherung, Rollback und Fehlermeldungen.
- [ ] Erlebnis- und Bewertungsfunktionen aus 0.1.0+9 auf realem Android-Gerät.
- [ ] JSON-Export, Excel-Export, Speichern/Teilen.
- [ ] Backup und Update mit identischem Signierschlüssel; SQLite-Schema 4 und JSON-Format 3 prüfen.
- [ ] Alte Vorabdatenbanken aus 0.1.0+6 und früher nicht als direkt upgradefähig bezeichnen.
- [ ] TalkBack, große Schrift, kleine Displays, Barcode, Standort, Karte und Offlinefälle.
- [ ] GitHub Pages, Dokumentationslinks, Lizenzhinweise.
- [ ] Signing-Secrets, APK, SHA-256 und Release Notes prüfen.
- [ ] Gesonderte Freigabe vor Start des offiziellen Android-Release-Workflows.

**Status:** Vorbereitung als PR; technische und manuelle Prüfungen stehen aus.
