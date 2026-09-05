import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/datenaustausch/services/export_service.dart';

void main() {
  late LokaleDatenbank datenbank;

  setUp(() {
    datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
  });

  tearDown(() => datenbank.schliessen());

  test('erzeugt vollständigen versionierten Export auch ohne Fachdaten', () {
    final service = ExportService(
      datenbank,
      appVersion: '0.1.0+4',
      jetzt: () => DateTime.utc(2026, 9, 2, 18, 30),
    );

    final dokument = jsonDecode(service.erzeugeJson()) as Map<String, Object?>;

    expect(dokument['format'], 'taugts-export');
    expect(dokument['schemaVersion'], 2);
    expect(dokument['exportiertAm'], '2026-09-02T18:30:00.000Z');
    expect(dokument['appVersion'], '0.1.0+4');
    for (final schluessel in const [
      'profile',
      'objekte',
      'orte',
      'erlebnisse',
      'erlebnisPositionen',
      'preisbeobachtungen',
      'bewertungskriterien',
      'bewertungen',
      'ortsbewertungen',
      'kategorien',
      'kategorieZuordnungen',
    ]) {
      expect(dokument[schluessel], isA<List<Object?>>(), reason: schluessel);
    }
  });

  test('exportiert lokale Profile ohne den Datenbestand zu verändern', () {
    datenbank.verbindung.execute(
      'INSERT INTO profile VALUES (?, ?, ?, ?)',
      [
        '10000000-0000-4000-8000-000000000001',
        'Anna',
        '2026-09-01T10:00:00.000Z',
        '2026-09-01T10:00:00.000Z',
      ],
    );
    final vorher = datenbank.verbindung
        .select('SELECT COUNT(*) AS n FROM profile')
        .single['n'];

    final dokument = jsonDecode(
      ExportService(datenbank, appVersion: '0.1.0+4').erzeugeJson(),
    ) as Map<String, Object?>;
    final profile = dokument['profile'] as List<Object?>;

    expect(profile, hasLength(1));
    expect((profile.single as Map<String, Object?>)['anzeigename'], 'Anna');
    final nachher = datenbank.verbindung
        .select('SELECT COUNT(*) AS n FROM profile')
        .single['n'];
    expect(nachher, vorher);
  });
}
