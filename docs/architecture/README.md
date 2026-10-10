# Architektur

Taugt’s? wird featureorientiert und offline-first entwickelt. UI, Fachlogik und Persistenz werden klar getrennt. Die fachlichen Modelle bleiben unabhängig von Widgets, konkreten Datenbankpaketen und Plattform-APIs.

## Leitentscheidungen

- Android ist die Mobile-first-Referenz.
- Windows und Linux verwenden dieselbe Fachlogik und erhalten nur klar isolierte Plattformanbindungen.
- Nutzerdaten bleiben lokal; Netzwerkzugriffe sind für die Kernfunktion nicht erforderlich.
- Import und Export sind explizite Nutzeraktionen. Das versionierte JSON-Format, die Importvalidierung, Konfliktstrategien sowie der atomare Import sind implementiert und in der Entwicklerdokumentation beschrieben.
- UI-Zustand und Navigation werden featurebezogen verwaltet; ein eigenes gemeinsames Entwurfsrepository bündelt ungespeicherte Änderungen des jeweils geöffneten Erlebnisses.
- Die lokale Persistenz verwendet SQLite; Entscheidung und Folgen beschreibt
  [ADR 0001](0001-lokale-persistenz-mit-sqlite.md). Das vollständige aktuelle
  Tabellen- und Historienmodell einschließlich Migrationen und ER-Diagrammen
  beschreibt die [Datenbankdokumentation](datenbank.md).
- Getränkebewertungen verwenden stabile, in SQLite konfigurierte Kriterien.
  Qualitätswertungen und beschreibende Intensitäten bleiben getrennt; ein
  Gesamturteil wird nicht aus Einzelwerten berechnet.
- Das Erlebnis bildet den historischen Kontext. Das atomare Speichern
  aktualisiert bei einer Korrektur nur die Bewertung desselben Erlebnisses;
  ein neues Erlebnis erzeugt eine weitere historische Bewertung.
- Erlebnisse besitzen einen stabilen Typ `Restaurantbesuch` oder `Einkauf` sowie optional `beginn` und `ende`. Getrennte Plan-/Ist-Zeitfelder und persistierte Status werden seit Schema 4 nicht mehr geführt; der Zeitraum bleibt korrigierbar.
- Ein eigenes temporäres Erlebnisentwurfsrepository hält Positionen, Preise und Bewertungen bis zur zentralen Speicheraktion zusammen. Das produktive Repository schreibt sie innerhalb einer SQLite-Transaktion; Fehler rollen die gesamte Änderung zurück.
- Das Löschen von Produkten oder Orten blendet Stammdaten über eine Löschmarkierung aus; historische Erlebnisse, Preise und Bewertungen behalten ihre Referenzen, die bei Bedarf manuell neu zugeordnet werden können.

Diese Zurückhaltung vermeidet Architektur auf Vorrat und hält spätere Entscheidungen offen, ohne die Plattformunterstützung zu behindern.
