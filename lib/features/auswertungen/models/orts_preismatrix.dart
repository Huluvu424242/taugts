import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';

/// Produkte/Währungen bilden Zeilen, beobachtete Zeitpunkte die Spalten.
class OrtsPreisMatrixZeile {
  const OrtsPreisMatrixZeile(this.produktUndWaehrung, this.preiseJeZeitpunkt);
  final String produktUndWaehrung;
  final Map<String, List<double>> preiseJeZeitpunkt;

  List<double> preiseAm(DateTime zeitpunkt) =>
      preiseJeZeitpunkt[zeitpunkt.toUtc().toIso8601String()] ?? const [];
}

class OrtsPreisMatrix {
  const OrtsPreisMatrix(this.zeitpunkte, this.zeilen);
  factory OrtsPreisMatrix.ausBeobachtungen(Iterable<Zeitwert> beobachtungen) {
    final werte = [...beobachtungen]
      ..sort((a, b) => a.zeitpunkt.compareTo(b.zeitpunkt));
    final zeiten = <String, DateTime>{};
    final gruppen = <String, Map<String, List<double>>>{};
    for (final wert in werte) {
      final zeit = wert.zeitpunkt.toUtc().toIso8601String();
      zeiten[zeit] = wert.zeitpunkt;
      gruppen
          .putIfAbsent(wert.serie ?? 'Ohne Produkt', () => {})
          .putIfAbsent(zeit, () => [])
          .add(wert.wert);
    }
    return OrtsPreisMatrix(
      zeiten.values.toList(),
      [
        for (final key in (gruppen.keys.toList()..sort()))
          OrtsPreisMatrixZeile(key, gruppen[key]!),
      ],
    );
  }

  final List<DateTime> zeitpunkte;
  final List<OrtsPreisMatrixZeile> zeilen;
}
