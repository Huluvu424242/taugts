import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/persistenz/aktuelles_datenbankschema.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';

void main() {
  test('migriert eine leere Datenbank von Schema 0 auf aktuellen Stand', () {
    final verbindung = sqlite3.openInMemory();

    final datenbank = LokaleDatenbank.oeffnen(verbindung);

    expect(LokaleDatenbank.schemaVersion, 2);
    expect(verbindung.userVersion, 2);
    expect(verbindung.select('PRAGMA foreign_key_check'), isEmpty);
    datenbank.schliessen();
  });

  test('Schema 2 enthält den vollständigen aktuellen Tabellenstand', () {
    final verbindung = sqlite3.openInMemory();
    final datenbank = LokaleDatenbank.oeffnen(verbindung);

    final tabellen = verbindung
        .select(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .map((zeile) => zeile['name'] as String)
        .toSet();

    expect(tabellen, containsAll(AktuellesDatenbankschema.erwarteteTabellen));
    expect(
      _spalten(verbindung, 'bewertungen'),
      containsAll(<String>{
        'wert',
        'text_wert',
        'erlebnis_position_id',
        'ortsbewertung_id',
        'kriterium_beschreibung',
        'kriterium_auswahlwerte',
      }),
    );
    expect(
      _spalten(verbindung, 'erlebnisse'),
      containsAll(<String>{
        'typ',
        'status',
        'geplanter_tag',
        'tatsaechlicher_beginn',
      }),
    );
    expect(
      _spalten(verbindung, 'kriterien'),
      containsAll(<String>{'objektart', 'version', 'auswahlwerte'}),
    );
    expect(verbindung.select('PRAGMA foreign_key_check'), isEmpty);
    datenbank.schliessen();
  });

  test('Schema 2 stellt die aktuellen Standardkriterien bereit', () {
    final verbindung = sqlite3.openInMemory();
    final datenbank = LokaleDatenbank.oeffnen(verbindung);

    final getraenke = verbindung.select(
      "SELECT * FROM kriterien WHERE id LIKE 'c0000000-%' "
      'ORDER BY reihenfolge',
    );

    expect(getraenke, hasLength(7));
    expect(getraenke.first['name'], 'Gesamturteil');
    expect(getraenke.last['name'], 'Farbintensität');
    expect(
      verbindung.select("SELECT * FROM kriterien WHERE produktart = 'speise'"),
      hasLength(6),
    );
    expect(
      verbindung.select(
        "SELECT * FROM kriterien WHERE produktart = 'sonstiges'",
      ),
      hasLength(1),
    );
    expect(
      verbindung
          .select("SELECT * FROM kriterien WHERE objektart = 'gastronomie'"),
      hasLength(7),
    );
    expect(
      verbindung
          .select("SELECT * FROM kriterien WHERE objektart = 'geschaeft'"),
      hasLength(8),
    );
    datenbank.schliessen();
  });

  test('migriert numerische Bewertungen verlustfrei von Schema 1 auf 2', () {
    final verbindung = sqlite3.openInMemory();
    LokaleDatenbank.oeffnen(verbindung);

    verbindung.execute('DROP TABLE bewertungen');
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
    const profilId = '10000000-0000-4000-8000-000000000001';
    const erlebnisId = '10000000-0000-4000-8000-000000000002';
    const bewertungId = '10000000-0000-4000-8000-000000000003';
    const zeit = '2026-09-05T18:00:00.000Z';
    verbindung.execute(
      'INSERT INTO profile VALUES (?, ?, ?, ?)',
      [profilId, 'Test', zeit, zeit],
    );
    verbindung.execute(
      '''INSERT INTO erlebnisse (
        id, typ, status, erstellt_am, geaendert_am, herkunft_profil_id,
        ist_entwurf
      ) VALUES (?, 'restaurantbesuch', 'geplant', ?, ?, ?, 0)''',
      [erlebnisId, zeit, zeit, profilId],
    );
    verbindung.execute(
      '''INSERT INTO bewertungen (
        id, erlebnis_id, kriterium_id, wert, erstellt_am, geaendert_am,
        herkunft_profil_id, kriterium_name, kriterium_eingabetyp,
        kriterium_reihenfolge, kriterium_version
      ) VALUES (?, ?, ?, 4, ?, ?, ?, 'Geschmack', 'wertung', 10, 1)''',
      [
        bewertungId,
        erlebnisId,
        'c0000000-0000-4000-8000-000000000002',
        zeit,
        zeit,
        profilId,
      ],
    );
    verbindung.userVersion = 1;

    LokaleDatenbank.oeffnen(verbindung);

    final zeile = verbindung.select(
      'SELECT wert, text_wert FROM bewertungen WHERE id = ?',
      [bewertungId],
    ).single;
    expect(verbindung.userVersion, 2);
    expect(zeile['wert'], 4.0);
    expect(zeile['text_wert'], isNull);
    expect(verbindung.select('PRAGMA foreign_key_check'), isEmpty);
    verbindung.close();
  });

  test('lehnt eine Datenbank mit höherer Schemaversion ab', () {
    final verbindung = sqlite3.openInMemory();
    verbindung.userVersion = 3;

    expect(
      () => LokaleDatenbank.oeffnen(verbindung),
      throwsA(
        isA<StateError>().having(
          (fehler) => fehler.message,
          'message',
          'Nicht unterstützte Schemaversion: 3',
        ),
      ),
    );

    verbindung.close();
  });
}

Set<String> _spalten(Database verbindung, String tabelle) => verbindung
    .select('PRAGMA table_info($tabelle)')
    .map((zeile) => zeile['name'] as String)
    .toSet();
