# Release-Checkliste 0.1.0+8

Diese Checkliste dokumentiert die Vorbereitung und die noch notwendigen Prüfungen für das Android-Release **0.1.0+8**. Die Releasevorbereitung führt den manuellen Android-Release-Workflow ausdrücklich nicht aus.

## Versions- und Dokumentationsstand

- [x] `pubspec.yaml` auf `0.1.0+8` gesetzt.
- [x] `CHANGELOG.md` enthält den datierten Abschnitt `0.1.0+8` und einen leeren Bereich `Unreleased` für folgende Änderungen.
- [x] Vergleichslinks im Changelog auf `v0.1.0+8` fortgeschrieben.
- [x] Die in der App angezeigte Änderungshistorie bleibt mit dem Changelog synchron: Die App lädt direkt das als Flutter-Asset eingebundene `CHANGELOG.md`; es existiert keine zweite manuell gepflegte Releasehistorie.
- [x] README auf Version, Funktionsumfang, APK-Dateinamen und Release-Dokumente von `0.1.0+8` aktualisiert.
- [x] Release Notes `docs/releases/0.1.0+8.md` erstellt.
- [x] Benutzerdokumentation gegen den aktuellen Stand geprüft; der Excel-Statistikexport ist unter `docs/benutzer/auswertungen.md` dokumentiert und der Speichern-Weg unter `docs/benutzer/datenhaltung.md` beschreibt weiterhin korrekt das nutzerseitige Verhalten.
- [x] Der weiterhin relevante Upgrade-Hinweis für Datenbanken aus 0.1.0+6 und davor ist in README und Release Notes sichtbar dokumentiert.
- [x] Repositoryweite Suche nach `0.1.0+7` durchgeführt; aktuelle Releaseangaben werden auf `0.1.0+8` aktualisiert, bewusst historische Angaben zu Release 0.1.0+7 bleiben erhalten.
- [x] `ATTRIBUTIONS.md` geprüft; die seit 0.1.0+7 neu ausgelieferte Abhängigkeit `excel_community` ist bereits mit Herkunft, MIT-Lizenz und Verwendung dokumentiert.

## Automatisierte Prüfungen

Nach Erstellung des Vorbereitungs-PRs müssen die gemäß den verbindlichen Agentenregeln vorgeschriebenen Prüfungen erfolgreich sein:

