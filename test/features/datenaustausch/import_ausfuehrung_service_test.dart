import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/datenaustausch/services/import_ausfuehrung_service.dart';
import 'package:taugts/features/datenaustausch/services/import_strategie_service.dart';

void main() {
  late LokaleDatenbank datenbank;
  const service = ImportAusfuehrungService();

  setUp(() => datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory()));
  tearDown(() => datenbank.schliessen());

  Map<String, Object?> dokument(List<Map<String, Object?>> profile) => {
        'profile': profile,
        'objekte': <Object?>[],
        'orte': <Object?>[],
        'bewertungskriterien': <Object?>[],
        'erlebnisse': <Object?>[],
        'erlebnisPositionen': <Object?>[],
        'preisbeobachtungen': <Object?>[],
        'ortsbewertungen': <Object?>[],
        'bewertungen': <Object?>[],
      };

  test('importiert atomar und ein wiederholter Import erzeugt keine Dubletten', () {
    final import = dokument([
      {
        'id': '10000000-0000-4000-8000-000000000001',
        'anzeigename': 'Importprofil',
        'erstelltAm': '2026-09-01T10:00:00.000Z',
        'geaendertAm': '2026-09-01T10:00:00.000Z',
      },
    ]);

    final erstes = service.ausfuehren(
      datenbank: datenbank,
      importDokument: import,
      strategie: ImportStrategie.importBevorzugen,
    );
    final zweites = service.ausfuehren(
      datenbank: datenbank,
      importDokument: import,
      strategie: ImportStrategie.importBevorzugen,
    );

    expect(erstes.nachSammlung['profile']!.hinzugefuegt, 1);
    expect(zweites.nachSammlung['profile']!.aktualisiert, 1);
    expect(
      datenbank.verbindung.select(
        "SELECT COUNT(*) AS n FROM profile WHERE id = '10000000-0000-4000-8000-000000000001'",
      ).single['n'],
      1,
    );
  });

  test('rollt den gesamten Import bei einem Fehler zurück', () {
    final vorher = datenbank.verbindung
        .select('SELECT COUNT(*) AS n FROM profile').single['n'];
    final import = dokument([
      {
        'id': '10000000-0000-4000-8000-000000000001',
        'anzeigename': 'Wird zurückgerollt',
        'erstelltAm': '2026-09-01T10:00:00.000Z',
        'geaendertAm': '2026-09-01T10:00:00.000Z',
      },
    ]);
    import['orte'] = [
      {
        'id': '20000000-0000-4000-8000-000000000001',
        'name': null,
        'typ': 'gastronomie',
        'erstelltAm': '2026-09-01T10:00:00.000Z',
        'geaendertAm': '2026-09-01T10:00:00.000Z',
      },
    ];

    expect(
      () => service.ausfuehren(
        datenbank: datenbank,
        importDokument: import,
        strategie: ImportStrategie.importBevorzugen,
      ),
      throwsA(anything),
    );
    expect(
      datenbank.verbindung.select('SELECT COUNT(*) AS n FROM profile').single['n'],
      vorher,
    );
  });

  test('Bestand ersetzen entfernt nicht importierte Fachdaten innerhalb der Transaktion', () {
    datenbank.verbindung.execute(
      'INSERT INTO orte (id, name, typ, erstellt_am, geaendert_am) VALUES (?, ?, ?, ?, ?)',
      ['alt', 'Alter Ort', 'gastronomie', '2026-09-01', '2026-09-01'],
    );

    service.ausfuehren(
      datenbank: datenbank,
      importDokument: dokument(const []),
      strategie: ImportStrategie.bestandErsetzen,
    );

    expect(datenbank.verbindung.select('SELECT * FROM orte'), isEmpty);
  });
}
