# Release-Checkliste 0.1.0+1

Stand: 30. August 2026

Diese Checkliste trennt vorbereitete Nachweise von Punkten, die erst nach Merge,
auf einem realen Gerät oder während der ausdrücklich freigegebenen
Release-Erstellung erledigt werden können. Ein offener Punkt darf nicht als
erledigt interpretiert werden.

## Dokumentarisch vorbereitet

- [x] Zielversion `0.1.0+1` ist in `pubspec.yaml` eingetragen.
- [x] Android-Anzeigename ist in `AndroidManifest.xml` als **Taugt’s?**
  eingetragen.
- [x] Android-Paketkennung lautet `de.huluvu.taugts`.
- [x] Android-Launcher-Icon und hochauflösende Logoquelle sind vorhanden.
- [x] `CHANGELOG.md` enthält den datierten Abschnitt `0.1.0+1`.
- [x] Deutschsprachige Release Notes liegen unter
  `docs/releases/0.1.0+1.md`.
- [x] MIT-Projektlizenz ist in `LICENSE` enthalten.
- [x] Logo, Flutter, Dart und Laufzeitabhängigkeiten sind in
  `ATTRIBUTIONS.md` dokumentiert.
- [x] README beschreibt Funktionsumfang, Installation, Datenschutz und
  Einschränkungen.
- [x] Es existiert noch kein GitHub Release für diese Version.
- [x] Keystores, `.env`-Dateien und lokale Android-Konfiguration sind durch
  `.gitignore` geschützt.
- [x] Der Release-Vorbereitungs-PR ändert den Release-Workflow nicht und führt
  ihn nicht aus.

## Vor Merge des Vorbereitungs-PRs

- [x] Der vorhandene freigegebene Workflow **Flutter-Prüfungen** war für den
  Release-Vorbereitungs-PR erfolgreich (Lauf #22).
- [ ] Der PR wurde menschlich geprüft.
- [ ] Offene Review-Diskussionen sind aufgelöst.
- [ ] Der PR wurde nach `master` gemergt.

## Vor der öffentlichen Veröffentlichung

- [ ] Story #30 und die darin vorgeschriebenen manuellen
  Barrierefreiheitsprüfungen sind abgeschlossen oder ihre Befunde wurden
  bearbeitet.
- [ ] Vollständigen Kernablauf mit TalkBack auf Android geprüft.
- [ ] Große Systemschrift und Display-Skalierung geprüft.
- [ ] Kleines Android-Gerät beziehungsweise kleine Bildschirmgröße geprüft.
- [ ] Gestennavigation und erreichbare untere Aktionen geprüft.
- [ ] Produkt anlegen, Ort anlegen, Erlebnisentwurf speichern und
  Getränkebewertung als zusammenhängenden Ablauf manuell geprüft.
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
  `release_version=0.1.0+1` und den vorbereiteten Release Notes gestartet.

## Ergebnis des Release-Laufs prüfen

- [ ] `flutter analyze` war im Release-Lauf erfolgreich.
- [ ] `flutter test` war im Release-Lauf erfolgreich.
- [ ] Signierter Release-Build war erfolgreich.
- [ ] Tag `v0.1.0+1` wurde vom vorgesehenen Commit erzeugt.
- [ ] GitHub Release trägt den vorgesehenen Titel und die geprüften Release
  Notes.
- [ ] `taugts-0.1.0+1.apk` ist angehängt.
- [ ] `taugts-0.1.0+1.apk.sha256` ist angehängt.
- [ ] Lokale SHA-256-Prüfung der heruntergeladenen APK stimmt überein.
- [ ] APK lässt sich auf einem Android-Testgerät neu installieren.
- [ ] Aktualisierung einer vorhandenen, mit demselben Keystore signierten
  Installation funktioniert oder ist für das erste Release als nicht
  anwendbar dokumentiert.
- [ ] Installierte App zeigt Version `0.1.0+1` im Über-Dialog.
- [ ] Kurzer Smoke-Test der Kernabläufe mit der veröffentlichten APK war
  erfolgreich.

## Nach dem Release

- [ ] Produktiven Branch `release/v0.1.0+1` exakt vom Release-Tag angelegt.
- [ ] Branch-Schutz für `release/**` greift.
- [ ] GitHub Release und Downloadlinks nochmals öffentlich geprüft.
- [ ] Story #82 geschlossen beziehungsweise durch Merge des zugehörigen PRs
  automatisch geschlossen.
- [ ] Offene Befunde als eigene Bug-Issues dokumentiert.
