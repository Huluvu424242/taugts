import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/persistenz/aktuelles_datenbankschema.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';

void main() {
  test(
    'stellt beim Öffnen den vollständigen aktuellen physischen Tabellenstand bereit',
    () {
      final verbindung = sqlite3.openInMemory();
      final datenbank = LokaleDatenbank.oeffnen(verbindung);

      final tabellen = verbindung
          .select(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .map((zeile) => zeile['name'] as String)
          .toSet();

      expect(
        tabellen,
        containsAll(AktuellesDatenbankschema.erwarteteTabellen),
      );
      expect(verbindung.userVersion, LokaleDatenbank.schemaVersion);
      expect(verbindung.select('PRAGMA foreign_key_check'), isEmpty);

      datenbank.schliessen();
    },
  );

  test('Feature-Baseline bleibt idempotent', () {
    final verbindung = sqlite3.openInMemory();
    final datenbank = LokaleDatenbank.oeffnen(verbindung);

    AktuellesDatenbankschema.stelleFeatureTabellenBereit(verbindung);
    AktuellesDatenbankschema.stelleFeatureTabellenBereit(verbindung);

    expect(verbindung.select('PRAGMA foreign_key_check'), isEmpty);
    datenbank.schliessen();
  });
}
