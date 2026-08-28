# Taugt’s?

Taugt’s? ist eine Flutter-App zur lokalen Erfassung und Bewertung von Dingen. Die Datenhaltung bleibt auf dem Gerät. Ein späterer Datenaustausch wird als expliziter, nutzerinitiierter Import und Export entworfen und setzt keinen Cloud-Dienst voraus.

## Zielplattformen

- Android: primäre Zielplattform und Mobile-first-Referenz
- Windows: vorbereitet
- Linux: vorbereitet

## Projekt initialisieren

Voraussetzung ist ein installiertes Flutter-SDK mit aktivierter Unterstützung für die gewünschten Plattformen.

Unter Linux/macOS:

```bash
chmod +x tool/bootstrap.sh
./tool/bootstrap.sh
```

Unter Windows PowerShell:

```powershell
.\tool\bootstrap.ps1
```

Die Skripte ergänzen die offiziellen Flutter-Runner für Android, Windows und Linux und führen anschließend Formatierung, Analyse und Tests aus. Bereits vorhandene Dateien in `lib/`, `test/` und der Projektdokumentation bleiben erhalten.

## Entwicklung

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

## Struktur

```text
lib/
  app/                 App-Einstieg und globale Verdrahtung
  core/                wirklich projektweit gemeinsame Infrastruktur
  features/            fachlich geschnittene Funktionen
test/                   spiegelt die fachliche Struktur aus lib/
docs/                   dauerhafte Projekt- und Architekturentscheidungen
tool/                   Entwicklungs- und Bootstrap-Skripte
```

Neue Ordner und Abstraktionen werden erst bei einem konkreten Bedarf angelegt. Die verbindlichen Arbeitsregeln stehen in `AGENTS.md`.

Die bereits erarbeiteten fachlichen Anforderungen und die vorläufige Storyliste stehen in `docs/fachliche_anforderungen.md`. Das ausgewählte Logo liegt als hochauflösende PNG-Quelle unter `assets/icons/app_icon_source.png`; plattformspezifische Icon-Größen werden später reproduzierbar daraus erzeugt.
