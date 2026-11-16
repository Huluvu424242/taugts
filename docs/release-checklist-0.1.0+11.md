# Release-Checkliste 0.1.0+11

Vorbereitung am 16. November 2026, Story [#304](https://github.com/Huluvu424242/taugts/issues/304). Keine automatische APK-Veröffentlichung.

## Vorbereitung

- [x] Letzten offiziellen Release `v0.1.0+10` vom 10. Oktober 2026 auf GitHub überprüft.
- [x] Änderungen auf `master` seit `v0.1.0+10` über Git-Vergleich und zugehörige Stories abgeglichen.
- [x] Version `0.1.0+11` in `pubspec.yaml` vorbereitet.
- [x] `CHANGELOG.md` für 0.1.0+11 ergänzt; die App liest unverändert dieses eingebettete Asset als Offline-Änderungshistorie.
- [x] README, Benutzer-, Entwickler-, Datenbank- und Release-Dokumentation auf Zielversion und Änderungen geprüft.
- [x] SQLite-Schema **5** und 4→5-Migration dokumentiert; JSON-Austauschformat bleibt **3**.
- [x] Neue Release Notes und diese Checkliste angelegt.

## Automatisierte Prüfungen (erst nach nachweislichem Erfolg abhaken)

- [ ] `dart format --set-exit-if-changed lib test` für den maßgeblichen Stand bestätigt.
- [ ] `flutter analyze` für den maßgeblichen Stand bestätigt.
- [ ] `flutter test` für den maßgeblichen Stand bestätigt.
- [ ] Freigegebene **Flutter-Prüfungen** auf dem exakten PR-Head erfolgreich.
- [ ] Freigegebene **MkDocs-PR-Prüfung** mit `mkdocs build --strict` auf dem exakten PR-Prüfstand erfolgreich.
- [ ] PR ist konfliktfrei und nach allen verpflichtenden Prüfungen mergebereit.

## Manuelle Prüfungen vor Veröffentlichung

- [ ] Versionsanzeige `0.1.0+11` und im Paket eingebettete Offline-Änderungshistorie.
- [ ] Bestandsupgrade mit realem Android-Gerät von `0.1.0+10` (SQLite 4) auf `0.1.0+11` (SQLite 5) ohne Datenverlust.
- [ ] Neue Bezugsmenge/-einheit, historische Preise ohne Snapshot, Mehrfachmengen, Stück/Gramm/Milliliter und vergleichbare Preisranglisten.
- [ ] Auswertungen inklusive Filter/Diagramme/Tabellen/Preismatrix, Produktpreis- und Produktwertungs-Ranglisten mit realistischen Daten.
- [ ] Excel-Export inklusive gefilterter Zeitreihe und Diagrammen in einer realen Tabellenkalkulation.
- [ ] Erlebnisbearbeitung: Weiterbearbeiten, bewusstes Verwerfen, Zurück-Navigation und separater Stammdaten-Speicherweg.
- [ ] JSON-Export/Import inklusive historischem Mengen-Snapshot, Konfliktvorschau, Bestandserhalt, Fehler- und Rollbackfällen.
- [ ] TalkBack, große Systemschrift, kleines Android-Gerät, Barcode, Standort, Karte und Offlinefälle.
- [ ] Release-Signierschlüssel, APK-Updatefähigkeit, SHA-256 und GitHub-Pages-Dokumentationslinks.
- [ ] Explizite gesonderte Freigabe für den offiziellen Android-Release-Workflow einholen.

**Status:** Releasevorbereitung auf Arbeitsbranch; Merge, APK-Build und Veröffentlichung noch nicht erfolgt.
