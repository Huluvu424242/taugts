# Release-Checkliste 0.1.0+7

Diese Checkliste dokumentiert die Vorbereitung und die noch notwendigen Prüfungen für das Android-Release **0.1.0+7**. Die Releasevorbereitung führt den manuellen Android-Release-Workflow ausdrücklich nicht aus.

## Versions- und Dokumentationsstand

- [x] `pubspec.yaml` auf `0.1.0+7` gesetzt.
- [x] `CHANGELOG.md` enthält den datierten Abschnitt `0.1.0+7` und einen leeren Bereich `Unreleased` für folgende Änderungen.
- [x] Vergleichslinks im Changelog auf `v0.1.0+7` fortgeschrieben.
- [x] Die in der App angezeigte Änderungshistorie bleibt mit dem Changelog synchron: Die App lädt direkt das als Flutter-Asset eingebundene `CHANGELOG.md`; es existiert keine zweite manuell gepflegte Releasehistorie.
- [x] README auf Version, Funktionsumfang, APK-Dateinamen und Release-Dokumente von `0.1.0+7` aktualisiert.
- [x] Release Notes `docs/releases/0.1.0+7.md` erstellt.
- [x] Benutzerdokumentation gegen den aktuellen Stand geprüft; die ausdrücklich aktuelle Versionsangabe steht auf `0.1.0+7`, die sechs Kriterien-Eingabetypen sind dokumentiert und der Bewertungen-Einstieg entspricht dem tatsächlichen Verhalten.
- [x] Der fehlende direkte Datenbank-Upgradepfad aus älteren Vorabständen ist in README, Benutzerdokumentation und Release Notes sichtbar dokumentiert.
- [x] Repositoryweite Suche nach `0.1.0+6` durchgeführt; verbleibende Fundstellen wurden als historische Releaseangaben beziehungsweise alte Release-Dokumente bewertet oder auf `0.1.0+7` aktualisiert.
- [x] `ATTRIBUTIONS.md` geprüft; seit 0.1.0+6 wurden für diesen Releaseumfang keine neuen ausgelieferten Laufzeitabhängigkeiten, Logos, Schriften oder Assets eingeführt.

## Automatisierte Prüfungen

Nach Erstellung des Vorbereitungs-PRs müssen die gemäß den verbindlichen Agentenregeln vorgeschriebenen Prüfungen erfolgreich sein:

