# ADR 0001: Lokale Persistenz mit SQLite

## Status

Angenommen am 28. August 2026.

## Kontext

Taugt’s? benötigt stabile Beziehungen zwischen Objekten, Produkten, Orten,
Erlebnissen, Bewertungen und Kriterien. Schreibvorgänge müssen atomar sein und
das Schema muss ohne Verlust vorhandener Daten vorwärts migriert werden können.
Android ist Referenzplattform, Windows und Linux bleiben unterstützt. JSON ist
für den späteren Datenaustausch vorgesehen, nicht als Arbeitsdatenbank.

## Entscheidung

Die Anwendung verwendet SQLite über das Dart-Paket `sqlite3`. Die Datenbank wird
im Anwendungsdatenverzeichnis abgelegt. Fachmodelle und Repository-Schnittstellen
kennen weder SQLite noch Flutter. Die Schemaversion liegt in `PRAGMA user_version`;
Migrationen laufen innerhalb einer Transaktion. Fremdschlüssel werden für jede
Verbindung aktiviert.

## Folgen

- Beziehungen und atomare Änderungen werden durch SQLite abgesichert.
- In-Memory-Datenbanken ermöglichen schnelle Repository- und Migrationstests.
- Android, Windows und Linux verwenden dieselbe Persistenzimplementierung.
- Schemaänderungen müssen die Schemaversion erhöhen und eine getestete,
  vorwärtsgerichtete Migration ergänzen.
- Der direkte SQL-Zugriff bleibt auf den Servicebereich des Features begrenzt.
- Die Migration auf Schema 8 überführt bisherige produktbezogene Erlebnisse
  verlustfrei in allgemeine Restaurantbesuche. Der bisherige Zeitpunkt wird als
  Planung übernommen; Produkt-, Preis-, Mengen- und Ortsbezüge bleiben bis zur
  Einführung der Erlebnispositionen als Migrationsdaten erhalten.
