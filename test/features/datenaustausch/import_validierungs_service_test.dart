import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/datenaustausch/services/import_validierungs_service.dart';

String _fixture(String name) =>
    File('schema/fixtures/$name').readAsStringSync();

Map<String, Object?> _dokument(String name) =>
    jsonDecode(_fixture(name)) as Map<String, Object?>;

void main() {
  const service = ImportValidierungsService();

  test('gültiges V1-Fixture wird auf V2 migriert und vollständig akzeptiert',
      () {
    final ergebnis = service.validiere(
      _fixture('taugts-export-v1-gueltig.json'),
    );

    expect(ergebnis.istGueltig, isTrue);
    expect(ergebnis.wurdeMigriert, isTrue);
    expect(ergebnis.urspruenglicheSchemaVersion, 1);
    expect(ergebnis.schemaVersion, 2);
    expect(ergebnis.fehler, isEmpty);
  });

  test(
      'eigenständige historische Datensätze werden nicht als Duplikat abgewiesen',
      () {
    final dokument = _dokument('taugts-export-v1-gueltig.json');
    final preise = dokument['preisbeobachtungen'] as List<Object?>;
    final bewertungen = dokument['bewertungen'] as List<Object?>;

    expect(preise, hasLength(2));
    expect(bewertungen, hasLength(2));
    expect(service.validiere(jsonEncode(dokument)).istGueltig, isTrue);
  });

  test('Vorabversion 0 wird vorwärts auf V2 migriert', () {
    final ergebnis = service.validiere(
      _fixture('taugts-export-v0-migrierbar.json'),
    );

    expect(ergebnis.istGueltig, isTrue);
    expect(ergebnis.wurdeMigriert, isTrue);
    expect(ergebnis.urspruenglicheSchemaVersion, 0);
    expect(ergebnis.schemaVersion, 2);
    expect(ergebnis.dokument!['kategorien'], isEmpty);
    expect(ergebnis.dokument!['kategorieZuordnungen'], isEmpty);
  });

  test('nicht unterstützte neuere Version wird abgewiesen', () {
    final dokument = _dokument('taugts-export-v1-gueltig.json');
    dokument['schemaVersion'] = 3;

    final ergebnis = service.validiere(jsonEncode(dokument));

    expect(ergebnis.istGueltig, isFalse);
    expect(
      ergebnis.fehler.map((fehler) => fehler.code),
      contains('schema_version_zu_neu'),
    );
    expect(ergebnis.dokument, isNull);
  });

  test('beschädigtes JSON erzeugt einen verständlichen Syntaxfehler', () {
    final ergebnis = service.validiere('{"format":');

    expect(ergebnis.istGueltig, isFalse);
    expect(ergebnis.fehler.single.code, 'ungueltiges_json');
    expect(ergebnis.fehler.single.nachricht, contains('gültiges JSON'));
  });

  test('verwaiste Erlebnisposition wird referenziell abgewiesen', () {
    final ergebnis = service.validiere(
      _fixture('taugts-export-v1-verwaist.json'),
    );

    expect(ergebnis.istGueltig, isFalse);
    expect(
      ergebnis.fehler.where((fehler) => fehler.code == 'referenz_ungueltig'),
      hasLength(2),
    );
  });

  test('ungültige Erlebnisstatus- und Zeitkombinationen werden erkannt', () {
    final ergebnis = service.validiere(
      _fixture('taugts-export-v1-fachlich-ungueltig.json'),
    );
    final codes = ergebnis.fehler.map((fehler) => fehler.code).toSet();

    expect(ergebnis.istGueltig, isFalse);
    expect(codes, contains('zeitkombination_ungueltig'));
    expect(codes, contains('status_ungueltig'));
  });

  test('Preis und Währung werden fachlich typisiert validiert', () {
    final dokument = _dokument('taugts-export-v1-gueltig.json');
    final preise = dokument['preisbeobachtungen'] as List<Object?>;
    final preis = preise.first as Map<String, Object?>;
    preis['betragMinor'] = '420';
    preis['waehrung'] = '€';

    final ergebnis = service.validiere(jsonEncode(dokument));
    final codes = ergebnis.fehler.map((fehler) => fehler.code).toSet();

    expect(ergebnis.istGueltig, isFalse);
    expect(codes, contains('ganzzahl_ungueltig'));
    expect(codes, contains('waehrung_ungueltig'));
  });

  test('historische Kriterienversion darf aktive Version nicht überholen', () {
    final dokument = _dokument('taugts-export-v1-gueltig.json');
    final bewertungen = dokument['bewertungen'] as List<Object?>;
    final bewertung = bewertungen.first as Map<String, Object?>;
    final kriterium = bewertung['kriterium'] as Map<String, Object?>;
    kriterium['version'] = 2;

    final ergebnis = service.validiere(jsonEncode(dokument));

    expect(ergebnis.istGueltig, isFalse);
    expect(
      ergebnis.fehler.map((fehler) => fehler.code),
      contains('kriterium_version_ungueltig'),
    );
  });

  test('unbekannte optionale Felder bleiben vorwärtskompatibel', () {
    final dokument = _dokument('taugts-export-v1-gueltig.json');
    dokument['zukuenftigerHinweis'] = {'wert': true};
    final objekte = dokument['objekte'] as List<Object?>;
    final objekt = objekte.first as Map<String, Object?>;
    objekt['zukuenftigesFeld'] = 'wird ignoriert';

    expect(service.validiere(jsonEncode(dokument)).istGueltig, isTrue);
  });

  test('V2 akzeptiert einen textuellen Auswahlwert', () {
    final dokument = _dokument('taugts-export-v1-gueltig.json');
    dokument['schemaVersion'] = 2;
    final kriterien = dokument['bewertungskriterien'] as List<Object?>;
    final kriterium = kriterien.first as Map<String, Object?>;
    kriterium['eingabetyp'] = 'auswahl';
    kriterium['auswahlwerte'] = ['Direkt', 'Langsam'];
    final bewertungen = dokument['bewertungen'] as List<Object?>;
    for (final roh in bewertungen) {
      final bewertung = roh as Map<String, Object?>;
      final snapshot = bewertung['kriterium'] as Map<String, Object?>;
      snapshot['eingabetyp'] = 'auswahl';
      snapshot['auswahlwerte'] = ['Direkt', 'Langsam'];
      bewertung['wert'] = null;
      bewertung['textWert'] = 'Direkt';
    }

    final ergebnis = service.validiere(jsonEncode(dokument));

    expect(ergebnis.istGueltig, isTrue);
    expect(ergebnis.schemaVersion, 2);
  });

  test('Dateigröße wird vor dem JSON-Parsing begrenzt', () {
    const klein = ImportValidierungsService(
      grenzen: ImportValidierungsGrenzen(maxBytes: 8),
    );

    final ergebnis = klein.validiere('{"wert":"zu lang"}');

    expect(ergebnis.istGueltig, isFalse);
    expect(ergebnis.fehler.single.code, 'datei_zu_gross');
  });

  test('zu tiefe Verschachtelung wird begrenzt', () {
    const flach = ImportValidierungsService(
      grenzen: ImportValidierungsGrenzen(maxTiefe: 2),
    );

    final ergebnis = flach.validiere(
      jsonEncode({
        'a': {
          'b': {'c': 1},
        },
      }),
    );

    expect(ergebnis.istGueltig, isFalse);
    expect(ergebnis.fehler.single.code, 'zu_tief_verschachtelt');
  });
}