- [ ] `dart format --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Zugehöriger GitHub-Actions-Lauf **Flutter-Prüfungen** erfolgreich.

Der dauerhaft freigegebene Workflow `Flutter-Prüfungen` darf auf dem Arbeitsbranch und dem PR automatisch laufen. Der manuelle Workflow **Android Release APK** wird durch diese Vorbereitung nicht ausgeführt.

## Release-spezifische Konsistenzprüfungen

- [x] Versionsnummer in `pubspec.yaml`: `0.1.0+7`.
- [x] Changelog-Version und Datum: `0.1.0+7` / `2026-09-05`.
- [x] `CHANGELOG.md` ist weiterhin unter `flutter.assets` eingetragen.
- [x] Die In-App-Änderungshistorie nutzt weiterhin direkt `CHANGELOG.md` als Quelle.
- [ ] In einer gebauten Release-APK zeigt der Über-Dialog die installierte Version `0.1.0+7` einschließlich Buildnummer korrekt an.
- [ ] Die Aktion **Änderungshistorie** öffnet offline und zeigt den Abschnitt `0.1.0+7` strukturiert ohne rohe Markdown-Syntax an.
- [ ] Projektseite, Benutzerdokumentation und Hilfe lassen sich aus dem Über-Dialog wie vorgesehen öffnen.

## Funktionale manuelle Android-Prüfungen

Vor der öffentlichen Freigabe auf mindestens einem vorgesehenen realen Android-Gerät prüfen:

- [ ] Produktbewertung: `Wertung` mit 1–5-Qualitätswertung erfassen, speichern und erneut laden.
- [ ] Produktbewertung: `Intensität` mit 1–5-Intensität erfassen, speichern und erneut laden.
- [ ] Produktbewertung: `Ja/Nein` erfassen, speichern und erneut laden.
- [ ] Produktbewertung: `Zahl` mit einem gültigen Wert außerhalb 1–5 erfassen; ungültigen Text zurückweisen lassen.
- [ ] Produktbewertung: `Auswahl` verwendet ausschließlich die am Kriterium hinterlegten Auswahlwerte.
- [ ] Produktbewertung: `Freitext` erfassen, Maximallänge und Validierung prüfen, speichern und erneut laden.
- [ ] Dieselben sechs Eingabetypen in Gaststätten- beziehungsweise Geschäftsbewertungen prüfen.
- [ ] Startseiten-Kachel **Bewertungen** öffnet die globale Suche mit **Bewertungen und Preise** als initialem Suchbereich.
- [ ] Normale Kachel **Suche** öffnet weiterhin die allgemeine Suche über alle Bereiche.
- [ ] Produkterfassung einschließlich Pflichtfeldvalidierung und Fehlersammler.
- [ ] EAN-/Barcode-Scan direkt am EAN-Feld und über den normalen Scan-Einstieg.
- [ ] Restaurantbesuch und Einkauf mit Ortsbewertung speichern und erneut öffnen.
- [ ] Standortermittlung, Karte und Reverse Geocoding einschließlich Fehler-/Offlinefall.
- [ ] Export mit realistischem lokalen Datenbestand erstellen, speichern und teilen.
- [ ] Importvalidierung, Vorschau, Strategien, Konfliktentscheidungen und Dubletten-Merge prüfen.

## Datenbank- und Upgrade-Prüfung

Die Konsolidierung der Entwicklungs-Migrationen ist für diesen Release besonders kritisch:

- [ ] Frische Installation von 0.1.0+7 erzeugt die aktuelle Datenbank fehlerfrei.
- [ ] Reguläre Vorwärtsmigration innerhalb des neuen Baseline-Modells auf die aktuelle Schemaversion läuft erfolgreich.
- [ ] Eine aus 0.1.0+6 stammende lokale Vorab-Datenbank wird nicht fälschlich als kompatibel behandelt.
- [ ] Vor dem Update aus 0.1.0+6 einen vollständigen JSON-Export mit realistischem Datenbestand erzeugen.
- [ ] 0.1.0+7 mit frischer lokaler Datenbank starten und den zuvor erzeugten Export erfolgreich importieren.
- [ ] Nach dem Neuimport Produkte, Orte, Erlebnisse, Preise, Produktbewertungen, Ortsbewertungen und Kriterienwerte stichprobenartig gegen den Ausgangsbestand vergleichen.
- [ ] Alte App-Daten erst nach erfolgreich geprüftem Export/Neuimport verwerfen.

## Dokumentationswebsite

- [ ] Veröffentlichtes ER-Diagramm wird als Mermaid-Diagramm und nicht als roher Codeblock dargestellt.
- [ ] Weitere Mermaid-Flowcharts werden korrekt gerendert.
- [ ] Navigation, Suche und zentrale Benutzerseiten der GitHub-Pages-Dokumentation funktionieren.

Der GitHub-Pages-Workflow ist nicht als selbständig ausführbares Werkzeug freigegeben; eine notwendige Ausführung oder erneute Ausführung benötigt die dafür vorgeschriebene ausdrückliche Freigabe.

## Barrierefreiheit und Bedienung

- [ ] TalkBack für Startseite, Bewertungen-Einstieg, Bewertungsformulare, Über-Dialog und Änderungshistorie prüfen.
- [ ] Große Systemschrift beziehungsweise Textskalierung ohne abgeschnittene Pflichtinformationen oder nicht erreichbare Aktionen prüfen.
- [ ] Kleines Android-Display auf Overflows und Scrollbarkeit prüfen.
- [ ] Fokusreihenfolge, Fehlersammler und semantische Beschriftungen der sechs Kriterien-Eingabetypen prüfen.
- [ ] Fehler- und Statusmeldungen als verständliche Live-Regionen prüfen.
- [ ] Gestennavigation und Zurück-Navigation in Formularen und Dialogen prüfen.

## Signierung und Release-Artefakte

Erst nach erfolgreichem Merge der Vorbereitung und gesonderter ausdrücklicher Freigabe des manuellen Release-Workflows:

- [ ] Signing-Secrets gemäß `docs/android-release.md` vorhanden und unverändert gültig.
- [ ] Manuellen Workflow **Android Release APK** für Version `0.1.0+7` starten.
- [ ] Workflow endet vollständig erfolgreich.
- [ ] GitHub Release `v0.1.0+7` wurde erzeugt.
- [ ] `taugts-0.1.0+7.apk` ist vorhanden.
- [ ] `taugts-0.1.0+7.apk.sha256` ist vorhanden.
- [ ] SHA-256-Prüfsumme lokal gegen die APK verifizieren.
- [ ] APK-Installation beziehungsweise Update mit demselben Release-Signierschlüssel prüfen; den separaten Datenbank-Upgrade-Hinweis beachten.
- [ ] Release Notes auf GitHub gegen `docs/releases/0.1.0+7.md` prüfen.

## Abschluss

Das Release gilt erst als freigabefähig, wenn alle für die Veröffentlichung relevanten offenen Punkte dieser Checkliste abgeschlossen sind. Insbesondere darf der dokumentierte Datenerhalt aus 0.1.0+6 nicht als geprüft gelten, bevor Export und Neuimport auf einem realen beziehungsweise repräsentativen Datenbestand erfolgreich nachvollzogen wurden.
