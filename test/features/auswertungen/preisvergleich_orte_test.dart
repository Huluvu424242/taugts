import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';
import 'package:taugts/features/auswertungen/models/preisvergleich_kennzahlen.dart';

void main() {
  test('Ort/Währung nicht vermischen und Preisgleichstände erhalten', () {
    final werte = [
      Zeitwert(
        zeitpunkt: DateTime.utc(2025, 1, 1, 10),
        wert: 3,
        beschreibung: 'Ort A',
        serie: 'Ort A · EUR',
      ),
      Zeitwert(
        zeitpunkt: DateTime.utc(2025, 1, 1, 12),
        wert: 3,
        beschreibung: 'Ort A',
        serie: 'Ort A · EUR',
      ),
      Zeitwert(
        zeitpunkt: DateTime.utc(2026, 1, 1),
        wert: 5,
        beschreibung: 'Ort A',
        serie: 'Ort A · EUR',
      ),
      Zeitwert(
        zeitpunkt: DateTime.utc(2026, 1, 1),
        wert: 2,
        beschreibung: 'Ort B',
        serie: 'Ort B · EUR',
      ),
      Zeitwert(
        zeitpunkt: DateTime.utc(2026, 1, 1),
        wert: 20,
        beschreibung: 'Ort A',
        serie: 'Ort A · USD',
      ),
    ];
    final gruppen = OrtsPreisAnalyse.berechne(werte);
    expect(gruppen, hasLength(3));
    final euro = gruppen.singleWhere((g) => g.serie == 'Ort A · EUR');
    expect(euro.anzahl, 3);
    expect(euro.minimum, 3);
    expect(euro.maximum, 5);
    expect(euro.minimumBeobachtungen, hasLength(2));
    expect(euro.durchschnitt, closeTo(11 / 3, 0.00001));
    expect(euro.ersterKauf, DateTime.utc(2025, 1, 1, 10));
    expect(euro.letzterKauf, DateTime.utc(2026, 1, 1));
  });

  test('leerer Zeitraum liefert keine Orte', () {
    expect(OrtsPreisAnalyse.berechne([]), isEmpty);
  });
}