- [ ] `dart format --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Zugehöriger GitHub-Actions-Lauf **Flutter-Prüfungen** erfolgreich.

Der dauerhaft freigegebene Workflow `Flutter-Prüfungen` darf auf dem Arbeitsbranch und dem PR automatisch laufen. Der manuelle Workflow **Android Release APK** wird durch diese Vorbereitung nicht ausgeführt.

## Release-spezifische Konsistenzprüfungen

- [x] Versionsnummer in `pubspec.yaml`: `0.1.0+8`.
- [x] Changelog-Version und Datum: `0.1.0+8` / `2026-09-06`.
- [x] `CHANGELOG.md` ist weiterhin unter `flutter.assets` eingetragen.
- [x] Die In-App-Änderungshistorie nutzt weiterhin direkt `CHANGELOG.md` als Quelle.
- [ ] In einer gebauten Release-APK zeigt der Über-Dialog die installierte Version `0.1.0+8` einschließlich Buildnummer korrekt an.
- [ ] Die Aktion **Änderungshistorie** öffnet offline und zeigt den Abschnitt `0.1.0+8` strukturiert ohne rohe Markdown-Syntax an.
- [ ] Projektseite, Benutzerdokumentation und Hilfe lassen sich aus dem Über-Dialog wie vorgesehen öffnen.

## Release-spezifische funktionale Android-Prüfungen

Vor der öffentlichen Freigabe auf mindestens einem vorgesehenen realen Android-Gerät prüfen:

- [ ] JSON-Export über **Export speichern** erzeugen und den Android-Systemdialog erfolgreich zum Speichern verwenden.
- [ ] Abbruch des Speicherdialogs verändert keine lokalen Daten und wird nicht als technischer Fehler gemeldet.
- [ ] JSON-Export über **Export teilen** funktioniert weiterhin unverändert.
- [ ] Im Bereich **Auswertungen** über **Exportieren** eine Excel-Datei mit realistischem Datenbestand speichern.
- [ ] Tabellenblatt **Produktbewertungen** enthält je Produkt/Ort beste, schlechteste und durchschnittliche Qualitätswertung; fehlende Kombinationen bleiben leer.
- [ ] Tabellenblatt **Ortsbewertungen** enthält je Ort beste, schlechteste und durchschnittliche Qualitätswertung.
- [ ] Tabellenblatt **Ortsverlauf** enthält historische Punkte und ein Liniendiagramm mit einer Linie je Ort.
- [ ] Beste und schlechteste Werte sind neben der textlichen Spaltenbezeichnung wie vorgesehen zusätzlich grün beziehungsweise rot hervorgehoben.
- [ ] Kriterien der Typen Intensität, Ja/Nein, Zahl, Auswahl und Freitext fließen nicht in die Excel-Qualitätskennzahlen ein.
- [ ] Excel-Datei in mindestens einer realen Tabellenkalkulation öffnen und Tabellen, Zahlenformate, Formatierung sowie Diagramm visuell prüfen.
- [ ] Export bei fehlenden Qualitätswertungen und technischer Speicherstörung auf verständliche Leer-/Fehlerzustände prüfen.

## Regression der Kernfunktionen

- [ ] Produkterfassung einschließlich Pflichtfeldvalidierung und Fehlersammler.
- [ ] EAN-/Barcode-Scan direkt am EAN-Feld und über den normalen Scan-Einstieg.
- [ ] Produkt-, Gaststätten- und Geschäftsbewertungen mit den sechs Eingabetypen speichern und erneut laden.
- [ ] Restaurantbesuch und Einkauf mit Ortsbewertung speichern und erneut öffnen.
- [ ] Globale Suche und Startseiten-Kachel **Bewertungen** prüfen.
- [ ] Standortermittlung, Karte und Reverse Geocoding einschließlich Fehler-/Offlinefall.
- [ ] Importvalidierung, Vorschau, Strategien, Konfliktentscheidungen und Dubletten-Merge prüfen.

## Datenbank- und Upgrade-Prüfung

0.1.0+8 führt gegenüber 0.1.0+7 keine neue Datenbank-Baseline ein. Der mit 0.1.0+7 eingeführte Upgrade-Hinweis bleibt für ältere Vorabstände relevant:

- [ ] Update einer vorhandenen 0.1.0+7-Installation auf 0.1.0+8 mit demselben Signierschlüssel durchführen und vorhandene Daten stichprobenartig prüfen.
- [ ] Frische Installation von 0.1.0+8 erzeugt die aktuelle Datenbank fehlerfrei.
- [ ] Eine aus 0.1.0+6 oder früher stammende lokale Vorab-Datenbank wird nicht fälschlich als direkt kompatibel behandelt.
- [ ] Für Datenerhalt aus 0.1.0+6 oder früher vollständigen JSON-Export vor dem Update und geprüften Neuimport in eine frische aktuelle Datenbank verwenden.

## Dokumentationswebsite

- [ ] Navigation, Suche und zentrale Benutzerseiten der GitHub-Pages-Dokumentation funktionieren.
- [ ] Seite **Auswertungen** beschreibt den Excel-Export mit drei Tabellenblättern und Ortsverlaufsdiagramm korrekt.

Der GitHub-Pages-Workflow ist nicht als selbständig ausführbares Werkzeug freigegeben; eine notwendige Ausführung oder erneute Ausführung benötigt die dafür vorgeschriebene ausdrückliche Freigabe.

## Barrierefreiheit und Bedienung

- [ ] TalkBack für Startseite, Auswertungen, Exportaktionen, Über-Dialog und Änderungshistorie prüfen.
- [ ] Große Systemschrift beziehungsweise Textskalierung ohne abgeschnittene Pflichtinformationen oder nicht erreichbare Aktionen prüfen.
- [ ] Kleines Android-Display auf Overflows und Scrollbarkeit prüfen.
- [ ] Fokusreihenfolge und semantische Beschriftungen der Exportaktionen prüfen.
- [ ] Fehler-, Abbruch- und Statusmeldungen als verständliche Live-Regionen prüfen.

## Signierung und Release-Artefakte

Erst nach erfolgreichem Merge der Vorbereitung und gesonderter ausdrücklicher Freigabe des manuellen Release-Workflows:

- [ ] Signing-Secrets gemäß `docs/android-release.md` vorhanden und unverändert gültig.
- [ ] Manuellen Workflow **Android Release APK** für Version `0.1.0+8` starten.
- [ ] Workflow endet vollständig erfolgreich.
- [ ] GitHub Release `v0.1.0+8` wurde erzeugt.
- [ ] `taugts-0.1.0+8.apk` ist vorhanden.
- [ ] `taugts-0.1.0+8.apk.sha256` ist vorhanden.
- [ ] SHA-256-Prüfsumme lokal gegen die APK verifizieren.
- [ ] APK-Installation beziehungsweise Update mit demselben Release-Signierschlüssel prüfen.
- [ ] Release Notes auf GitHub gegen `docs/releases/0.1.0+8.md` prüfen.

## Abschluss

Das Release gilt erst als freigabefähig, wenn alle für die Veröffentlichung relevanten offenen Punkte dieser Checkliste abgeschlossen sind. Insbesondere müssen der Android-System-Speicherdialog und die erzeugte Excel-Arbeitsmappe vor der öffentlichen Freigabe auf einer realen Zielumgebung geprüft werden.
