# Architektur

Taugt’s? wird featureorientiert und offline-first entwickelt. UI, Fachlogik und Persistenz werden klar getrennt. Die fachlichen Modelle bleiben unabhängig von Widgets, konkreten Datenbankpaketen und Plattform-APIs.

## Leitentscheidungen

- Android ist die Mobile-first-Referenz.
- Windows und Linux verwenden dieselbe Fachlogik und erhalten nur klar isolierte Plattformanbindungen.
- Nutzerdaten bleiben lokal; Netzwerkzugriffe sind für die Kernfunktion nicht erforderlich.
- Import und Export sind explizite Nutzeraktionen. Dateiformat, Konfliktstrategie und Datenschutz werden vor ihrer Implementierung als eigene Architekturentscheidung dokumentiert.
- State Management und Navigation werden erst bei konkretem Bedarf ausgewählt.
- Die lokale Persistenz verwendet SQLite; Entscheidung und Folgen beschreibt
  [ADR 0001](0001-lokale-persistenz-mit-sqlite.md).

Diese Zurückhaltung vermeidet Architektur auf Vorrat und hält spätere Entscheidungen offen, ohne die Plattformunterstützung zu behindern.
