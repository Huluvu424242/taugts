# Taugt’s?

<img src="assets/icons/app_icon_source.png" alt="Logo der App Taugt’s?" width="180">

Taugt’s? ist eine Offline-first-Flutter-App zur lokalen Erfassung und Bewertung
von Produkten, Orten und Erlebnissen. Die Datenhaltung bleibt auf dem Gerät;
für die Kernfunktionen sind weder Konto noch Serververbindung erforderlich.

Die vorbereitete Android-Version ist **0.1.0+8**.

## Funktionsumfang von 0.1.0+8

- Produkte wie Getränke, Speisen und andere Produkte lokal anlegen, suchen,
  bearbeiten und erneut bewerten, ohne Stammdaten neu anzulegen
- strukturierte Kategorien, Herkunft, Hersteller und Eigenschaften getrennt von
  freien Tags verwalten; Kategorie-Kriteriensets können Standards erweitern,
  ersetzen und aus Elternkategorien erben
- Orte mit Typ, optionaler Adresse, Koordinaten, OpenStreetMap-Referenz und
  Notiz lokal verwalten
- für nicht private Orte nach ausdrücklicher Nutzeraktion aus vorhandenen
  Koordinaten einen bearbeitbaren Namens- und Adressvorschlag über
  OpenStreetMap/Nominatim abrufen
- Restaurantbesuche und Einkäufe planen, beginnen, beenden, in einer
  Erlebnisübersicht wiederfinden und nachträglich bearbeiten
- Restaurantbestellungen und Einkaufslisten mit mehreren Positionen, Anzahl,
  Währung, optionalem Einzelpreis und sichtbarem Bewertungsstatus führen
- Produkte, Gaststätten und Geschäfte anhand lokal konfigurierbarer Kriterien
  bewerten; Wertung, Intensität, Ja/Nein, Zahl, Auswahl und Freitext werden
  entsprechend ihrem Eingabetyp erfasst und gespeichert
- Gaststätten und Geschäfte im selben Erlebnis getrennt von den
  Produktbewertungen bewerten; geänderte Ortsbewertungen werden gemeinsam mit
  dem Erlebnis gespeichert
- Produkt- und Ortsverläufe mit historischen Bewertungen, Einzelwerten,
  Preisen, Mengen, konkretem Erlebniszusammenhang und getrennten
  Beobachtungszeitpunkten anzeigen
- globale lokale Suche über Produkte, Orte, Erlebnisse, Bewertungen und Preise
  mit strukturierten und freien Filtern verwenden; die Startseiten-Kachel
  **Bewertungen** führt direkt in die Historien-Suche
- lokale Auswertungen zu vergleichbaren Kriterienwerten, Preis- und
  Bewertungsverläufen sowie ausdrücklich erfassten Andrangsdaten nutzen
- die lokalen Qualitätsauswertungen als Excel-Arbeitsmappe mit
  Produktbewertungen je Ort, zusammengefassten Ortsbewertungen und
  historischem Ortsverlauf einschließlich Liniendiagramm speichern
- EAN-, GTIN- und UPC-Barcodes bewusst starten, lokal scannen, bestätigen und
  einem vorhandenen oder neuen Produkt zuordnen; der Scanner ist zusätzlich
  direkt am EAN-Feld der Produkterfassung erreichbar
- den aktuellen Standort ausschließlich auf Nutzeraktion ermitteln, prüfen und
  bestätigt in das Ortsformular übernehmen
- Koordinaten optional auf einer OpenStreetMap-Karte kontrollieren und
  korrigieren; die manuelle Erfassung bleibt erhalten
- den vollständigen lokalen Datenbestand als versionierte JSON-Datei
  exportieren, speichern und unter Android über den Systemdialog teilen
- Importdateien vollständig validieren, ihre Auswirkungen vorab analysieren
  und zwischen „Bestand ersetzen“, „Import bevorzugen“ und „Lokalen Bestand
  bevorzugen“ wählen
- Importkonflikte einzeln entscheiden und fachliche Produkt- oder Ortsdubletten
  kontrolliert zusammenführen; persistente Aliasreferenzen sorgen bei späteren
  Importen für die Wiedererkennung bereits zusammengeführter Identitäten
- geprüfte Importe ausdrücklich und atomar ausführen; Fehler rollen den
  Importversuch vollständig zurück und ein lokales datensparsames Protokoll
  hält nur Status, Strategie und Ergebniszähler fest
- responsive mobile Startseite mit zentralen Aktionen und Navigation zu den
  fachlichen Bereichen nutzen
- Projektseite, Hilfe und veröffentlichte Dokumentation direkt aus dem
  Über-Dialog öffnen
- die Änderungshistorie offline im Über-Dialog lesen; sie wird direkt aus dem
  mit der App ausgelieferten `CHANGELOG.md` erzeugt und bleibt damit mit dem
  Projekt-Changelog synchron
- lokales Profil als Herkunftskennung verwenden
- Offline-Barrierefreiheitserklärung und kontextbezogene Bug-Meldung nutzen

## Installation unter Android

