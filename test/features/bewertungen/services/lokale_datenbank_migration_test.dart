import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';

void main() {
  test('migriert Schema 1 bis zum aktuellen Schema ohne Datenverlust', () {
    final verbindung = sqlite3.openInMemory();
    verbindung.execute('''
      CREATE TABLE bewertungen (
        id TEXT PRIMARY KEY,
        erlebnis_id TEXT NOT NULL,
        kriterium_id TEXT NOT NULL,
        wert REAL NOT NULL,
        erstellt_am TEXT NOT NULL
      )
    ''');
    verbindung.execute(
      "INSERT INTO bewertungen VALUES ('b1', 'e1', 'k1', 4.0, "
      "'2026-08-28T20:00:00.000Z')",
    );
    verbindung.userVersion = 1;

    final datenbank = LokaleDatenbank.oeffnen(verbindung);
    final zeile = verbindung.select('SELECT * FROM bewertungen').single;
    final profile = verbindung.select('SELECT * FROM profile');

    expect(verbindung.userVersion, LokaleDatenbank.schemaVersion);
    expect(zeile['wert'], 4.0);
    expect(zeile['geaendert_am'], zeile['erstellt_am']);
    expect(zeile['herkunft_profil_id'], profile.single['id']);
    datenbank.schliessen();
  });

  test('migriert Produktstammdaten von Schema 3 auf Schema 4', () {
    final verbindung = sqlite3.openInMemory();
    verbindung.execute('''
      CREATE TABLE produkte (
        objekt_id TEXT PRIMARY KEY,
        marke TEXT
      )
    ''');
    verbindung.execute(
      "INSERT INTO produkte VALUES ('p1', 'Bestehende Marke')",
    );
    verbindung.userVersion = 3;

    final datenbank = LokaleDatenbank.oeffnen(verbindung);
    final zeile = verbindung.select('SELECT * FROM produkte').single;

    expect(verbindung.userVersion, LokaleDatenbank.schemaVersion);
    expect(zeile['marke'], 'Bestehende Marke');
    expect(zeile['produktart'], 'bier');
    expect(zeile['barcode'], isNull);
    datenbank.schliessen();
  });
}
