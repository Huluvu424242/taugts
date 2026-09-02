import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/datenaustausch/services/import_strategie_service.dart';

void main() {
  const service = ImportStrategieService();

  Map<String, Object?> dokument({
    List<Map<String, Object?>> objekte = const [],
    List<Map<String, Object?>> erlebnisse = const [],
    List<Map<String, Object?>> bewertungen = const [],
  }) =>
      {
        'objekte': objekte,
        'erlebnisse': erlebnisse,
        'bewertungen': bewertungen,
      };

  test('Bestand ersetzen entfernt ausschließlich lokale Datensätze', () {
    final plan = service.plane(
      strategie: ImportStrategie.bestandErsetzen,
      importDokument: dokument(objekte: [
        {'id': 'neu', 'name': 'Neu'},
      ]),
      lokalesDokument: dokument(objekte: [
        {'id': 'alt', 'name': 'Alt'},
      ]),
    );

    final objekte = plan.sammlungen.singleWhere((e) => e.name == 'objekte');
    expect(objekte.hinzufuegen, 1);
    expect(objekte.entfernen, 1);
  });

  test(
      'Import bevorzugen aktualisiert identische UUID und behält lokalen Zusatz',
      () {
    final plan = service.plane(
      strategie: ImportStrategie.importBevorzugen,
      importDokument: dokument(objekte: [
        {'id': 'gleich', 'name': 'Import'},
      ]),
      lokalesDokument: dokument(objekte: [
        {'id': 'gleich', 'name': 'Lokal'},
        {'id': 'nur-lokal', 'name': 'Lokal behalten'},
      ]),
    );

    final objekte = plan.sammlungen.singleWhere((e) => e.name == 'objekte');
    expect(objekte.aktualisieren, 1);
    expect(objekte.behalten, 1);
    expect(objekte.entfernen, 0);
  });

  test('Lokal bevorzugen überschreibt vorhandene UUID nicht', () {
    final plan = service.plane(
      strategie: ImportStrategie.lokalBevorzugen,
      importDokument: dokument(objekte: [
        {'id': 'gleich', 'name': 'Import'},
        {'id': 'neu', 'name': 'Neu'},
      ]),
      lokalesDokument: dokument(objekte: [
        {'id': 'gleich', 'name': 'Lokal'},
      ]),
    );

    final objekte = plan.sammlungen.singleWhere((e) => e.name == 'objekte');
    expect(objekte.hinzufuegen, 1);
    expect(objekte.aktualisieren, 0);
    expect(objekte.behalten, 1);
  });

  test(
      'historische Datensätze mit verschiedenen IDs bleiben zusätzlich erhalten',
      () {
    final plan = service.plane(
      strategie: ImportStrategie.importBevorzugen,
      importDokument: dokument(bewertungen: [
        {
          'id': 'bew-import',
          'objektId': 'bier',
          'zeitpunkt': '2026-08-02',
          'wert': 4
        },
      ]),
      lokalesDokument: dokument(bewertungen: [
        {
          'id': 'bew-lokal',
          'objektId': 'bier',
          'zeitpunkt': '2026-08-01',
          'wert': 3
        },
      ]),
    );

    final bewertungen =
        plan.sammlungen.singleWhere((e) => e.name == 'bewertungen');
    expect(bewertungen.hinzufuegen, 1);
    expect(bewertungen.behalten, 1);
    expect(bewertungen.entfernen, 0);
  });

  test(
      'gleiche historische ID mit anderem Kontext wird als Identitätskonflikt markiert',
      () {
    final plan = service.plane(
      strategie: ImportStrategie.importBevorzugen,
      importDokument: dokument(erlebnisse: [
        {'id': 'e1', 'ortId': 'ort-a', 'begonnenAm': '2026-08-02T18:00:00Z'},
      ]),
      lokalesDokument: dokument(erlebnisse: [
        {'id': 'e1', 'ortId': 'ort-b', 'begonnenAm': '2026-08-01T18:00:00Z'},
      ]),
    );

    expect(plan.identitaetsKonflikte, hasLength(1));
    expect(plan.identitaetsKonflikte.single.id, 'e1');
  });

  test(
      'fachliche Dubletten werden nur ausgewiesen und nicht still zusammengeführt',
      () {
    final plan = service.plane(
      strategie: ImportStrategie.importBevorzugen,
      importDokument: dokument(),
      lokalesDokument: dokument(),
      fachlicheDubletten: const [
        FachlicheDubletteHinweis(
            sammlung: 'objekte', importId: 'i', lokaleId: 'l'),
      ],
    );

    expect(plan.fachlicheDubletten, hasLength(1));
  });
}
