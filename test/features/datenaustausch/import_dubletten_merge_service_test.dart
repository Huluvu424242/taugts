import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/datenaustausch/services/import_dubletten_merge_service.dart';

void main() {
  const service = ImportDublettenMergeService();

  test('Produktmerge übernimmt gewählte Stammdaten und hängt gesamte Historie um', () {
    final lokal = <String, Object?>{
      'objekte': [
        {'id': 'lokal-p', 'name': 'Pils lokal', 'barcode': '4001', 'produktart': 'bier'},
      ],
    };
    final import = <String, Object?>{
      'objekte': [
        {'id': 'import-p', 'name': 'Pils Import', 'barcode': '4001', 'produktart': 'bier'},
      ],
      'erlebnisPositionen': [
        {'id': 'pos-1', 'erlebnisId': 'e-1', 'produktId': 'import-p', 'anzahl': 2},
      ],
      'preisbeobachtungen': [
        {'id': 'preis-1', 'erlebnisId': 'e-1', 'erlebnisPositionId': 'pos-1', 'produktId': 'import-p', 'ortId': 'o-1', 'betragMinor': 450, 'beobachtetAm': '2026-09-01T18:00:00Z'},
        {'id': 'preis-2', 'erlebnisId': 'e-2', 'erlebnisPositionId': 'pos-2', 'produktId': 'anderes-p', 'ortId': 'o-1', 'betragMinor': 399, 'beobachtetAm': '2026-08-01T18:00:00Z'},
      ],
      'bewertungen': [
        {'id': 'b-1', 'objektId': 'import-p', 'erlebnisId': 'e-1', 'erlebnisPositionId': 'pos-1', 'ortId': 'o-1', 'bewertetAm': '2026-09-01T18:30:00Z', 'wert': '4'},
      ],
      'kategorieZuordnungen': [
        {'kategorieId': 'k-1', 'zielId': 'import-p'},
      ],
    };

    final ergebnis = service.plane(
      sammlung: 'objekte',
      importId: 'import-p',
      lokaleId: 'lokal-p',
      importDokument: import,
      lokalesDokument: lokal,
      feldauswahl: const {'name': DublettenFeldQuelle.import},
    );

    final produkt = (ergebnis.dokument['objekte'] as List).single as Map;
    expect(produkt['id'], 'lokal-p');
    expect(produkt['name'], 'Pils Import');
    expect(produkt['barcode'], '4001');
    expect(((ergebnis.dokument['erlebnisPositionen'] as List).single as Map)['produktId'], 'lokal-p');
    expect(((ergebnis.dokument['preisbeobachtungen'] as List).first as Map)['produktId'], 'lokal-p');
    expect(((ergebnis.dokument['bewertungen'] as List).single as Map)['objektId'], 'lokal-p');
    expect(((ergebnis.dokument['kategorieZuordnungen'] as List).single as Map)['zielId'], 'lokal-p');
    expect(((ergebnis.dokument['preisbeobachtungen'] as List)[1] as Map)['produktId'], 'anderes-p');
    expect(ergebnis.alias.aliasId, 'import-p');
    expect(ergebnis.alias.kanonischeId, 'lokal-p');
  });

  test('Ortsmerge erhält Bewertungen, Preise und Zeitkontext und hängt nur Ortsreferenzen um', () {
    final lokal = <String, Object?>{
      'orte': [
        {'id': 'lokal-o', 'name': 'Zum Test', 'typ': 'gastronomie', 'adresse': 'Hauptstr. 1'},
      ],
    };
    final import = <String, Object?>{
      'orte': [
        {'id': 'import-o', 'name': 'Zum Test', 'typ': 'gastronomie', 'adresse': 'Hauptstraße 1'},
      ],
      'erlebnisse': [
        {'id': 'e-1', 'ortId': 'import-o', 'tatsaechlicherBeginn': '2026-08-10T18:00:00Z'},
      ],
      'preisbeobachtungen': [
        {'id': 'p-1', 'produktId': 'prod-1', 'ortId': 'import-o', 'beobachtetAm': '2026-08-10T18:05:00Z', 'betragMinor': 420},
      ],
      'bewertungen': [
        {'id': 'b-1', 'objektId': 'prod-1', 'erlebnisId': 'e-1', 'ortId': 'import-o', 'bewertetAm': '2026-08-10T18:30:00Z', 'wert': '3.5'},
      ],
      'ortsbewertungen': [
        {'id': 'ob-1', 'erlebnisId': 'e-1', 'ortId': 'import-o', 'bewertetAm': '2026-08-10T19:00:00Z'},
      ],
    };

    final ergebnis = service.plane(
      sammlung: 'orte',
      importId: 'import-o',
      lokaleId: 'lokal-o',
      importDokument: import,
      lokalesDokument: lokal,
      feldauswahl: const {'adresse': DublettenFeldQuelle.import},
    );

    expect(((ergebnis.dokument['erlebnisse'] as List).single as Map)['ortId'], 'lokal-o');
    expect(((ergebnis.dokument['preisbeobachtungen'] as List).single as Map)['ortId'], 'lokal-o');
    expect(((ergebnis.dokument['bewertungen'] as List).single as Map)['ortId'], 'lokal-o');
    expect(((ergebnis.dokument['ortsbewertungen'] as List).single as Map)['ortId'], 'lokal-o');
    expect(((ergebnis.dokument['preisbeobachtungen'] as List).single as Map)['beobachtetAm'], '2026-08-10T18:05:00Z');
    expect(((ergebnis.dokument['bewertungen'] as List).single as Map)['bewertetAm'], '2026-08-10T18:30:00Z');
  });

  test('Eingabedokument wird bei der Merge-Planung nicht verändert', () {
    final lokal = <String, Object?>{'objekte': [{'id': 'lokal', 'name': 'Lokal'}]};
    final import = <String, Object?>{
      'objekte': [{'id': 'import', 'name': 'Import'}],
      'bewertungen': [{'id': 'b', 'objektId': 'import'}],
    };

    service.plane(
      sammlung: 'objekte',
      importId: 'import',
      lokaleId: 'lokal',
      importDokument: import,
      lokalesDokument: lokal,
      feldauswahl: const {},
    );

    expect(((import['objekte'] as List).single as Map)['id'], 'import');
    expect(((import['bewertungen'] as List).single as Map)['objektId'], 'import');
  });
}
