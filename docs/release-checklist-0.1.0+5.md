# Release-Checkliste 0.1.0+5

Stand: 2. September 2026

Diese Checkliste trennt vorbereitete Nachweise von Punkten, die erst nach Merge, auf realen Geräten oder während der ausdrücklich freigegebenen Release-Erstellung erledigt werden können. Ein offener Punkt darf nicht als erledigt interpretiert werden.

## Dokumentarisch vorbereitet

- [x] Zielversion `0.1.0+5` ist in `pubspec.yaml` eingetragen.
- [x] `CHANGELOG.md` enthält den datierten Abschnitt `0.1.0+5` und einen neuen leeren Abschnitt `Unreleased`.
- [x] Deutschsprachige Release Notes liegen unter `docs/releases/0.1.0+5.md`.
- [x] README beschreibt Funktionsumfang, Installation, Datenschutz und Einschränkungen für `0.1.0+5`.
- [x] Benutzerdokumentation beschreibt den seit 0.1.0+4 hinzugekommenen Import-/Export-Weg sowie das ausdrücklich ausgelöste Reverse Geocoding.
- [x] `ATTRIBUTIONS.md` wurde gegen die seit 0.1.0+4 hinzugekommenen Release-Inhalte geprüft; für die reine Release-Vorbereitung ist keine zusätzliche Attribution erforderlich.
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
- [ ] Startseite und Navigation mit allen zentralen Aktionen geprüft.
- [ ] Restaurantbesuch mit mehreren Positionen, Mengenänderung, Einzelpreisen, Produkt- und Gaststättenbewertung geprüft.
- [ ] Einkauf geplant, gestartet und beendet; Einkaufssumme, Produkt- und Geschäftsbewertung geprüft.
- [ ] Produkt- und Ortsverläufe mit mehreren historischen Preisen und Bewertungen geprüft.
- [ ] Barcode mit gültigem Code gescannt, bestätigt und einem vorhandenen sowie einem neuen Produkt zugeordnet.
- [ ] Ablehnung der Kameraberechtigung und manuelle Barcode-Eingabe geprüft.
- [ ] Standort mit Genauigkeitsanzeige übernommen, korrigiert und entfernt.
- [ ] Ablehnung der Standortberechtigung sowie ausgeschaltete Standortdienste geprüft.
- [ ] OpenStreetMap-Karte mit vorhandener und neuer Position geprüft, Attribution geöffnet und manuelle Offline-Alternative kontrolliert.
- [ ] Reverse Geocoding für einen nicht privaten Ort ausdrücklich ausgelöst, Vorschlag geprüft, korrigiert und gespeichert.
- [ ] Reverse Geocoding bei fehlendem Netz beziehungsweise Providerfehler geprüft; manuelles Speichern bleibt möglich.
- [ ] Bei `Privater Ort` geprüft, dass keine exakten Koordinaten an den Geocoding-Dienst übertragen werden.
- [ ] Vollständigen Datenbestand exportiert und die erzeugte JSON-Datei gespeichert.
- [ ] Android-Teilen-Dialog für einen Export geöffnet und einen Abbruch ohne Datenänderung geprüft.
- [ ] Gültigen Export erneut importiert und Vorschau sowie Ergebniszahlen geprüft.
- [ ] Ungültige, beschädigte, verwaiste und nicht unterstützte Importdateien ohne lokale Datenänderung abgewiesen.
- [ ] Import einer unterstützten Schemaversion 0 mit Vorwärtsmigration geprüft.
- [ ] Die Strategien `Bestand ersetzen`, `Import bevorzugen` und `Lokalen Bestand bevorzugen` mit realistischem Bestand geprüft.
- [ ] Vor `Bestand ersetzen` Datenverlustwarnung und Sicherungsexport geprüft.
- [ ] Importkonflikte einzeln entschieden und eine Entscheidung auf weitere Konflikte gleicher Art angewendet.
- [ ] Produkt- und Ortsdubletten zusammengeführt und historische Beziehungen anschließend geprüft.
- [ ] Nach App-Neustart einen späteren Import mit bekannter Alias-ID ausgeführt und Wiedererkennung ohne neue Dublette geprüft.
- [ ] Import bewusst ausgelöst und während der Ausführung eine zweite Import-/Exportaktion auf UI-Ebene verhindert.
- [ ] Gleichzeitige beziehungsweise reentrante zweite Importausführung desselben Datenbestands technisch verhindert.
- [ ] Einen Importfehler provoziert und vollständigen Rollback des fachlichen Bestands einschließlich neuer Aliasreferenzen geprüft.
- [ ] Wiederholungsimport derselben stabilen IDs ohne zusätzliche technische Datensätze geprüft.
- [ ] Lokales Importprotokoll auf Status, Strategie und Zähler sowie auf das Fehlen kopierter Fachinhalte geprüft.
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
- [ ] Workflow **Android Release APK** manuell mit `release_version=0.1.0+5` und den vorbereiteten Release Notes gestartet.

## Ergebnis des Release-Laufs prüfen

- [ ] `flutter analyze` war im Release-Lauf erfolgreich.
- [ ] `flutter test` war im Release-Lauf erfolgreich.
- [ ] Signierter Release-Build war erfolgreich.
- [ ] Tag `v0.1.0+5` wurde vom vorgesehenen Commit erzeugt.
- [ ] GitHub Release trägt den vorgesehenen Titel und die geprüften Release Notes.
- [ ] `taugts-0.1.0+5.apk` ist angehängt.
- [ ] `taugts-0.1.0+5.apk.sha256` ist angehängt.
- [ ] Lokale SHA-256-Prüfung der heruntergeladenen APK stimmt überein.
- [ ] APK lässt sich auf einem Android-Testgerät neu installieren.
- [ ] Aktualisierung einer vorhandenen, mit demselben Keystore signierten Installation funktioniert.
- [ ] Installierte App zeigt Version `0.1.0+5` im Über-Dialog.
- [ ] Kurzer Smoke-Test der Kernabläufe mit der veröffentlichten APK war erfolgreich.

## Nach dem Release

- [ ] Produktiven Branch `release/v0.1.0+5` exakt vom Release-Tag angelegt.
- [ ] Branch-Schutz für `release/**` greift.
- [ ] GitHub Release und Downloadlinks nochmals öffentlich geprüft.
- [ ] Story #157 durch Merge des zugehörigen PRs automatisch geschlossen.
- [ ] Offene Befunde als eigene Bug-Issues dokumentiert.
