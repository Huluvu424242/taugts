import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _jsonDatei(String pfad) {
  final inhalt = File(pfad).readAsStringSync();
  return jsonDecode(inhalt) as Map<String, Object?>;
}

List<Map<String, Object?>> _liste(
  Map<String, Object?> dokument,
  String schluessel,
) =>
    (dokument[schluessel] as List<Object?>)
        .cast<Map<String, Object?>>();

void main() {
  const schemaPfad = 'schema/taugts-export.schema.json';
  const gueltigPfad = 'schema/fixtures/taugts-export-v1-gueltig.json';
  const ungueltigPfad = 'schema/fixtures/taugts-export-v1-ungueltig.json';

  test('Schema und Fixtures sind syntaktisch gültiges JSON', () {
    final schema = _jsonDatei(schemaPfad);
    final gueltig = _jsonDatei(gueltigPfad);
    final ungueltig = _jsonDatei(ungueltigPfad);

    expect(schema[r'$schema'], 'https://json-schema.org/draft/2020-12/schema');
    expect(schema['type'], 'object');
    expect(gueltig, isNotEmpty);
    expect(ungueltig, isNotEmpty);
  });

  test('gültiges Fixture verwendet Kennung, Version und alle Sammlungen', () {
    final dokument = _jsonDatei(gueltigPfad);

    expect(dokument['format'], 'taugts-export');
    expect(dokument['schemaVersion'], 1);
    expect(dokument['exportiertAm'], endsWith('Z'));
    expect(dokument['appVersion'], isNotEmpty);

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

  test('Fixture bewahrt mehrere historische Preise desselben Produkts', () {
    final dokument = _jsonDatei(gueltigPfad);
    final preise = _liste(dokument, 'preisbeobachtungen');

    expect(preise, hasLength(2));
    expect(preise.map((preis) => preis['produktId']).toSet(), hasLength(1));
    expect(preise.map((preis) => preis['id']).toSet(), hasLength(2));
    expect(preise.map((preis) => preis['erlebnisId']).toSet(), hasLength(2));
    expect(preise.map((preis) => preis['betragMinor']).toList(), [420, 450]);
  });

  test('Fixture bewahrt historische Bewertungen und Kriterien-Snapshots', () {
    final dokument = _jsonDatei(gueltigPfad);
    final bewertungen = _liste(dokument, 'bewertungen');

    expect(bewertungen, hasLength(2));
    expect(
      bewertungen.map((bewertung) => bewertung['objektId']).toSet(),
      hasLength(1),
    );
    expect(
      bewertungen.map((bewertung) => bewertung['erlebnisId']).toSet(),
      hasLength(2),
    );
    expect(bewertungen.map((bewertung) => bewertung['id']).toSet(), hasLength(2));

    for (final bewertung in bewertungen) {
      final kriterium = bewertung['kriterium'] as Map<String, Object?>;
      expect(kriterium['id'], isNotNull);
      expect(kriterium['name'], isNotEmpty);
      expect(kriterium['version'], 1);
      expect(kriterium['auswahlwerte'], isA<List<Object?>>());
      expect(bewertung['wert'], isA<String>());
      expect(bewertung['bewertetAm'], endsWith('Z'));
    }
  });

  test('ungültiges Fixture verletzt bewusst grundlegende Formatregeln', () {
    final dokument = _jsonDatei(ungueltigPfad);

    expect(dokument['format'], isNot('taugts-export'));
    expect(dokument['schemaVersion'], isNot(1));
    expect(dokument['appVersion'], isEmpty);
    expect(dokument['exportiertAm'], isNot(endsWith('Z')));

    final preis = _liste(dokument, 'preisbeobachtungen').single;
    expect(preis['betragMinor'], lessThan(0));
    expect(preis['waehrung'], isNot(matches(RegExp(r'^[A-Z]{3}$'))));
  });
}
