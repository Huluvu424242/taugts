# Release-Checkliste 0.1.0+4

Stand: 1. September 2026

Diese Checkliste trennt vorbereitete Nachweise von Punkten, die erst nach Merge, auf realen Geräten oder während der ausdrücklich freigegebenen Release-Erstellung erledigt werden können. Ein offener Punkt darf nicht als erledigt interpretiert werden.

## Dokumentarisch vorbereitet

- [x] Zielversion `0.1.0+4` ist in `pubspec.yaml` eingetragen.
- [x] `CHANGELOG.md` enthält den datierten Abschnitt `0.1.0+4` und einen neuen leeren Abschnitt `Unreleased`.
- [x] Deutschsprachige Release Notes liegen unter `docs/releases/0.1.0+4.md`.
- [x] README beschreibt Funktionsumfang, Installation, Datenschutz und Einschränkungen für `0.1.0+4`.
- [x] Benutzerdokumentation beschreibt die seit 0.1.0+3 hinzugekommenen sichtbaren Erlebnis-, Bewertungs- und Supportabläufe.
- [x] Barrierefreiheitsdokumentation wurde für den aktuellen Funktionsumfang geprüft und auf die vorbereitete Version sowie diese Checkliste aktualisiert.
- [x] `ATTRIBUTIONS.md` wurde gegen die seit 0.1.0+3 hinzugekommenen Release-Inhalte geprüft; für die reine Release-Vorbereitung ist keine zusätzliche Laufzeitabhängigkeit oder Attribution erforderlich.
- [x] Der Release-Vorbereitungs-PR ändert den Release-Workflow nicht und führt ihn nicht aus.
- [x] Bei der Vorbereitung wurden weder Tag noch GitHub Release, APK oder produktiver Release-Branch erzeugt.

## Vor Merge des Vorbereitungs-PRs

- [ ] `dart format --set-exit-if-changed lib test` ist für den exakten PR-Head erfolgreich.
- [ ] `flutter analyze` ist für den exakten PR-Head erfolgreich.
- [ ] `flutter test` ist für den exakten PR-Head erfolgreich.
- [ ] Der PR wurde menschlich geprüft.
- [ ] Offene Review-Diskussionen sind aufgelöst.
- [ ] Der PR wurde nach `master` gemergt.

## Manuelle Funktions- und Geräteprüfungen vor Veröffentlichung

- [ ] Story #30 und die darin vorgeschriebenen manuellen Barrierefreiheitsprüfungen sind abgeschlossen oder ihre Befunde wurden bearbeitet.
- [ ] Vollständigen Kernablauf mit TalkBack auf Android geprüft.
- [ ] Große Systemschrift und Display-Skalierung geprüft.
- [ ] Kleines Android-Gerät beziehungsweise kleine Bildschirmgröße einschließlich App Bar geprüft.
- [ ] Gestennavigation und erreichbare untere Aktionen geprüft.
- [ ] Startseite und Navigation mit allen zentralen Aktionen geprüft; genau ein aktives Erlebnis direkt fortgesetzt und mehrere aktive Erlebnisse ohne automatische Vorauswahl geprüft.
- [ ] Erlebnisübersicht mit laufenden, geplanten und vergangenen Restaurantbesuchen und Einkäufen geprüft.
- [ ] Restaurantbestellung mit mehreren Positionen, Mengenänderung, Einzelpreisen und Produktbewertung geprüft.
- [ ] Einkauf ohne Termin geplant, gestartet und beendet; Einkaufssumme mit vorhandenen und fehlenden Preisen geprüft.
- [ ] Bekannte Produkte aus Liste, Details und Verlauf erneut bewertet und Wiederverwendung des Stammdatensatzes kontrolliert.
- [ ] Gaststätte und Geschäft innerhalb ihrer jeweiligen Erlebnisse getrennt bewertet und spätere historische Einträge geprüft.
- [ ] Produkt- und Ortsverlauf auf Erlebniszusammenhang, Bewertungs-/Preiszeitpunkte, damalige Anzahl und damaligen Preis geprüft.
- [ ] Kriterien angelegt, sortiert, deaktiviert und ihre historische Unveränderlichkeit geprüft.
- [ ] Barcode mit gültigem Code gescannt, bestätigt und einem vorhandenen sowie einem neuen Produkt zugeordnet.
- [ ] Ablehnung der Kameraberechtigung und manuelle Barcode-Eingabe geprüft.
- [ ] Standort mit Genauigkeitsanzeige übernommen, korrigiert und entfernt.
- [ ] Ablehnung der Standortberechtigung sowie ausgeschaltete Standortdienste geprüft.
- [ ] OpenStreetMap-Karte mit vorhandener und neuer Position geprüft, Attribution geöffnet und manuelle Offline-Alternative kontrolliert.
- [ ] Projektseite und Benutzerdokumentation aus dem Über-Dialog geöffnet sowie verständlichen Öffnungsfehler geprüft.
- [ ] App-Neustart durchgeführt und lokale Daten anschließend geprüft.
- [ ] Bug-Meldung einschließlich GitHub-Anmeldehinweis auf einem realen Gerät geprüft.
- [ ] Barrierefreiheitserklärung vollständig auf einem realen Gerät gelesen und ihr Stand bei Bedarf aktualisiert.
- [ ] Bekannte Einschränkungen in Release Notes und Dokumentation stimmen mit dem tatsächlichen Stand überein.

