import 'package:sqlite3/sqlite3.dart';

class LokaleDatenbank {
  LokaleDatenbank._(this.verbindung);

  factory LokaleDatenbank.oeffnen(Database verbindung) {
    final datenbank = LokaleDatenbank._(verbindung);
    datenbank._migriere();
    return datenbank;
  }

  static const schemaVersion = 2;
  final Database verbindung;

  void schliessen() => verbindung.close();

  void transaktion(void Function() aktion) {
    verbindung.execute('BEGIN IMMEDIATE');
    try {
      aktion();
      verbindung.execute('COMMIT');
    } catch (_) {
      verbindung.execute('ROLLBACK');
      rethrow;
    }
  }

  void _migriere() {
    verbindung.execute('PRAGMA foreign_keys = ON');
    final version = verbindung.userVersion;
    if (version > schemaVersion) {
      throw StateError('Nicht unterstützte Schemaversion: $version');
    }
    transaktion(() {
      if (version == 0) {
        _erstelleSchemaV2();
      } else if (version == 1) {
        verbindung.execute(
          'ALTER TABLE bewertungen ADD COLUMN geaendert_am TEXT',
        );
        verbindung.execute(
          'UPDATE bewertungen SET geaendert_am = erstellt_am '
          'WHERE geaendert_am IS NULL',
        );
      }
      verbindung.userVersion = schemaVersion;
    });
  }

  void _erstelleSchemaV2() {
    verbindung.execute('''
      CREATE TABLE objekte (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        art TEXT NOT NULL,
        erstellt_am TEXT NOT NULL,
        geaendert_am TEXT NOT NULL
      )
    ''');
    verbindung.execute('''
      CREATE TABLE produkte (
        objekt_id TEXT PRIMARY KEY REFERENCES objekte(id) ON DELETE CASCADE,
        marke TEXT
      )
    ''');
    verbindung.execute('''
      CREATE TABLE orte (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        typ TEXT NOT NULL,
        erstellt_am TEXT NOT NULL,
        geaendert_am TEXT NOT NULL
      )
    ''');
    verbindung.execute('''
      CREATE TABLE erlebnisse (
        id TEXT PRIMARY KEY,
        produkt_id TEXT NOT NULL REFERENCES produkte(objekt_id),
        kaufort_id TEXT REFERENCES orte(id),
        konsumort_id TEXT REFERENCES orte(id),
        erlebt_am TEXT NOT NULL,
        erstellt_am TEXT NOT NULL,
        geaendert_am TEXT NOT NULL
      )
    ''');
    verbindung.execute('''
      CREATE TABLE kriterien (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        erstellt_am TEXT NOT NULL,
        geaendert_am TEXT NOT NULL
      )
    ''');
    verbindung.execute('''
      CREATE TABLE bewertungen (
        id TEXT PRIMARY KEY,
        erlebnis_id TEXT NOT NULL REFERENCES erlebnisse(id) ON DELETE CASCADE,
        kriterium_id TEXT NOT NULL REFERENCES kriterien(id),
        wert REAL NOT NULL,
        erstellt_am TEXT NOT NULL,
        geaendert_am TEXT NOT NULL
      )
    ''');
  }
}
