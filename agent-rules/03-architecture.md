# Architektur und Implementierung

## Implementierung

- Für jede Story oder jeden Bug einen eigenen Branch verwenden und den Umfang eng halten.
- UI, Fachlogik, Persistenz, Import/Export und Plattformintegration klar trennen.
- Screens und Widgets enthalten keine Datenbank-, Dateiformat- oder Plattformdetails.
- Externe Abhängigkeiten werden hinter kleinen, testbaren Schnittstellen gekapselt.
- Lade-, Leer-, Erfolgs- und Fehlerzustände sichtbar behandeln, wenn sie für die Funktion relevant sind.
- Nutzereingaben bei Fehlern erhalten; Fehler nicht still ignorieren; keine leeren `catch`-Blöcke verwenden.
- Nach asynchronen Operationen den Widget-Lebenszyklus beachten und doppelte Seiteneffekte verhindern.

## Architekturleitplanken

### Offline-first und Datenschutz

- Die Kernfunktion muss ohne Netzwerkverbindung nutzbar sein.
- Nutzerdaten werden ausschließlich lokal gespeichert, solange keine spätere Story ausdrücklich etwas anderes festlegt.
- Es gibt keine versteckte Synchronisation, Telemetrie oder Cloud-Übertragung.
- Datenaustausch erfolgt nur als explizite, vom Nutzer ausgelöste Import- oder Exportaktion.
- Vor Implementierung des Datenaustauschs werden Formatversionierung, Validierung, Konfliktbehandlung, atomare Schreibvorgänge und verständliche Fehlerfälle festgelegt.
- Exportierte Daten enthalten nur fachlich erforderliche Informationen. Potenziell sensible Inhalte werden nicht protokolliert.

### Featureorientierte Struktur

Die Anwendung wird zuerst nach fachlichen Features und erst darin nach technischen Rollen gegliedert:

```text
lib/
  app/
  core/
  features/
    bewertungen/
      models/
      services/
      presentation/
```

- Kleine Features bleiben flach; Unterordner und Abstraktionen entstehen nur bei konkretem Bedarf.
- Projektweit gemeinsame Infrastruktur darf unter `core/` liegen. Feature-lokale Logik bleibt beim Feature.
- Tests spiegeln die fachliche Struktur aus `lib/` soweit sinnvoll.
- Fachmodelle bleiben möglichst unabhängig von Flutter-Widgets, Persistenzpaketen und Import-/Exportformaten.
- Eine fachliche Funktion besitzt einen zentralen Implementierungsweg, den verschiedene Einstiegspunkte wiederverwenden.
- State Management, Navigation und Persistenzbibliothek werden nicht auf Vorrat festgelegt. Neue Packages benötigen einen belegbaren Nutzen sowie Prüfung von Wartungszustand, Plattformunterstützung und Lizenz.

### Plattformen

- Android ist die primäre Zielplattform und Referenz für Bedienung und Releasefähigkeit.
- Gestaltung und Interaktion erfolgen Mobile first für kleine Touch-Geräte.
- Fachlogik bleibt plattformneutral in Dart. Android-, Windows- und Linux-spezifischer Code wird an klaren Rändern isoliert.
- Windows und Linux werden bei Architektur- und Paketentscheidungen mitgeprüft, auch wenn eine Story zunächst nur Android umsetzt.
- Web und iOS gehören ohne eigene Story nicht zum Projektumfang.

### Clean Code und Testbarkeit

- Sprechende Namen, kleine Verantwortungsbereiche, geringe Kopplung und wenige versteckte Seiteneffekte verwenden.
- Keine Architektur auf Vorrat und keine Bibliothek für triviale Funktionalität einführen.
- Strukturierte Daten über klar benannte Modelle statt lose Maps durch mehrere Schichten reichen.
- `const` sinnvoll verwenden, Kontrollstrukturen klammern und Kommentare auf das Warum beschränken.
- Fachlogik unabhängig von Widgets und Plattformdetails testen; technische Abhängigkeiten durch Fakes ersetzen können.

### Flutter-spezifische Analysefehler vermeiden

- `Semantics` und andere Konstruktoren, die in der unterstützten Flutter-Version nicht `const` sind, dürfen nicht durch einen äußeren konstanten Konstruktor-Kontext implizit als konstant ausgewertet werden.
- Vor dem Hinzufügen oder Beibehalten von `const` an einem Widget mit `child` oder `children` ist der **gesamte darunterliegende Widgetbaum** zu prüfen. Enthält er direkt oder indirekt einen nicht konstanten Konstruktor, insbesondere `Semantics`, Builder, zustandsabhängige Widgets oder SDK-abhängig nicht konstante Widgets, darf der äußere Container nicht `const` sein.
- In zusammengesetzten Widgetbäumen gilt verbindlich: **konstante Blätter einzeln markieren, nicht den gemeinsamen Vorfahren pauschal konstant machen**. Beispielsweise bleibt `Center` ohne `const`, wenn sein Kind `Semantics` ist; nur ein darunterliegender nachweislich konstanter `CircularProgressIndicator` erhält `const`.
- Wird ein Widget in einen bereits konstanten Baum eingefügt oder ein vorhandenes Kind durch `Semantics` beziehungsweise ein anderes nicht konstantes Widget umschlossen, muss die Vorfahrenkette bis zum nächsten ohnehin nicht konstanten Widget geprüft und ein dort vorhandenes `const` entfernt werden. Nur das unmittelbar bearbeitete Widget zu prüfen ist unzureichend.
- Vor jedem Commit mit Flutter-UI-Änderungen ist repositoryweit nach vergleichbaren indirekten `const`-Kontexten in den geänderten Widgetbäumen zu suchen. Anschließend ist mindestens die betroffene Datei mit `flutter analyze` zu prüfen; vor Abschluss gelten zusätzlich die vollständigen Prüfanforderungen aus [Qualität und Dokumentation](06-quality-documentation.md#codestyle-und-prüfungen).
- Jeder einzelne `await` innerhalb eines `State`-Objekts bildet eine neue asynchrone Lücke. Nach jedem `await` muss vor der anschließenden Verwendung von `context`, `Navigator`, `ScaffoldMessenger`, Fokus, Scrollposition oder `setState` erneut `mounted` geprüft werden.
- Eine `mounted`-Prüfung vor einem weiteren `await` schützt nicht den Code nach diesem `await`.
- Wird nach einem `await` ein zuvor gespeicherter `BuildContext` verwendet, muss dessen eigener Lebenszyklus mit `context.mounted` geprüft werden.
- Redundante Konstruktionen wie `if (!mounted) return; if (mounted) ...` sind zu vermeiden.

## Datenmigration und Persistenz

- Persistierte Daten benötigen ein erkennbares Schema beziehungsweise eine Versionsnummer.
- Schemaänderungen erhalten getestete, vorwärtsgerichtete Migrationen. Bestehende Nutzerdaten dürfen nicht still verworfen werden.
- Schreibvorgänge müssen Abstürze und Teilfehler möglichst ohne beschädigten Datenbestand überstehen.
- Importdaten gelten als nicht vertrauenswürdig und werden vollständig validiert, bevor sie den lokalen Bestand verändern.
- Vor migrationsrelevanten Änderungen werden Sicherungs- und Wiederherstellungsverhalten dokumentiert.