## Signing und Workflow-Freigabe

Diese Punkte werden ausschließlich vom Projektverantwortlichen beziehungsweise nach einer gesonderten ausdrücklichen Freigabe erledigt. Geheimwerte werden niemals im Chat, in Issues, Pull Requests oder Logs eingetragen.

- [ ] Stabilen Release-Keystore dauerhaft und sicher gesichert.
- [ ] Repository-Secret `ANDROID_KEYSTORE_BASE64` eingerichtet.
- [ ] Repository-Secret `ANDROID_KEYSTORE_PASSWORD` eingerichtet.
- [ ] Repository-Secret `ANDROID_KEY_ALIAS` eingerichtet.
- [ ] Repository-Secret `ANDROID_KEY_PASSWORD` eingerichtet.
- [ ] Endgültigen Git-Blob-SHA von `.github/workflows/android-release.yml` nach Merge ermittelt.
- [ ] Ausdrückliche Ausführungsfreigabe gemäß `AGENTS.md` für genau diese Workflow-Version eingeholt.
- [ ] Workflow **Android Release APK** manuell mit `release_version=0.1.0+4` und den vorbereiteten Release Notes gestartet.

## Ergebnis des Release-Laufs prüfen

- [ ] `flutter analyze` war im Release-Lauf erfolgreich.
- [ ] `flutter test` war im Release-Lauf erfolgreich.
- [ ] Signierter Release-Build war erfolgreich.
- [ ] Tag `v0.1.0+4` wurde vom vorgesehenen Commit erzeugt.
- [ ] GitHub Release trägt den vorgesehenen Titel und die geprüften Release Notes.
- [ ] `taugts-0.1.0+4.apk` ist angehängt.
- [ ] `taugts-0.1.0+4.apk.sha256` ist angehängt.
- [ ] Lokale SHA-256-Prüfung der heruntergeladenen APK stimmt überein.
- [ ] APK lässt sich auf einem Android-Testgerät neu installieren.
- [ ] Aktualisierung einer vorhandenen, mit demselben Keystore signierten Installation funktioniert.
- [ ] Installierte App zeigt Version `0.1.0+4` im Über-Dialog.
- [ ] Kurzer Smoke-Test der Kernabläufe mit der veröffentlichten APK war erfolgreich.

## Nach dem Release

- [ ] Produktiven Branch `release/v0.1.0+4` exakt vom Release-Tag angelegt.
- [ ] Branch-Schutz für `release/**` greift.
- [ ] GitHub Release und Downloadlinks nochmals öffentlich geprüft.
- [ ] Story #140 durch Merge des zugehörigen PRs automatisch geschlossen.
- [ ] Offene Befunde als eigene Bug-Issues dokumentiert.
