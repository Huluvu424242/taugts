# Taugt’s?

<img src="assets/icons/app_icon_source.png" alt="Logo der App Taugt’s?" width="180">

Taugt’s? ist eine Offline-first-Flutter-App zur lokalen Erfassung und Bewertung
von Produkten, Orten und Erlebnissen. Die Datenhaltung bleibt auf dem Gerät;
für die Kernfunktionen sind weder Konto noch Serververbindung erforderlich.

Die vorbereitete Android-Version ist **0.1.0+4**.

## Funktionsumfang von 0.1.0+4

- Produkte wie Getränke, Speisen und andere Dinge lokal anlegen, suchen,
  bearbeiten und erneut bewerten, ohne Stammdaten neu anzulegen
- Orte mit Typ, optionaler Adresse, Koordinaten, OpenStreetMap-Referenz und
  Notiz lokal verwalten
- Restaurantbesuche und Einkäufe planen, beginnen, beenden, in einer
  Erlebnisübersicht wiederfinden und nachträglich bearbeiten
- Restaurantbestellungen und Einkaufslisten mit mehreren Positionen, Anzahl,
  Währung, optionalem Einzelpreis und sichtbarem Bewertungsstatus führen
- Produkte anhand typabhängiger, lokal konfigurierbarer Kriterien bewerten
- Gaststätten und Geschäfte im selben Erlebnis getrennt von den
  Produktbewertungen bewerten
- Produkt- und Ortsverläufe mit historischen Bewertungen, Einzelwerten,
  Preisen, Mengen, konkretem Erlebniszusammenhang und getrennten
  Beobachtungszeitpunkten anzeigen
- EAN-, GTIN- und UPC-Barcodes bewusst starten, lokal scannen, bestätigen und
  einem vorhandenen oder neuen Produkt zuordnen
- den aktuellen Standort ausschließlich auf Nutzeraktion ermitteln, prüfen und
  bestätigt in das Ortsformular übernehmen
- Koordinaten optional auf einer OpenStreetMap-Karte kontrollieren und
  korrigieren; die manuelle Erfassung bleibt erhalten
- responsive mobile Startseite mit zentralen Aktionen und Navigation zu den
  fachlichen Bereichen nutzen
- Projektseite und veröffentlichte Dokumentation direkt aus dem Über-Dialog
  öffnen
- lokales Profil als Herkunftskennung verwenden
- Offline-Barrierefreiheitserklärung und kontextbezogene Bug-Meldung nutzen

## Installation unter Android

Nach Veröffentlichung steht die APK unter
[GitHub Releases](https://github.com/Huluvu424242/taugts/releases) bereit:

1. `taugts-0.1.0+4.apk` und die zugehörige
   `.apk.sha256`-Datei herunterladen.
2. Die SHA-256-Prüfsumme kontrollieren.
3. Unter Android gegebenenfalls die Installation aus der verwendeten
   Download-App oder dem Browser erlauben.
4. Die APK öffnen und die Installation bestätigen.

Unter Windows lässt sich die Prüfsumme so ermitteln:

```powershell
Get-FileHash .\taugts-0.1.0+4.apk -Algorithm SHA256
```

Der Hash muss mit dem Inhalt von
`taugts-0.1.0+4.apk.sha256` übereinstimmen. APK-Updates funktionieren nur mit
demselben Release-Signierschlüssel.

## Datenschutz und lokale Daten

Alle fachlichen Daten werden lokal in einer SQLite-Datenbank gespeichert. Diese
Version enthält keine Telemetrie, keine versteckte Synchronisation und keinen
Cloud-Dienst. Kamera und Standort werden erst nach einer bewussten Nutzeraktion
verwendet; es gibt kein Hintergrund-Tracking. Ein Bugreport wird nur nach einer
bewussten Nutzeraktion vorbereitet und anschließend zur Prüfung im Browser
geöffnet. Die App sendet ihn nicht selbständig ab und hängt keine lokalen
Nutzerdaten oder Diagnoselogs an.

Die manuelle Orts- und Koordinateneingabe funktioniert offline. Für das Laden
der optionalen OpenStreetMap-Kartenkacheln sowie für das Öffnen externer
Projekt- und Dokumentationslinks ist eine Netzwerkverbindung erforderlich.

## Bekannte Einschränkungen

- Import und Export sind noch nicht enthalten.
- Windows und Linux sind architektonisch berücksichtigt, aber nicht Bestandteil
  dieses Releases.
- Barcode, Standort und Karte müssen vor einer öffentlichen Freigabe noch auf
  den vorgesehenen realen Zielgeräten manuell geprüft werden.
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
[docs/android-release.md](docs/android-release.md). Für Version 0.1.0+4 liegen
außerdem folgende Dokumente bereit:

- [Release Notes](docs/releases/0.1.0+4.md)
- [Release-Checkliste](docs/release-checklist-0.1.0+4.md)
- [Changelog](CHANGELOG.md)

Der Release-Workflow darf erst nach Einrichtung der Signing-Secrets und einer
gesonderten ausdrücklichen Freigabe gemäß `AGENTS.md` ausgeführt werden.

## Dokumentation, Barrierefreiheit und Bug-Meldung

Die veröffentlichte Projektdokumentation ist unter
[huluvu424242.github.io/taugts](https://huluvu424242.github.io/taugts/)
erreichbar. Die App enthält außerdem eine offline verfügbare
Barrierefreiheitserklärung und bereitet kontextbezogene Bugreports zur Prüfung
auf GitHub vor. Umsetzungsstand und noch offene manuelle Prüfungen stehen in
[docs/barrierefreiheit.md](docs/barrierefreiheit.md).

## Lizenz

Der Quellcode steht unter der [MIT-Lizenz](LICENSE). Herkunft und Lizenzen des
Logos sowie wesentlicher Open-Source-Komponenten sind in
[ATTRIBUTIONS.md](ATTRIBUTIONS.md) dokumentiert.
