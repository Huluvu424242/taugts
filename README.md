# Taugt’s?

<img src="assets/icons/app_icon_source.png" alt="Logo der App Taugt’s?" width="180">

Taugt’s? ist eine Offline-first-Flutter-App zur lokalen Erfassung und Bewertung
von Produkten, Orten und Erlebnissen. Die Datenhaltung bleibt auf dem Gerät;
für die Kernfunktionen sind weder Konto noch Serververbindung erforderlich.

Die vorbereitete erste Android-Version ist **0.1.0+1**.

## Funktionsumfang von 0.1.0+1

- Produkte wie Bier und andere Getränke lokal anlegen, suchen und bearbeiten
- Orte mit Typ und optionalen Detailangaben lokal verwalten
- Erlebnisentwürfe mit Produkt, Ort, Zeitpunkt, Preis, Menge, Gebinde und Notiz
  erfassen
- Getränke anhand geordneter, optionaler Qualitäts- und
  Intensitätskriterien bewerten
- Gesamturteil unabhängig von den Einzelkriterien vergeben
- Bewertungen historisch je Erlebnis erhalten
- lokales Profil als Herkunftskennung verwenden
- Offline-Barrierefreiheitserklärung und kontextbezogene Bug-Meldung nutzen

## Installation unter Android

Nach Veröffentlichung steht die APK unter
[GitHub Releases](https://github.com/Huluvu424242/taugts/releases) bereit:

1. `taugts-0.1.0+1.apk` und die zugehörige
   `.apk.sha256`-Datei herunterladen.
2. Die SHA-256-Prüfsumme kontrollieren.
3. Unter Android gegebenenfalls die Installation aus der verwendeten
   Download-App oder dem Browser erlauben.
4. Die APK öffnen und die Installation bestätigen.

Unter Windows lässt sich die Prüfsumme so ermitteln:

```powershell
Get-FileHash .\taugts-0.1.0+1.apk -Algorithm SHA256
```

Der Hash muss mit dem Inhalt von
`taugts-0.1.0+1.apk.sha256` übereinstimmen. Spätere APK-Updates funktionieren
nur mit demselben Release-Signierschlüssel.

## Datenschutz und lokale Daten

Alle fachlichen Daten werden lokal in einer SQLite-Datenbank gespeichert. Diese
Version enthält keine Telemetrie, keine versteckte Synchronisation und keinen
Cloud-Dienst. Ein Bugreport wird nur nach einer bewussten Nutzeraktion
vorbereitet und anschließend zur Prüfung im Browser geöffnet. Die App sendet
ihn nicht selbständig ab und hängt keine lokalen Nutzerdaten oder Diagnoselogs
an.

## Bekannte Einschränkungen

- Import und Export sind noch nicht enthalten.
- Produktpositionen innerhalb von Restaurantbesuchen und Einkäufen sind noch
  nicht umgesetzt.
- Windows und Linux sind architektonisch berücksichtigt, aber nicht Bestandteil
  dieses Releases.
- Die systematische manuelle Prüfung mit TalkBack, großer Systemschrift,
  Gestennavigation und einem kleinen Android-Gerät ist vor einer öffentlichen
  Freigabe noch abzuschließen; siehe
  [Story #30](https://github.com/Huluvu424242/taugts/issues/30).
- Vor Neuinstallation oder Wechsel des Signierschlüssels gibt es noch keinen
  Exportweg für die lokal gespeicherten Daten.

## Zielplattformen

- Android: primäre Zielplattform und Mobile-first-Referenz
- Windows: vorbereitet
- Linux: vorbereitet

## Entwicklung

Voraussetzung ist ein installiertes Flutter-SDK mit aktivierter Unterstützung
für die gewünschten Plattformen.

Repository klonen und Prüfungen ausführen:

```bash
git clone https://github.com/Huluvu424242/taugts.git
cd taugts
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter run
```

Die vorhandenen Bootstrap-Skripte können die offiziellen Flutter-Runner
ergänzen:

Unter Linux/macOS:

```bash
chmod +x tool/bootstrap.sh
./tool/bootstrap.sh
```

Unter Windows PowerShell:

```powershell
.\tool\bootstrap.ps1
```

Bereits vorhandene Dateien in `lib/`, `test/` und der Projektdokumentation
bleiben dabei erhalten.

## Projektstruktur

```text
lib/
  app/                 App-Einstieg und globale Verdrahtung
  core/                projektweit gemeinsame Infrastruktur
  features/            fachlich geschnittene Funktionen
test/                   spiegelt die fachliche Struktur aus lib/
docs/                   Projekt-, Architektur- und Releasedokumentation
tool/                   Entwicklungs- und Bootstrap-Skripte
```

Neue Ordner und Abstraktionen entstehen erst bei einem konkreten Bedarf. Die
verbindlichen Arbeitsregeln stehen in [AGENTS.md](AGENTS.md). Die fachlichen
Anforderungen und die Storyplanung stehen in
[docs/fachliche_anforderungen.md](docs/fachliche_anforderungen.md).

## App-Logo und Android-Icons

Das ausgewählte Logo liegt als hochauflösende PNG-Quelle unter
`assets/icons/app_icon_source.png`, wird in der App-Oberfläche angezeigt und
ist die Quelle für die Android-Launcher-Icons. Mit installiertem ImageMagick
lassen sich die Größen reproduzierbar neu erzeugen:

```bash
chmod +x tool/generate_app_icons.sh
./tool/generate_app_icons.sh
```

Herkunft, Verwendung und Lizenz stehen in [ATTRIBUTIONS.md](ATTRIBUTIONS.md).

## Android-Release

Der ausschließlich manuell startbare GitHub-Actions-Workflow
**Android Release APK** kann eine stabil signierte APK bauen und zusammen mit
ihrer SHA-256-Prüfsumme als GitHub Release veröffentlichen.

Einrichtung, Sicherheitsvorgaben und Ablauf stehen in
[docs/android-release.md](docs/android-release.md). Für Version 0.1.0+1 liegen
außerdem folgende Dokumente bereit:

- [Release Notes](docs/releases/0.1.0+1.md)
- [Release-Checkliste](docs/release-checklist-0.1.0+1.md)
- [Changelog](CHANGELOG.md)

Der Release-Workflow darf erst nach Einrichtung der Signing-Secrets und einer
gesonderten ausdrücklichen Freigabe gemäß `AGENTS.md` ausgeführt werden.

## Barrierefreiheit und Bug-Meldung

Die App enthält eine offline verfügbare Barrierefreiheitserklärung und bereitet
kontextbezogene Bugreports zur Prüfung auf GitHub vor. Umsetzungsstand und noch
offene manuelle Prüfungen stehen in
[docs/barrierefreiheit.md](docs/barrierefreiheit.md).

## Lizenz

Der Quellcode steht unter der [MIT-Lizenz](LICENSE). Herkunft und Lizenzen des
Logos sowie wesentlicher Open-Source-Komponenten sind in
[ATTRIBUTIONS.md](ATTRIBUTIONS.md) dokumentiert.
