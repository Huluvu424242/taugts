import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

class LokaleDatenbank {
  LokaleDatenbank._(this.verbindung);

  factory LokaleDatenbank.oeffnen(Database verbindung) {
    final datenbank = LokaleDatenbank._(verbindung);
    datenbank._migriere();
    return datenbank;
  }

  static const schemaVersion = 5;
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
        _erstelleAktuellesSchema();
      } else {
        if (version == 1) {
          verbindung.execute(
            'ALTER TABLE bewertungen ADD COLUMN geaendert_am TEXT',
          );
          verbindung.execute(
            'UPDATE bewertungen SET geaendert_am = erstellt_am '
            'WHERE geaendert_am IS NULL',
          );
        }
        if (version <= 2) {
          _migriereAufSchemaV3();
        }
        if (version <= 3) {
          _migriereAufSchemaV4();
        }
        if (version <= 4) {
          _migriereAufSchemaV5();
        }
      }
      verbindung.userVersion = schemaVersion;
    });
  }

  void _migriereAufSchemaV5() {
    if (!_tabelleExistiert('orte')) {
      return;
    }
    for (final definition in [
      'adresse TEXT',
      'breitengrad REAL',
      'laengengrad REAL',
      'osm_referenz TEXT',
      'notiz TEXT',
    ]) {
      verbindung.execute('ALTER TABLE orte ADD COLUMN $definition');
    }
  }

  void _migriereAufSchemaV4() {
    if (!_tabelleExistiert('produkte')) return;
    for (final definition in [
      'produktart TEXT NOT NULL DEFAULT \'bier\'',
      'brauerei TEXT',
      'sorte TEXT',
      'alkoholgehalt REAL',
      'herkunft TEXT',
      'gebinde TEXT',
      'fuellmenge_ml INTEGER',
      'barcode TEXT',
      'notiz TEXT',
    ]) {
      verbindung.execute('ALTER TABLE produkte ADD COLUMN $definition');
    }
  }

  void _migriereAufSchemaV3() {
    verbindung.execute('''
      CREATE TABLE profile (
        id TEXT PRIMARY KEY,
        anzeigename TEXT,
        erstellt_am TEXT NOT NULL,
        geaendert_am TEXT NOT NULL
      )
    ''');
    final profilId = const Uuid().v4();
    final zeitpunkt = DateTime.now().toUtc().toIso8601String();
    verbindung.execute(
      'INSERT INTO profile VALUES (?, NULL, ?, ?)',
      [profilId, zeitpunkt, zeitpunkt],
    );

    if (_tabelleExistiert('erlebnisse')) {
      verbindung.execute(
        'ALTER TABLE erlebnisse ADD COLUMN herkunft_profil_id TEXT '
        'REFERENCES profile(id)',
      );
      verbindung.execute(
        'UPDATE erlebnisse SET herkunft_profil_id = ?',
        [profilId],
      );
    }
    if (_tabelleExistiert('bewertungen')) {
      verbindung.execute(
        'ALTER TABLE bewertungen ADD COLUMN herkunft_profil_id TEXT '
        'REFERENCES profile(id)',
      );
      verbindung.execute(
        'UPDATE bewertungen SET herkunft_profil_id = ?',
        [profilId],
      );
    }
  }

  bool _tabelleExistiert(String name) => verbindung
      .select(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
        [name],
      )
      .isNotEmpty;

  void _erstelleAktuellesSchema() {
    verbindung.execute('''
      CREATE TABLE profile (
        id TEXT PRIMARY KEY,
        anzeigename TEXT,
        erstellt_am TEXT NOT NULL,
        geaendert_am TEXT NOT NULL
      )
    ''');
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
        marke TEXT,
        produktart TEXT NOT NULL DEFAULT 'bier',
        brauerei TEXT,
        sorte TEXT,
        alkoholgehalt REAL,
        herkunft TEXT,
        gebinde TEXT,
        fuellmenge_ml INTEGER,
        barcode TEXT,
        notiz TEXT
      )
    ''');
    verbindung.execute('''
      CREATE TABLE orte (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        typ TEXT NOT NULL,
        erstellt_am TEXT NOT NULL,
        geaendert_am TEXT NOT NULL,
        adresse TEXT,
        breitengrad REAL,
        laengengrad REAL,
        osm_referenz TEXT,
        notiz TEXT
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
        geaendert_am TEXT NOT NULL,
        herkunft_profil_id TEXT NOT NULL REFERENCES profile(id)
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
        geaendert_am TEXT NOT NULL,
        herkunft_profil_id TEXT NOT NULL REFERENCES profile(id)
      )
    ''');
  }
}
