import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/persistenz/aktuelles_datenbankschema.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';

void main() {
  test('migriert eine leere Datenbank von Schema 0 auf Baseline 1', () {
    final verbindung = sqlite3.openInMemory();

    final datenbank = LokaleDatenbank.oeffnen(verbindung);

    expect(LokaleDatenbank.schemaVersion, 1);
    expect(verbindung.userVersion, 1);
    expect(verbindung.select('PRAGMA foreign_key_check'), isEmpty);
    datenbank.schliessen();
  });

  test('Baseline 1 enthält den vollständigen aktuellen Tabellenstand', () {
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

  test('Baseline 1 stellt die aktuellen Standardkriterien bereit', () {
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

  test('lehnt eine Datenbank mit höherer Schemaversion ab', () {
    final verbindung = sqlite3.openInMemory();
    verbindung.userVersion = 2;

    expect(
      () => LokaleDatenbank.oeffnen(verbindung),
      throwsA(
        isA<StateError>().having(
          (fehler) => fehler.message,
          'message',
          'Nicht unterstützte Schemaversion: 2',
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
