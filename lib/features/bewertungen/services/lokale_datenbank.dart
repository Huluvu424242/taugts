import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/persistenz/aktuelles_datenbankschema.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';

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
      var aktuelleVersion = version;
      while (aktuelleVersion < schemaVersion) {
        switch (aktuelleVersion) {
          case 0:
            _migriereVon0Auf1();
            aktuelleVersion = 1;
          case 1:
            _migriereVon1Auf2();
            aktuelleVersion = 2;
          default:
            throw StateError(
              'Kein Migrationspfad von Schemaversion $aktuelleVersion '
              'auf $schemaVersion vorhanden.',
            );
        }
      }

      _stelleStandardkriterienBereit();
      verbindung.userVersion = aktuelleVersion;
    });
  }

  void _migriereVon0Auf1() {
    _erstelleSchemaVersion1();
  }

  void _migriereVon1Auf2() {
    verbindung.execute('ALTER TABLE bewertungen RENAME TO bewertungen_v1');
    _erstelleBewertungenTabelleVersion2();
    verbindung.execute('''
      INSERT INTO bewertungen (
        id, erlebnis_id, kriterium_id, wert, text_wert, erstellt_am,
        geaendert_am, herkunft_profil_id, erlebnis_position_id, ort_id,
        kriterium_name, kriterium_eingabetyp, kriterium_reihenfolge,
        kriterium_version, kriterium_beschreibung, kriterium_auswahlwerte,
        ortsbewertung_id
      )
      SELECT
        id, erlebnis_id, kriterium_id, wert, NULL, erstellt_am,
        geaendert_am, herkunft_profil_id, erlebnis_position_id, ort_id,
        kriterium_name, kriterium_eingabetyp, kriterium_reihenfolge,
        kriterium_version, kriterium_beschreibung, kriterium_auswahlwerte,
        ortsbewertung_id
      FROM bewertungen_v1
    ''');
    verbindung.execute('DROP TABLE bewertungen_v1');
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

  bool _tabelleExistiert(String name) => verbindung.select(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
        [name],
      ).isNotEmpty;

  void _erstelleSchemaVersion1() {
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
    _erstelleOrtsbewertungenTabelle();
    _erstelleBewertungenTabelleVersion1();
    AktuellesDatenbankschema.stelleFeatureTabellenBereit(verbindung);
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

  void _erstelleBewertungenTabelleVersion1() {
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
        kriterium_auswahlwerte TEXT NOT NULL DEFAULT '',
        ortsbewertung_id TEXT REFERENCES ortsbewertungen(id)
          ON DELETE CASCADE
      )
    ''');
  }

  void _erstelleBewertungenTabelleVersion2() {
    verbindung.execute('''
      CREATE TABLE bewertungen (
        id TEXT PRIMARY KEY,
        erlebnis_id TEXT NOT NULL REFERENCES erlebnisse(id) ON DELETE CASCADE,
        kriterium_id TEXT NOT NULL REFERENCES kriterien(id),
        wert REAL,
        text_wert TEXT,
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
        kriterium_auswahlwerte TEXT NOT NULL DEFAULT '',
        ortsbewertung_id TEXT REFERENCES ortsbewertungen(id)
          ON DELETE CASCADE,
        CHECK (
          (wert IS NOT NULL AND text_wert IS NULL) OR
          (wert IS NULL AND text_wert IS NOT NULL AND LENGTH(TRIM(text_wert)) > 0)
        )
      )
    ''');
  }

  void _erstelleOrtsbewertungenTabelle() {
    verbindung.execute('''
      CREATE TABLE IF NOT EXISTS ortsbewertungen (
        id TEXT PRIMARY KEY,
        erlebnis_id TEXT NOT NULL UNIQUE
          REFERENCES erlebnisse(id) ON DELETE CASCADE,
        ort_id TEXT NOT NULL REFERENCES orte(id),
        herkunft_profil_id TEXT NOT NULL REFERENCES profile(id),
        bewertet_am TEXT NOT NULL,
        notiz TEXT,
        erstellt_am TEXT NOT NULL,
        geaendert_am TEXT NOT NULL
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