Nach Veröffentlichung steht die APK unter
[GitHub Releases](https://github.com/Huluvu424242/taugts/releases) bereit:

1. `taugts-0.1.0+8.apk` und die zugehörige
   `.apk.sha256`-Datei herunterladen.
2. Die SHA-256-Prüfsumme kontrollieren.
3. Unter Android gegebenenfalls die Installation aus der verwendeten
   Download-App oder dem Browser erlauben.
4. Die APK öffnen und die Installation bestätigen.

Unter Windows lässt sich die Prüfsumme so ermitteln:

```powershell
Get-FileHash .\taugts-0.1.0+8.apk -Algorithm SHA256
```

Der Hash muss mit dem Inhalt von
`taugts-0.1.0+8.apk.sha256` übereinstimmen. APK-Updates funktionieren nur mit
demselben Release-Signierschlüssel.

### Hinweis für Updates aus älteren Vorabversionen

Mit 0.1.0+7 wurde die lokale SQLite-Datenbank auf eine neue Baseline
konsolidiert und anschließend für typisierte Kriterienwerte erweitert. Dieser
Stand gilt auch für 0.1.0+8. Für die während der Vorabentwicklung verwendeten
Datenbankschemata aus 0.1.0+6 und davor besteht weiterhin kein direkter
Datenbank-Upgradepfad. Wer solche Daten behalten möchte, sollte **vor dem
Update** einen vollständigen JSON-Export erstellen und dessen Wiederherstellung
in einer frisch angelegten aktuellen Datenbank prüfen, bevor alte App-Daten
gelöscht werden. Ein Update von 0.1.0+7 auf 0.1.0+8 führt keine neue
Datenbank-Baseline ein.

## Datenschutz und lokale Daten

Alle fachlichen Daten werden lokal in einer SQLite-Datenbank gespeichert. Diese
Version enthält keine Telemetrie, keine versteckte Synchronisation und keinen
Cloud-Dienst. Kamera und Standort werden erst nach einer bewussten Nutzeraktion
verwendet; es gibt kein Hintergrund-Tracking. Ein Bugreport wird nur nach einer
bewussten Nutzeraktion vorbereitet und anschließend zur Prüfung im Browser
geöffnet. Die App sendet ihn nicht selbständig ab und hängt keine lokalen
Nutzerdaten oder Diagnoselogs an.

Import und Export sind ebenfalls ausdrücklich nutzerinitiierte lokale
Dateiaktionen. JSON- und Excel-Exporte werden lokal erzeugt und über den
Systemdialog gespeichert; dafür benötigt Taugt’s? keine allgemeine
Android-Dateisystemberechtigung. Importdateien werden vor jeder Übernahme
geprüft; der eigentliche Import erfolgt atomar, sodass ein Fehler den vorherigen
fachlichen Datenbestand erhält. Das lokale Importprotokoll speichert keine
importierten Namen, Notizen, Preise oder Bewertungswerte.

Die manuelle Orts- und Koordinateneingabe funktioniert offline. Für das Laden
der optionalen OpenStreetMap-Kartenkacheln, das ausdrücklich gestartete Reverse
Geocoding für nicht private Orte sowie für das Öffnen externer Projekt- und
Dokumentationslinks ist eine Netzwerkverbindung erforderlich. Für Orte vom Typ
**Privater Ort** werden keine exakten Koordinaten an den Geocoding-Dienst
übertragen.

## Bekannte Einschränkungen

- Windows und Linux sind architektonisch berücksichtigt, aber nicht Bestandteil
  dieses Releases.
- Barcode, Standort, Karte und Reverse Geocoding müssen vor einer öffentlichen
  Freigabe noch auf den vorgesehenen realen Zielgeräten manuell geprüft werden.
- Import und Export müssen vor Veröffentlichung zusätzlich mit realistischen
  Datenbeständen sowie Abbruch-, Fehler-, Wiederholungs- und Rollbackfällen auf
  einem realen Android-Gerät geprüft werden.
- Der Android-System-Speicherdialog und die mit 0.1.0+8 erzeugte
  Excel-Arbeitsmappe einschließlich Diagramm müssen vor Veröffentlichung auf
  einer realen Zielumgebung beziehungsweise in einer realen Tabellenkalkulation
  manuell geprüft werden.
- Der Übergang von einer Vorab-Datenbank aus 0.1.0+6 oder früher auf den seit
  0.1.0+7 geltenden Baseline-Stand besitzt keinen direkten SQLite-Migrationspfad;
  Datenerhalt muss über Export, frische Datenbank und geprüften Import
  abgesichert werden.
- Die systematische manuelle Prüfung mit TalkBack, großer Systemschrift,
  Gestennavigation und einem kleinen Android-Gerät ist vor einer öffentlichen
  Freigabe noch abzuschließen; siehe
  [Story #30](https://github.com/Huluvu424242/taugts/issues/30).

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
[docs/android-release.md](docs/android-release.md). Für Version 0.1.0+8 liegen
außerdem folgende Dokumente bereit:

- [Release Notes](docs/releases/0.1.0+8.md)
- [Release-Checkliste](docs/release-checklist-0.1.0+8.md)
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
