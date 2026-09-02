import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/datenaustausch/services/import_strategie_service.dart';

void main() {
  const service = ImportStrategieService();

  test('plant Positionen und Ortsbewertungen mit den Export-Schlüsseln', () {
    final plan = service.plane(
      strategie: ImportStrategie.importBevorzugen,
      importDokument: {
        'erlebnisPositionen': [
          {'id': 'position-neu', 'erlebnisId': 'e1', 'produktId': 'p1'},
        ],
        'ortsbewertungen': [
          {'id': 'ort-neu', 'erlebnisId': 'e1', 'ortId': 'o1'},
        ],
      },
      lokalesDokument: {
        'erlebnisPositionen': [
          {'id': 'position-alt', 'erlebnisId': 'e0', 'produktId': 'p1'},
        ],
        'ortsbewertungen': [
          {'id': 'ort-alt', 'erlebnisId': 'e0', 'ortId': 'o1'},
        ],
      },
    );

    final positionen = plan.sammlungen
        .singleWhere((sammlung) => sammlung.name == 'erlebnisPositionen');
    final ortsbewertungen = plan.sammlungen
        .singleWhere((sammlung) => sammlung.name == 'ortsbewertungen');

    expect(positionen.hinzufuegen, 1);
    expect(positionen.behalten, 1);
    expect(ortsbewertungen.hinzufuegen, 1);
    expect(ortsbewertungen.behalten, 1);
  });

  test('erkennt historischen Positionskonflikt anhand stabiler ID', () {
    final plan = service.plane(
      strategie: ImportStrategie.importBevorzugen,
      importDokument: {
        'erlebnisPositionen': [
          {'id': 'position-1', 'erlebnisId': 'e1', 'produktId': 'p1'},
        ],
      },
      lokalesDokument: {
        'erlebnisPositionen': [
          {'id': 'position-1', 'erlebnisId': 'e2', 'produktId': 'p1'},
        ],
      },
    );

    expect(plan.identitaetsKonflikte, hasLength(1));
    expect(plan.identitaetsKonflikte.single.sammlung, 'erlebnisPositionen');
  });
}
