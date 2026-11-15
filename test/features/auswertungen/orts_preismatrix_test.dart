import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';
import 'package:taugts/features/auswertungen/models/orts_preismatrix.dart';

void main() {
  test('Preismatrix erhält Mehrfachkäufe und leere Zellen', () {
    final t1 = DateTime.utc(2025, 1, 1, 12);
    final t2 = DateTime.utc(2026, 1, 1, 12);
    final matrix = OrtsPreisMatrix.ausBeobachtungen([
      Zeitwert(zeitpunkt: t1, wert: 2, beschreibung: 'A', serie: 'A · EUR'),
      Zeitwert(zeitpunkt: t1, wert: 3, beschreibung: 'A', serie: 'A · EUR'),
      Zeitwert(zeitpunkt: t2, wert: 4, beschreibung: 'B', serie: 'B · EUR'),
    ]);
    expect(matrix.zeitpunkte, [t1, t2]);
    expect(matrix.zeilen, hasLength(2));
    expect(matrix.zeilen.first.produktUndWaehrung, 'A · EUR');
    expect(matrix.zeilen.first.preiseAm(t1), [2, 3]);
    expect(matrix.zeilen.first.preiseAm(t2), isEmpty);
    expect(matrix.zeilen.last.preiseAm(t2), [4]);
  });

  test('leere Matrix hat keine Spalten', () {
    final matrix = OrtsPreisMatrix.ausBeobachtungen([]);
    expect(matrix.zeitpunkte, isEmpty);
    expect(matrix.zeilen, isEmpty);
  });
}
