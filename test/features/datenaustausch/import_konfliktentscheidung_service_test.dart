import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/datenaustausch/services/import_konfliktanalyse_service.dart';
import 'package:taugts/features/datenaustausch/services/import_konfliktentscheidung_service.dart';

void main() {
  const service = ImportKonfliktentscheidungService();

  test(
      'Versionskonflikt zeigt Feldunterschiede und erlaubt keine Dublettenaktionen',
      () {
    final konflikte = service.ermittle(
      importDokument: {
        'objekte': [
          {'id': 'p1', 'name': 'Importname', 'barcode': '123'},
        ],
      },
      lokalesDokument: {
        'objekte': [
          {'id': 'p1', 'name': 'Lokaler Name', 'barcode': '123'},
        ],
      },
      analyse: const ImportKonfliktAnalyse(
        sammlungen: [],
        fachlicheDubletten: [],
        eigeneHerkunft: 0,
        fremdeHerkunft: 0,
      ),
    );

    expect(konflikte, hasLength(1));
    final konflikt = konflikte.single;
    expect(konflikt.art, ImportKonfliktArt.versionskonflikt);
    expect(konflikt.unterschiede.single.feld, 'name');
    expect(konflikt.erlaubteAktionen,
        isNot(contains(ImportKonfliktAktion.beideBehalten)));
    expect(konflikt.erlaubteAktionen,
        isNot(contains(ImportKonfliktAktion.zusammenfuehren)));
  });

  test(
      'Historischer Identitätskonflikt zeigt Objekt Erlebnis Ort und Zeitpunkt',
      () {
    final konflikte = service.ermittle(
      importDokument: {
        'bewertungen': [
          {
            'id': 'b1',
            'objektId': 'produkt-a',
            'erlebnisId': 'erlebnis-a',
            'ortId': 'ort-a',
            'bewertetAm': '2026-09-02T18:00:00Z',
            'wert': '4',
          },
        ],
      },
      lokalesDokument: {
        'bewertungen': [
          {
            'id': 'b1',
            'objektId': 'produkt-b',
            'erlebnisId': 'erlebnis-b',
            'ortId': 'ort-b',
            'bewertetAm': '2026-09-01T18:00:00Z',
            'wert': '3',
          },
        ],
      },
      analyse: const ImportKonfliktAnalyse(
        sammlungen: [],
        fachlicheDubletten: [],
        eigeneHerkunft: 0,
        fremdeHerkunft: 0,
      ),
    );

    final konflikt = konflikte.single;
    expect(konflikt.art, ImportKonfliktArt.identitaetskonflikt);
    expect(konflikt.kontext.objektId, 'produkt-a');
    expect(konflikt.kontext.erlebnisId, 'erlebnis-a');
    expect(konflikt.kontext.ortId, 'ort-a');
    expect(konflikt.kontext.zeitpunkt, '2026-09-02T18:00:00Z');
    expect(konflikt.erlaubteAktionen,
        isNot(contains(ImportKonfliktAktion.beideBehalten)));
  });

  test('Fachliche Dublette darf beide behalten oder zusammenführen', () {
    final konflikte = service.ermittle(
      importDokument: {
        'objekte': [
          {'id': 'import', 'name': 'Pils', 'barcode': '123'},
        ],
      },
      lokalesDokument: {
        'objekte': [
          {'id': 'lokal', 'name': 'Pils', 'barcode': '123'},
        ],
      },
      analyse: const ImportKonfliktAnalyse(
        sammlungen: [],
        fachlicheDubletten: [
          FachlicheDublette(
            sammlung: 'objekte',
            importId: 'import',
            lokaleId: 'lokal',
            begruendung: 'Gleicher Barcode',
          ),
        ],
        eigeneHerkunft: 0,
        fremdeHerkunft: 0,
      ),
    );

    final konflikt = konflikte.single;
    expect(konflikt.art, ImportKonfliktArt.fachlicheDublette);
    expect(konflikt.erlaubteAktionen,
        contains(ImportKonfliktAktion.beideBehalten));
    expect(konflikt.erlaubteAktionen,
        contains(ImportKonfliktAktion.zusammenfuehren));
  });

  test('Entscheidung kann auf weitere Konflikte desselben Typs angewendet werden',
      () {
    const erster = ImportEinzelKonflikt(
      schluessel: 'objekte|1|1',
      art: ImportKonfliktArt.versionskonflikt,
      sammlung: 'objekte',
      importId: '1',
      lokaleId: '1',
      unterschiede: [],
      kontext: ImportKonfliktKontext(),
      erlaubteAktionen: {
        ImportKonfliktAktion.lokaleVersion,
        ImportKonfliktAktion.importVersion,
        ImportKonfliktAktion.ueberspringen,
      },
    );
    const zweiter = ImportEinzelKonflikt(
      schluessel: 'objekte|2|2',
      art: ImportKonfliktArt.versionskonflikt,
      sammlung: 'objekte',
      importId: '2',
      lokaleId: '2',
      unterschiede: [],
      kontext: ImportKonfliktKontext(),
      erlaubteAktionen: {
        ImportKonfliktAktion.lokaleVersion,
        ImportKonfliktAktion.importVersion,
        ImportKonfliktAktion.ueberspringen,
      },
    );
    const andererTyp = ImportEinzelKonflikt(
      schluessel: 'orte|3|3',
      art: ImportKonfliktArt.versionskonflikt,
      sammlung: 'orte',
      importId: '3',
      lokaleId: '3',
      unterschiede: [],
      kontext: ImportKonfliktKontext(),
      erlaubteAktionen: {
        ImportKonfliktAktion.lokaleVersion,
        ImportKonfliktAktion.importVersion,
        ImportKonfliktAktion.ueberspringen,
      },
    );

    final stand = service.entscheide(
      stand: const ImportKonfliktEntscheidungsStand(),
      konflikt: erster,
      aktion: ImportKonfliktAktion.importVersion,
      alleKonflikte: const [erster, zweiter, andererTyp],
      aufGleichenTypAnwenden: true,
    );

    expect(stand.fuer(erster), ImportKonfliktAktion.importVersion);
    expect(stand.fuer(zweiter), ImportKonfliktAktion.importVersion);
    expect(stand.fuer(andererTyp), isNull);
  });

  test('Unzulässige Aktion wird fachlich abgewiesen', () {
    const konflikt = ImportEinzelKonflikt(
      schluessel: 'bewertungen|1|1',
      art: ImportKonfliktArt.identitaetskonflikt,
      sammlung: 'bewertungen',
      importId: '1',
      lokaleId: '1',
      unterschiede: [],
      kontext: ImportKonfliktKontext(),
      erlaubteAktionen: {
        ImportKonfliktAktion.lokaleVersion,
        ImportKonfliktAktion.importVersion,
        ImportKonfliktAktion.ueberspringen,
      },
    );

    expect(
      () => service.entscheide(
        stand: const ImportKonfliktEntscheidungsStand(),
        konflikt: konflikt,
        aktion: ImportKonfliktAktion.beideBehalten,
        alleKonflikte: const [konflikt],
      ),
      throwsArgumentError,
    );
  });
}
