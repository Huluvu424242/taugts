import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:uuid/uuid.dart';

class LokaleDatenbank {
  LokaleDatenbank._(this.verbindung);

  factory LokaleDatenbank.oeffnen(Database verbindung) {
    final datenbank = LokaleDatenbank._(verbindung);
    datenbank._migriere();
    return datenbank;
  }

  static const schemaVersion = 12;
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
        if (version <= 5) {
          _migriereAufSchemaV6();
        }
        if (version <= 6) {
          _migriereAufSchemaV7();
        }
        if (version <= 7) {
          _migriereAufSchemaV8();
        }
        if (version <= 8) {
          _migriereAufSchemaV9();
        }
        if (version <= 9) {
          _migriereAufSchemaV10();
        }
        if (version <= 10) {
          _migriereAufSchemaV11();
        }
        if (version <= 11) {
          _migriereAufSchemaV12();
        }
      }
      _stelleStandardkriterienBereit();
      verbindung.userVersion = schemaVersion;
    });
  }

  void _migriereAufSchemaV12() {
    if (!_tabelleExistiert('bewertungen')) return;
    verbindung.execute(
      'ALTER TABLE bewertungen ADD COLUMN kriterium_beschreibung TEXT',
    );
    verbindung.execute(
      "ALTER TABLE bewertungen ADD COLUMN kriterium_auswahlwerte TEXT NOT NULL DEFAULT ''",
    );
    if (_tabelleExistiert('kriterien')) {
      verbindung.execute('''
        UPDATE bewertungen SET
          kriterium_beschreibung = (
            SELECT beschreibung FROM kriterien k WHERE k.id = kriterium_id
          ),
          kriterium_auswahlwerte = COALESCE((
            SELECT auswahlwerte FROM kriterien k WHERE k.id = kriterium_id
          ), '')
      ''');
    }
  }

  void _migriereAufSchemaV11() {
    final hatKriterien = _tabelleExistiert('kriterien');
    if (hatKriterien) {
      verbindung.execute(
        "ALTER TABLE kriterien ADD COLUMN objektart TEXT NOT NULL DEFAULT 'getraenk'",
      );
      verbindung.execute(
        'ALTER TABLE kriterien ADD COLUMN version INTEGER NOT NULL DEFAULT 1',
      );
      verbindung.execute(
        "ALTER TABLE kriterien ADD COLUMN auswahlwerte TEXT NOT NULL DEFAULT ''",
      );
      verbindung.execute("UPDATE kriterien SET objektart = CASE produktart "
          "WHEN 'speise' THEN 'speise' WHEN 'sonstiges' THEN 'sonstigesProdukt' "
          "ELSE 'getraenk' END");
    }
    if (_tabelleExistiert('bewertungen')) {
      for (final definition in [
        'ort_id TEXT REFERENCES orte(id)',
        'kriterium_name TEXT',
        'kriterium_eingabetyp TEXT',
        'kriterium_reihenfolge INTEGER',
        'kriterium_version INTEGER',
      ]) {
        verbindung.execute('ALTER TABLE bewertungen ADD COLUMN $definition');
      }
      if (hatKriterien) {
        verbindung.execute('''
          UPDATE bewertungen SET
            kriterium_name = (SELECT name FROM kriterien k WHERE k.id = kriterium_id),
            kriterium_eingabetyp = (SELECT eingabetyp FROM kriterien k WHERE k.id = kriterium_id),
            kriterium_reihenfolge = (SELECT reihenfolge FROM kriterien k WHERE k.id = kriterium_id),
            kriterium_version = 1
        ''');
      }
    }
  }

  void _migriereAufSchemaV10() {
    if (!_tabelleExistiert('kriterien')) return;
    verbindung.execute(
      "ALTER TABLE kriterien ADD COLUMN produktart TEXT NOT NULL DEFAULT 'bier'",
    );
  }

  void _migriereAufSchemaV9() {
    if (!_tabelleExistiert('erlebnisse')) return;
    _erstelleErlebnispositionenTabellen();
    verbindung.execute('''
      INSERT INTO erlebnispositionen (
        id, erlebnis_id, produkt_id, anzahl, erstellt_am, geaendert_am
      )
      SELECT id, id, produkt_id, 1, erstellt_am, geaendert_am
      FROM erlebnisse
      WHERE produkt_id IS NOT NULL
    ''');
    verbindung.execute('''
      INSERT INTO preisbeobachtungen (
        id, erlebnis_id, erlebnis_position_id, produkt_id, ort_id,
        beobachtet_am, betrag_minor, waehrung, erstellt_am, geaendert_am
      )
      SELECT id, id, id, produkt_id,
        COALESCE(ort_id, konsumort_id, kaufort_id),
        COALESCE(tatsaechlicher_beginn, erlebt_am, erstellt_am),
        CAST(ROUND(preis * 100) AS INTEGER), 'EUR', erstellt_am, geaendert_am
      FROM erlebnisse
      WHERE produkt_id IS NOT NULL AND preis IS NOT NULL
    ''');
    if (_tabelleExistiert('bewertungen')) {
      if (!_spalteExistiert('bewertungen', 'erlebnis_position_id')) {
        verbindung.execute(
          'ALTER TABLE bewertungen ADD COLUMN erlebnis_position_id TEXT '
          'REFERENCES erlebnispositionen(id) ON DELETE CASCADE',
        );
      }
      verbindung.execute('''
        UPDATE bewertungen
        SET erlebnis_position_id = erlebnis_id
        WHERE EXISTS (
          SELECT 1 FROM erlebnispositionen p
          WHERE p.id = bewertungen.erlebnis_id
        )
      ''');
    }
  }

  void _migriereAufSchemaV8() {
    if (!_tabelleExistiert('erlebnisse')) return;
    final hatBewertungen = _tabelleExistiert('bewertungen');
    if (hatBewertungen) {
      verbindung.execute(
        'ALTER TABLE bewertungen RENAME TO bewertungen_schema7',
      );
    }
    verbindung.execute('ALTER TABLE erlebnisse RENAME TO erlebnisse_schema7');
    _erstelleErlebnisseTabelle();
    _erstelleErlebnispositionenTabellen();
    verbindung.execute('''
      INSERT INTO erlebnisse (
        id, typ, status, ort_id, geplanter_tag, geplante_minute,
        geplante_dauer_minuten, tatsaechlicher_beginn, tatsaechliches_ende,
        erstellt_am, geaendert_am, herkunft_profil_id, notiz, ist_entwurf,
        produkt_id, kaufort_id, konsumort_id, erlebt_am, preis, menge, gebinde
      )
      SELECT
        id, 'restaurantbesuch', 'geplant',
        COALESCE(konsumort_id, kaufort_id), SUBSTR(erlebt_am, 1, 10),
        CAST(STRFTIME('%H', erlebt_am) AS INTEGER) * 60 +
          CAST(STRFTIME('%M', erlebt_am) AS INTEGER),
        NULL, NULL, NULL, erstellt_am, geaendert_am, herkunft_profil_id,
        notiz, ist_entwurf, produkt_id, kaufort_id, konsumort_id, erlebt_am,
        preis, menge, gebinde
      FROM erlebnisse_schema7
    ''');
    if (hatBewertungen) {
      _erstelleBewertungenTabelle();
      verbindung.execute('''
        INSERT INTO bewertungen (
          id, erlebnis_id, kriterium_id, wert, erstellt_am, geaendert_am,
          herkunft_profil_id
        )
        SELECT id, erlebnis_id, kriterium_id, wert, erstellt_am,
          geaendert_am, herkunft_profil_id
        FROM bewertungen_schema7
      ''');
      verbindung.execute('DROP TABLE bewertungen_schema7');
    }
    verbindung.execute('DROP TABLE erlebnisse_schema7');
  }

  void _migriereAufSchemaV7() {
    if (!_tabelleExistiert('kriterien')) return;
    for (final definition in [
      'beschreibung TEXT',
      "eingabetyp TEXT NOT NULL DEFAULT 'wertung'",
      'reihenfolge INTEGER NOT NULL DEFAULT 0',
      'aktiv INTEGER NOT NULL DEFAULT 1',
    ]) {
      verbindung.execute('ALTER TABLE kriterien ADD COLUMN $definition');
    }
  }

  void _stelleStandardkriterienBereit() {
    if (!_tabelleExistiert('kriterien')) return;
    final zeitpunkt = DateTime.utc(2026, 8, 30);
    final kriterien = [
      ...StandardGetraenkekriterien.alle(zeitpunkt),
      ...StandardSpeisekriterien.alle(zeitpunkt),
      StandardFallbackKriterien.gesamturteil(zeitpunkt),
      ...StandardOrtskriterien.gastronomie(zeitpunkt),
      ...StandardOrtskriterien.geschaeft(zeitpunkt),
    ];
    for (final kriterium in kriterien) {
      verbindung.execute(
        '''
          INSERT OR IGNORE INTO kriterien (
            id, name, beschreibung, eingabetyp, reihenfolge, aktiv,
            erstellt_am, geaendert_am, produktart, objektart, version,
            auswahlwerte
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          kriterium.id,
          kriterium.name,
          kriterium.beschreibung,
          kriterium.eingabetyp.name,
          kriterium.reihenfolge,
          kriterium.aktiv ? 1 : 0,
          kriterium.erstelltAm.toIso8601String(),
          kriterium.geaendertAm.toIso8601String(),
          kriterium.produktart.name,
          kriterium.wirksameObjektart.name,
          kriterium.version,
          kriterium.auswahlwerte.join('\n'),
        ],
      );
    }
  }

  void _migriereAufSchemaV6() {
    if (!_tabelleExistiert('erlebnisse')) return;
    for (final definition in [
      'preis REAL',
      'menge REAL',
      'gebinde TEXT',
      'notiz TEXT',
      'ist_entwurf INTEGER NOT NULL DEFAULT 0',
    ]) {
      verbindung.execute('ALTER TABLE erlebnisse ADD COLUMN $definition');
    }
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

  bool _tabelleExistiert(String name) => verbindung.select(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
        [name],
      ).isNotEmpty;

  bool _spalteExistiert(String tabelle, String spalte) => verbindung
      .select('PRAGMA table_info($tabelle)')
      .any((zeile) => zeile['name'] == spalte);

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
    _erstelleErlebnisseTabelle();
    _erstelleErlebnispositionenTabellen();
    verbindung.execute('''
      CREATE TABLE kriterien (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        beschreibung TEXT,
        eingabetyp TEXT NOT NULL DEFAULT 'wertung',
        reihenfolge INTEGER NOT NULL DEFAULT 0,
        aktiv INTEGER NOT NULL DEFAULT 1,
        erstellt_am TEXT NOT NULL,
        geaendert_am TEXT NOT NULL,
        produktart TEXT NOT NULL DEFAULT 'bier',
        objektart TEXT NOT NULL DEFAULT 'getraenk',
        version INTEGER NOT NULL DEFAULT 1,
        auswahlwerte TEXT NOT NULL DEFAULT ''
      )
    ''');
    _erstelleBewertungenTabelle();
  }

  void _erstelleErlebnisseTabelle() {
    verbindung.execute('''
      CREATE TABLE erlebnisse (
        id TEXT PRIMARY KEY,
        typ TEXT NOT NULL,
        status TEXT NOT NULL,
        ort_id TEXT REFERENCES orte(id),
        geplanter_tag TEXT,
        geplante_minute INTEGER,
        geplante_dauer_minuten INTEGER,
        tatsaechlicher_beginn TEXT,
        tatsaechliches_ende TEXT,
        erstellt_am TEXT NOT NULL,
        geaendert_am TEXT NOT NULL,
        herkunft_profil_id TEXT NOT NULL REFERENCES profile(id),
        notiz TEXT,
        ist_entwurf INTEGER NOT NULL DEFAULT 0,
        produkt_id TEXT REFERENCES produkte(objekt_id),
        kaufort_id TEXT REFERENCES orte(id),
        konsumort_id TEXT REFERENCES orte(id),
        erlebt_am TEXT,
        preis REAL,
        menge REAL,
        gebinde TEXT,
        CHECK (geplante_minute IS NULL OR
          (geplante_minute >= 0 AND geplante_minute < 1440)),
        CHECK (geplante_dauer_minuten IS NULL OR
          geplante_dauer_minuten > 0)
      )
    ''');
  }

  void _erstelleBewertungenTabelle() {
    verbindung.execute('''
      CREATE TABLE bewertungen (
        id TEXT PRIMARY KEY,
        erlebnis_id TEXT NOT NULL REFERENCES erlebnisse(id) ON DELETE CASCADE,
        kriterium_id TEXT NOT NULL REFERENCES kriterien(id),
        wert REAL NOT NULL,
        erstellt_am TEXT NOT NULL,
        geaendert_am TEXT NOT NULL,
        herkunft_profil_id TEXT NOT NULL REFERENCES profile(id),
        erlebnis_position_id TEXT REFERENCES erlebnispositionen(id)
          ON DELETE CASCADE,
        ort_id TEXT REFERENCES orte(id),
        kriterium_name TEXT,
        kriterium_eingabetyp TEXT,
        kriterium_reihenfolge INTEGER,
        kriterium_version INTEGER,
        kriterium_beschreibung TEXT,
        kriterium_auswahlwerte TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  void _erstelleErlebnispositionenTabellen() {
    verbindung.execute('''
      CREATE TABLE IF NOT EXISTS erlebnispositionen (
        id TEXT PRIMARY KEY,
        erlebnis_id TEXT NOT NULL REFERENCES erlebnisse(id) ON DELETE CASCADE,
        produkt_id TEXT NOT NULL REFERENCES produkte(objekt_id),
        anzahl INTEGER NOT NULL CHECK (anzahl >= 1),
        erstellt_am TEXT NOT NULL,
        geaendert_am TEXT NOT NULL
      )
    ''');
    verbindung.execute('''
      CREATE TABLE IF NOT EXISTS preisbeobachtungen (
        id TEXT PRIMARY KEY,
        erlebnis_id TEXT NOT NULL REFERENCES erlebnisse(id) ON DELETE CASCADE,
        erlebnis_position_id TEXT NOT NULL UNIQUE
          REFERENCES erlebnispositionen(id) ON DELETE CASCADE,
        produkt_id TEXT NOT NULL REFERENCES produkte(objekt_id),
        ort_id TEXT REFERENCES orte(id),
        beobachtet_am TEXT NOT NULL,
        betrag_minor INTEGER NOT NULL CHECK (betrag_minor >= 0),
        waehrung TEXT NOT NULL,
        erstellt_am TEXT NOT NULL,
        geaendert_am TEXT NOT NULL
      )
    ''');
  }
}
