import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/datenaustausch/services/export_service.dart';
import 'package:taugts/features/datenaustausch/services/import_ausfuehrung_service.dart';
import 'package:taugts/features/datenaustausch/services/import_strategie_service.dart';
import 'package:taugts/features/datenaustausch/services/import_validierungs_service.dart';

void main() {
  late LokaleDatenbank datenbank;

  setUp(() {
    datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
  });

  tearDown(() => datenbank.schliessen());

  test('formales JSON-Schema stimmt mit Export und Importversion überein', () {
    final schema = jsonDecode(
      File('schema/taugts-export.schema.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final eigenschaften = schema['properties'] as Map<String, dynamic>;
    final versionsFeld = eigenschaften['schemaVersion'] as Map<String, dynamic>;
    final export = jsonDecode(
      ExportService(datenbank, appVersion: '0.1.0+8').erzeugeJson(),
    ) as Map<String, dynamic>;

    expect(
      versionsFeld['const'],
      ImportValidierungsService.aktuelleSchemaVersion,
    );
    expect(export['schemaVersion'], versionsFeld['const']);
    expect(schema['description'], contains('Version 3'));

    final definitionen = schema[r'$defs'] as Map<String, dynamic>;
    final erlebnis = definitionen['erlebnis'] as Map<String, dynamic>;
    final felder = erlebnis['properties'] as Map<String, dynamic>;
    expect(felder, containsPair('beginn', isA<Map<String, dynamic>>()));
    expect(felder, containsPair('ende', isA<Map<String, dynamic>>()));
    for (final altesFeld in [
      'status',
      'istEntwurf',
      'geplanterTag',
      'geplanteMinute',
      'geplanteDauerMinuten',
      'tatsaechlicherBeginn',
      'tatsaechlichesEnde',
    ]) {
      expect(felder.containsKey(altesFeld), isFalse);
    }

    final importErgebnis = const ImportValidierungsService().validiere(
      jsonEncode(export),
    );
    expect(importErgebnis.istGueltig, isTrue);
  });

  test('erzeugt vollständigen versionierten Export auch ohne Fachdaten', () {
    final service = ExportService(
      datenbank,
      appVersion: '0.1.0+4',
      jetzt: () => DateTime.utc(2026, 9, 2, 18, 30),
    );

    final dokument = jsonDecode(service.erzeugeJson()) as Map<String, Object?>;

    expect(dokument['format'], 'taugts-export');
    expect(dokument['schemaVersion'], 3);
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

  test('Kategorie- und Klassifikationsdaten bestehen einen vollständigen Roundtrip', () {
    const produkt = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    const kategorie = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
    datenbank.verbindung.execute(
      'INSERT INTO objekte (id, name, art, erstellt_am, geaendert_am) '
      'VALUES (?, ?, ?, ?, ?)',
      [produkt, 'Testbier', 'produkt',
        '2026-09-01T00:00:00.000Z', '2026-09-01T00:00:00.000Z'],
    );
    datenbank.verbindung.execute(
      'INSERT INTO produkte (objekt_id) VALUES (?)', [produkt],
    );
    datenbank.verbindung.execute(
      'INSERT INTO kategorien (id, name, bereich, ist_standard) '
      'VALUES (?, ?, ?, ?)',
      [kategorie, 'Getränk', 'produkt', 0],
    );
    datenbank.verbindung.execute(
      'INSERT INTO produkt_kategorien (produkt_id, kategorie_id) '
      'VALUES (?, ?)', [produkt, kategorie],
    );
    datenbank.verbindung.execute(
      'INSERT INTO objekt_tags (objekt_id, normalisiert, text) '
      'VALUES (?, ?, ?)', [produkt, 'regional', 'Regional'],
    );
    datenbank.verbindung.execute(
      'INSERT INTO objekt_klassifikationsmerkmale '
      '(objekt_id, dimension, schluessel, wert) VALUES (?, ?, ?, ?)',
      [produkt, 'hersteller', '', 'Brauerei'],
    );
    datenbank.verbindung.execute(
      'INSERT INTO kategorie_kriterienset_regeln '
      '(kategorie_id, fallback_objektart, modus, version) '
      'VALUES (?, ?, ?, ?)',
      [kategorie, 'getraenk', 'erweitern', 1],
    );

    final text = ExportService(
      datenbank, appVersion: '0.1.0-test',
      jetzt: () => DateTime.utc(2026, 10, 10),
    ).erzeugeJson();
    final validierung = const ImportValidierungsService().validiere(text);
    expect(validierung.istGueltig, isTrue, reason: validierung.fehler.toString());

    final neu = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(neu.schliessen);
    const ImportAusfuehrungService().ausfuehren(
      datenbank: neu,
      importDokument: validierung.dokument!,
      strategie: ImportStrategie.bestandErsetzen,
    );
    final danach = jsonDecode(
      ExportService(neu, appVersion: '0.1.0-test').erzeugeJson(),
    ) as Map<String, Object?>;
    for (final name in const [
      'kategorien',
      'kategorieZuordnungen',
      'objektTags',
      'objektKlassifikationsmerkmale',
      'kategorieKriteriensetRegeln',
      'kategorieKriterien',
    ]) {
      expect(
        danach[name],
        (jsonDecode(text) as Map<String, Object?>)[name],
        reason: name,
      );
    }
  });

  test('allgemeine Objekte ohne Produktdatensatz bleiben erhalten', () {
    const id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaab';
    datenbank.verbindung.execute(
      'INSERT INTO objekte (id, name, art, erstellt_am, geaendert_am) '
      'VALUES (?, ?, ?, ?, ?)',
      [id, 'Allgemeines Objekt', 'allgemein',
        '2026-09-01T00:00:00.000Z', '2026-09-01T00:00:00.000Z'],
    );
    final dokument = const ImportValidierungsService().validiere(
      ExportService(datenbank, appVersion: '0.1.0-test').erzeugeJson(),
    );
    expect(dokument.istGueltig, isTrue, reason: dokument.fehler.toString());
    final ziel = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(ziel.schliessen);
    const ImportAusfuehrungService().ausfuehren(
      datenbank: ziel,
      importDokument: dokument.dokument!,
      strategie: ImportStrategie.bestandErsetzen,
    );
    expect(
      ziel.verbindung
          .select('SELECT art FROM objekte WHERE id = ?', [id])
          .single['art'],
      'allgemein',
    );
    expect(ziel.verbindung.select('SELECT * FROM produkte'), isEmpty);
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
