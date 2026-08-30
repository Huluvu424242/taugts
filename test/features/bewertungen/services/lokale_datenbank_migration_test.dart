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

  test('migriert Ortsdaten von Schema 4 auf Schema 5', () {
    final verbindung = sqlite3.openInMemory();
    verbindung.execute('''
      CREATE TABLE orte (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        typ TEXT NOT NULL,
        erstellt_am TEXT NOT NULL,
        geaendert_am TEXT NOT NULL
      )
    ''');
    verbindung.execute(
      "INSERT INTO orte VALUES ('o1', 'Alter Ort', 'privat', 'x', 'x')",
    );
    verbindung.userVersion = 4;

    final datenbank = LokaleDatenbank.oeffnen(verbindung);
    final zeile = verbindung.select('SELECT * FROM orte').single;

    expect(verbindung.userVersion, LokaleDatenbank.schemaVersion);
    expect(zeile['name'], 'Alter Ort');
    expect(zeile['adresse'], isNull);
    expect(zeile['osm_referenz'], isNull);
    datenbank.schliessen();
  });

  test('migriert Erlebnisse von Schema 5 auf Entwurfsfelder', () {
    final verbindung = sqlite3.openInMemory();
    verbindung.execute('''
      CREATE TABLE erlebnisse (
        id TEXT PRIMARY KEY,
        produkt_id TEXT NOT NULL,
        kaufort_id TEXT,
        konsumort_id TEXT,
        erlebt_am TEXT NOT NULL,
        erstellt_am TEXT NOT NULL,
        geaendert_am TEXT NOT NULL,
        herkunft_profil_id TEXT NOT NULL
      )
    ''');
    verbindung.execute(
      "INSERT INTO erlebnisse VALUES ('e1', 'p1', NULL, NULL, 'x', 'x', 'x', 'u1')",
    );
    verbindung.userVersion = 5;

    final datenbank = LokaleDatenbank.oeffnen(verbindung);
    final zeile = verbindung.select('SELECT * FROM erlebnisse').single;

    expect(zeile['preis'], isNull);
    expect(zeile['notiz'], isNull);
    expect(zeile['ist_entwurf'], 0);
    datenbank.schliessen();
  });

  test('migriert Kriterien und liefert stabile Getränkestandards aus', () {
    final verbindung = sqlite3.openInMemory();
    verbindung.execute('''
      CREATE TABLE kriterien (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        erstellt_am TEXT NOT NULL,
        geaendert_am TEXT NOT NULL
      )
    ''');
    verbindung.execute(
      "INSERT INTO kriterien VALUES ('alt', 'Vorhanden', 'x', 'x')",
    );
    verbindung.userVersion = 6;

    final datenbank = LokaleDatenbank.oeffnen(verbindung);
    final vorhanden = verbindung.select(
      "SELECT * FROM kriterien WHERE id = 'alt'",
    ).single;
    final standard = verbindung.select(
      "SELECT * FROM kriterien WHERE id LIKE 'c0000000-%' "
      'ORDER BY reihenfolge',
    );

    expect(verbindung.userVersion, LokaleDatenbank.schemaVersion);
    expect(vorhanden['name'], 'Vorhanden');
    expect(vorhanden['eingabetyp'], 'wertung');
    expect(vorhanden['aktiv'], 1);
    expect(standard, hasLength(7));
    expect(standard.first['name'], 'Gesamturteil');
    expect(standard.last['name'], 'Farbintensität');
    datenbank.schliessen();
  });
}
