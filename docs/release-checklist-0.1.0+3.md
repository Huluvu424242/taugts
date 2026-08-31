# Release-Checkliste 0.1.0+3

Stand: 31. August 2026

Diese Checkliste trennt vorbereitete Nachweise von Punkten, die erst nach Merge,
auf realen Geräten oder während der ausdrücklich freigegebenen
Release-Erstellung erledigt werden können. Ein offener Punkt darf nicht als
erledigt interpretiert werden.

## Dokumentarisch vorbereitet

- [x] Zielversion `0.1.0+3` ist in `pubspec.yaml` eingetragen.
- [x] `CHANGELOG.md` enthält den datierten Abschnitt `0.1.0+3` und einen
  neuen leeren Abschnitt `Unreleased`.
- [x] Deutschsprachige Release Notes liegen unter
  `docs/releases/0.1.0+3.md`.
- [x] README beschreibt Funktionsumfang, Installation, Datenschutz und
  Einschränkungen für `0.1.0+3`.
- [x] Barrierefreiheitsdokumentation nennt die vorbereitete Version und diese
  Checkliste.
- [x] Logo, Flutter, Dart und alle in `pubspec.yaml` aufgeführten
  Laufzeitabhängigkeiten sind in `ATTRIBUTIONS.md` dokumentiert.
- [x] Die geprüften Lizenzen der Laufzeitabhängigkeiten sind mit der
  MIT-Projektlizenz vereinbar beziehungsweise erfordern die dokumentierte
  Attribution.
- [x] Der Release-Vorbereitungs-PR ändert den Release-Workflow nicht und führt
  ihn nicht aus.
- [x] Bei der Vorbereitung wurden weder Tag noch GitHub Release, APK oder
  produktiver Release-Branch erzeugt.

## Vor Merge des Vorbereitungs-PRs

- [x] `dart format --set-exit-if-changed lib test` war für den exakten
  PR-Head erfolgreich.
- [x] `flutter analyze` war für den exakten PR-Head erfolgreich.
- [x] `flutter test` war für den exakten PR-Head erfolgreich.
- [ ] Der PR wurde menschlich geprüft.
- [ ] Offene Review-Diskussionen sind aufgelöst.
- [ ] Der PR wurde nach `master` gemergt.

## Manuelle Funktions- und Geräteprüfungen vor Veröffentlichung

- [ ] Story #30 und die darin vorgeschriebenen manuellen
  Barrierefreiheitsprüfungen sind abgeschlossen oder ihre Befunde wurden
  bearbeitet.
- [ ] Vollständigen Kernablauf mit TalkBack auf Android geprüft.
- [ ] Große Systemschrift und Display-Skalierung geprüft.
- [ ] Kleines Android-Gerät beziehungsweise kleine Bildschirmgröße geprüft.
- [ ] Gestennavigation und erreichbare untere Aktionen geprüft.
- [ ] Produkt und Ort angelegt, Erlebnis mit mehreren Positionen gespeichert,
  Produkt bewertet und Verlauf kontrolliert.
- [ ] Gaststätte im Restaurantbesuch getrennt bewertet und späteren Besuch als
  eigenen historischen Datensatz geprüft.
- [ ] Kriterien angelegt, sortiert, deaktiviert und ihre historische
  Unveränderlichkeit geprüft.
- [ ] Barcode mit gültigem Code gescannt, bestätigt und einem vorhandenen sowie
  einem neuen Produkt zugeordnet.
- [ ] Ablehnung der Kameraberechtigung und manuelle Barcode-Eingabe geprüft.
- [ ] Standort mit Genauigkeitsanzeige übernommen, korrigiert und entfernt.
- [ ] Ablehnung der Standortberechtigung sowie ausgeschaltete Standortdienste
  geprüft.
- [ ] OpenStreetMap-Karte mit vorhandener und neuer Position geprüft,
  Attribution geöffnet und manuelle Offline-Alternative kontrolliert.
- [ ] App-Neustart durchgeführt und lokale Daten anschließend geprüft.
- [ ] Bug-Meldung einschließlich GitHub-Anmeldehinweis auf einem realen Gerät
  geprüft.
- [ ] Barrierefreiheitserklärung vollständig auf einem realen Gerät gelesen und
  ihr Stand bei Bedarf aktualisiert.
- [ ] Bekannte Einschränkungen in Release Notes und Dokumentation stimmen mit
  dem tatsächlichen Stand überein.

## Signing und Workflow-Freigabe

Diese Punkte werden ausschließlich vom Projektverantwortlichen beziehungsweise
nach einer gesonderten ausdrücklichen Freigabe erledigt. Geheimwerte werden
niemals im Chat, in Issues, Pull Requests oder Logs eingetragen.

- [ ] Stabilen Release-Keystore dauerhaft und sicher gesichert.
- [ ] Repository-Secret `ANDROID_KEYSTORE_BASE64` eingerichtet.
- [ ] Repository-Secret `ANDROID_KEYSTORE_PASSWORD` eingerichtet.
- [ ] Repository-Secret `ANDROID_KEY_ALIAS` eingerichtet.
- [ ] Repository-Secret `ANDROID_KEY_PASSWORD` eingerichtet.
- [ ] Endgültigen Git-Blob-SHA von
  `.github/workflows/android-release.yml` nach Merge ermittelt.
- [ ] Ausdrückliche Ausführungsfreigabe gemäß `AGENTS.md` für genau diese
  Workflow-Version eingeholt.
- [ ] Workflow **Android Release APK** manuell mit
  `release_version=0.1.0+3` und den vorbereiteten Release Notes gestartet.

## Ergebnis des Release-Laufs prüfen

- [ ] `flutter analyze` war im Release-Lauf erfolgreich.
- [ ] `flutter test` war im Release-Lauf erfolgreich.
- [ ] Signierter Release-Build war erfolgreich.
- [ ] Tag `v0.1.0+3` wurde vom vorgesehenen Commit erzeugt.
- [ ] GitHub Release trägt den vorgesehenen Titel und die geprüften Release
  Notes.
- [ ] `taugts-0.1.0+3.apk` ist angehängt.
- [ ] `taugts-0.1.0+3.apk.sha256` ist angehängt.
- [ ] Lokale SHA-256-Prüfung der heruntergeladenen APK stimmt überein.
- [ ] APK lässt sich auf einem Android-Testgerät neu installieren.
- [ ] Aktualisierung einer vorhandenen, mit demselben Keystore signierten
  Installation funktioniert.
- [ ] Installierte App zeigt Version `0.1.0+3` im Über-Dialog.
- [ ] Kurzer Smoke-Test der Kernabläufe mit der veröffentlichten APK war
  erfolgreich.

## Nach dem Release

- [ ] Produktiven Branch `release/v0.1.0+3` exakt vom Release-Tag angelegt.
- [ ] Branch-Schutz für `release/**` greift.
- [ ] GitHub Release und Downloadlinks nochmals öffentlich geprüft.
- [ ] Story #96 durch Merge des zugehörigen PRs automatisch geschlossen.
- [ ] Offene Befunde als eigene Bug-Issues dokumentiert.
