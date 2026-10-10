# Release-Checkliste 0.1.0+9

Vorbereitung vom 10. Oktober 2026. Der Release-Workflow wird **nicht** automatisch ausgeführt.

## Vorbereitung
- [x] Version `0.1.0+9` in `pubspec.yaml` setzen.
- [x] Changelog `Unreleased` als datierten Releaseabschnitt abschließen und Vergleichslinks fortschreiben.
- [x] In-App-Änderungshistorie: `CHANGELOG.md` bleibt das eingebundene Flutter-Asset.
- [x] README, Benutzer- und Entwicklerdokumentation und Release Notes auf den vorgesehenen Release abstimmen.
- [x] Historische Release-Dokumente und historische Versionsangaben unverändert lassen.
- [ ] Alle verbleibenden aktuellen Versionshinweise repositoryweit abschließend gegenprüfen.

## Automatisierte Prüfungen (exakter PR-Head)
- [ ] `dart format --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Freigegebener Workflow **Flutter-Prüfungen** erfolgreich.

## Manuelle Regression auf Android
- [ ] Versionsanzeige **0.1.0+9** und offline Änderungshistorie prüfen.
- [ ] Produkte und Orte löschen; historische Bewertungen, Preise und Erlebnisse bleiben erhalten; Zuordnungen korrigieren.
- [ ] Bewertungsdetails und Suchtreffer zeigen Namen statt IDs.
- [ ] Produkt aus Erlebnisposition bearbeiten oder neu erfassen; Abbruch erhält vorhandene Eingaben.
- [ ] Erlebnis ohne Produkte und mit alleiniger Ortsbewertung speichern.
- [ ] Gemeinsames Speichern und Fehler-Rollback mit Produkt-, Orts- und Preisänderungen prüfen.
- [ ] Beginn und Ende von Erlebnissen anlegen, bearbeiten und wieder öffnen.
- [ ] JSON-Export und ergänzenden Import einschließlich Kategorien, gelöschter Stammdaten und Dubletten prüfen.
- [ ] Bestandsersatz nur nach Sicherungsangebot und Bestätigung prüfen; Rollback bei Fehler.
- [ ] Excel-Export, Speichern und Teilen auf echtem Android-Gerät prüfen.
- [ ] Barcode, Standort, Karte, Offlinefälle und globale Suche prüfen.
- [ ] TalkBack, große Schrift, kleine Displays, Fokus und Fehlermeldungen prüfen.

## Datenbank und Datensicherung
- [ ] Vollständiges JSON-Backup einer 0.1.0+8-Installation anlegen und prüfen.
- [ ] Update 0.1.0+8 → 0.1.0+9 mit gleichem Signierschlüssel testen.
- [ ] SQLite-Migration Schema 3 → 4 sowie Daten und Bewertungen nach dem Update prüfen.
- [ ] JSON-Format 3 und Import älterer Formate 0 bis 2 mit Testdaten prüfen.
- [ ] Frische Installation und Import in frische Datenbank prüfen.
- [ ] Für 0.1.0+6 und älter weiterhin keinen direkten SQLite-Upgradepfad behaupten.

## Dokumentation und Freigabe
- [ ] GitHub Pages, Navigation, Suche, Benutzerhilfe und Versionsangaben prüfen.
- [ ] Release Notes und Lizenzhinweise gegen tatsächlichen Releaseumfang prüfen.
- [ ] Signing-Secrets vorhanden; keine Schlüssel oder Tokens offenlegen.
- [ ] Vor Veröffentlichung gesonderte Freigabe für **Android Release APK** einholen.
- [ ] Workflow für `v0.1.0+9` erst nach Freigabe ausführen.
- [ ] APK, SHA-256-Datei, Release Notes und Installation prüfen.

**Status:** Releasevorbereitung als PR, keine APK-Veröffentlichung. Offene Prüfungen bleiben offen.
