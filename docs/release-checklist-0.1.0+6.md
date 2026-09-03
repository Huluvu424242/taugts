# Release-Checkliste 0.1.0+6

Diese Checkliste dokumentiert die Vorbereitung und die noch notwendigen Prüfungen für das Android-Release **0.1.0+6**. Die Releasevorbereitung führt den manuellen Android-Release-Workflow ausdrücklich nicht aus.

## Versions- und Dokumentationsstand

- [x] `pubspec.yaml` auf `0.1.0+6` gesetzt.
- [x] `CHANGELOG.md` enthält den datierten Abschnitt `0.1.0+6` und einen leeren Bereich `Unreleased` für folgende Änderungen.
- [x] Vergleichslinks im Changelog auf `v0.1.0+6` fortgeschrieben.
- [x] Die in der App angezeigte Änderungshistorie bleibt mit dem Changelog synchron: `AssetChangelogService` lädt direkt das als Flutter-Asset eingebundene `CHANGELOG.md`; es existiert keine zweite manuell gepflegte Releasehistorie.
- [x] README auf Version, Funktionsumfang, APK-Dateinamen und Release-Dokumente von `0.1.0+6` aktualisiert.
- [x] Release Notes `docs/releases/0.1.0+6.md` erstellt.
- [x] Bestehende Endnutzer-Dokumentation zu Suche, Auswertungen, Bedienung und Datenhaltung gegen den aktuellen Stand geprüft; die seit 0.1.0+5 hinzugekommenen Funktionsbereiche sind bereits in eigenen beziehungsweise aktualisierten Dokumentationsseiten enthalten.
- [x] `ATTRIBUTIONS.md` geprüft; für die reine Releasevorbereitung sind keine neuen Fremdkomponenten oder Lizenzangaben hinzugekommen.

## Automatisierte Prüfungen

Nach Erstellung des Vorbereitungs-PRs müssen die gemäß `AGENTS.md` vorgeschriebenen Prüfungen erfolgreich sein:

- [ ] `dart format --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Zugehöriger GitHub-Actions-Lauf **Flutter-Prüfungen** erfolgreich.

Für diese Releasevorbereitung werden keine produktiven Flutter- oder Testdateien geändert. Trotzdem gelten die vollständigen Repository-Prüfungen als Freigabekriterium.

## Release-spezifische Konsistenzprüfungen

- [x] Versionsnummer in `pubspec.yaml`: `0.1.0+6`.
- [x] Changelog-Version und Datum: `0.1.0+6` / `2026-09-03`.
- [x] `CHANGELOG.md` ist weiterhin unter `flutter.assets` eingetragen.
- [x] `AssetChangelogService` liest `CHANGELOG.md` direkt über `rootBundle.loadString('CHANGELOG.md')`.
- [ ] In einer gebauten Release-APK zeigt der Über-Dialog die installierte Version `0.1.0+6` einschließlich Buildnummer korrekt an.
- [ ] Die Aktion **Änderungshistorie** befindet sich zwischen Hilfe und Projektseite, öffnet offline und zeigt den Abschnitt `0.1.0+6` strukturiert ohne rohe Markdown-Syntax an.
- [ ] Hilfe, Änderungshistorie, Projektseite und Projektdokumentation bleiben auf einem kleinen Android-Display vollständig erreichbar und bei Bedarf scrollbar.
- [ ] Der Urheberhinweis `🄯  created by Huluvu424242` wird sichtbar und barrierefrei dargestellt.

## Funktionale manuelle Android-Prüfungen

Vor der öffentlichen Freigabe auf mindestens einem vorgesehenen realen Android-Gerät prüfen:

- [ ] Produkterfassung einschließlich Pflichtfeldvalidierung und Fehlersammler.
- [ ] EAN-/Barcode-Scan aus dem normalen Scan-Einstieg.
- [ ] EAN-/Barcode-Scan direkt am EAN-Feld der Produkterfassung; Abbruch verändert vorhandene Formulardaten nicht.
- [ ] Globale Suche über Produkte, Orte, Erlebnisse, Bewertungen und Preise; freie und strukturierte Filter kombinieren und historische Treffer öffnen.
- [ ] Auswertungen für Kriterienwerte, Preis- und Bewertungsverläufe sowie vorhandene Andrangsdaten.
- [ ] Kategorie-Kriteriensets einschließlich Vererbung und Kennzeichnung der Kriterienquelle.
- [ ] Restaurantbesuch mit Gaststättenbewertung speichern und erneut öffnen; geänderte Bewertung wird gemeinsam mit dem Erlebnis gespeichert.
- [ ] Einkauf mit Geschäftsbewertung speichern und erneut öffnen; geänderte Bewertung wird gemeinsam mit dem Erlebnis gespeichert.
- [ ] Standortermittlung nur nach Nutzeraktion und bestätigte Übernahme.
- [ ] OpenStreetMap-Karte laden, Koordinaten korrigieren und bestätigen.
- [ ] Reverse Geocoding für einen nicht privaten Ort sowie Fehler-/Offlinefall.
- [ ] Bei einem privaten Ort werden keine exakten Koordinaten an Reverse Geocoding übertragen.
- [ ] Export mit realistischem lokalen Datenbestand erstellen, speichern und teilen.
- [ ] Exportdatei wieder importieren; Validierung, Vorschau, Strategien, Konfliktentscheidungen und Dubletten-Merge prüfen.
- [ ] Importfehler beziehungsweise Abbruch hinterlassen den vorherigen Datenbestand unverändert.
- [ ] Wiederholungsimport erkennt persistente Aliasreferenzen und erzeugt keine technischen Dubletten.

## Barrierefreiheit und Bedienung

- [ ] TalkBack für Startseite, Produkterfassung, Suche, Auswertungen, Über-Dialog und Änderungshistorie prüfen.
- [ ] Große Systemschrift beziehungsweise Textskalierung ohne abgeschnittene Pflichtinformationen oder nicht erreichbare Aktionen prüfen.
- [ ] Kleines Android-Display auf Overflows und Scrollbarkeit prüfen.
- [ ] Fokusreihenfolge und semantische Beschriftungen der zentralen Aktionen prüfen.
- [ ] Fehler- und Statusmeldungen als verständliche Live-Regionen prüfen.
- [ ] Gestennavigation und Zurück-Navigation in Formularen und Dialogen prüfen.

## Signierung und Release-Artefakte

Erst nach erfolgreichem Merge der Vorbereitung und gesonderter ausdrücklicher Freigabe des manuellen Release-Workflows:

- [ ] Signing-Secrets gemäß `docs/android-release.md` vorhanden und unverändert gültig.
- [ ] Manuellen Workflow **Android Release APK** für Version `0.1.0+6` starten.
- [ ] Workflow endet vollständig erfolgreich.
- [ ] GitHub Release `v0.1.0+6` wurde erzeugt.
- [ ] `taugts-0.1.0+6.apk` ist vorhanden.
- [ ] `taugts-0.1.0+6.apk.sha256` ist vorhanden.
- [ ] SHA-256-Prüfsumme lokal gegen die APK verifizieren.
- [ ] APK als Update über eine bestehende, mit demselben Schlüssel signierte Taugt’s?-Installation testen.
- [ ] Release Notes auf GitHub gegen `docs/releases/0.1.0+6.md` prüfen.

## Abschluss

Das Release gilt erst als freigabefähig, wenn alle für die Veröffentlichung relevanten offenen Punkte dieser Checkliste abgeschlossen sind. Diese Datei dokumentiert bewusst sowohl bereits automatisierbare als auch weiterhin manuelle Prüfungen.
