import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';

void main() {
  group('Statistikgrundlage', () {
    test('Kennzahlen halten Anzahl, Minimum, Maximum und Mittelwert fest', () {
      final kennzahlen =
          StatistikKennzahlen.ausWerten([4, 2, 8, 2]);

      expect(kennzahlen.anzahl, 4);
      expect(kennzahlen.minimum, 2);
      expect(kennzahlen.maximum, 8);
      expect(kennzahlen.durchschnitt, 4);
    });

    test('Kennzahlen lehnen eine leere Stichprobe ab', () {
      expect(
        () => StatistikKennzahlen.ausWerten(const <num>[]),
        throwsArgumentError,
      );
    });

    test('Zeitraumgrenzen sind einschließlich', () {
      final filter = AuswertungsFilter(
        von: DateTime(2026, 1, 1),
        bis: DateTime(2026, 1, 31, 23, 59, 59),
      );

      expect(filter.enthaeltZeitpunkt(DateTime(2026, 1, 1)), isTrue);
      expect(filter.enthaeltZeitpunkt(DateTime(2026, 1, 31, 23, 59, 59)), isTrue);
      expect(filter.enthaeltZeitpunkt(DateTime(2025, 12, 31, 23, 59, 59)), isFalse);
      expect(filter.enthaeltZeitpunkt(DateTime(2026, 2, 1)), isFalse);
    });

    test('Wochen beginnen am Montag und Monate am Monatsersten', () {
      final zeitpunkt = StatistikZeitpunkt(
        zeitpunkt: DateTime(2026, 10, 11, 20, 30),
        schluessel: 'Produkt',
      );

      expect(
        zeitpunkt.runde(StatistikZeitraum.woche),
        DateTime(2026, 10, 5),
      );
      expect(
        zeitpunkt.runde(StatistikZeitraum.monat),
        DateTime(2026, 10),
      );
      expect(
        zeitpunkt.runde(StatistikZeitraum.jahr),
        DateTime(2026),
      );
    });
  });
}
