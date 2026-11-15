import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';

/// Berechnet Preiskennzahlen ausschließlich innerhalb einer Ort/Währung-Serie.
class OrtsPreisKennzahl {
  const OrtsPreisKennzahl({
    required this.serie,
    required this.anzahl,
    required this.minimum,
    required this.maximum,
    required this.durchschnitt,
    required this.ersterKauf,
    required this.letzterKauf,
    required this.minimumBeobachtungen,
    required this.maximumBeobachtungen,
  });

  final String serie;
  final int anzahl;
  final double minimum;
  final double maximum;
  final double durchschnitt;
  final DateTime ersterKauf;
  final DateTime letzterKauf;
  final List<Zeitwert> minimumBeobachtungen;
  final List<Zeitwert> maximumBeobachtungen;
}

abstract final class OrtsPreisAnalyse {
  static List<OrtsPreisKennzahl> berechne(Iterable<Zeitwert> werte) {
    final gruppen = <String, List<Zeitwert>>{};
    for (final wert in werte) {
      gruppen.putIfAbsent(wert.serie ?? '', () => []).add(wert);
    }
    return [
      for (final gruppe in gruppen.entries)
        _kennzahl(gruppe.key, gruppe.value),
    ]..sort((a, b) => a.serie.compareTo(b.serie));
  }

  static OrtsPreisKennzahl _kennzahl(String serie, List<Zeitwert> werte) {
    final punkte = [...werte]
      ..sort((a, b) => a.zeitpunkt.compareTo(b.zeitpunkt));
    final kennzahlen = StatistikKennzahlen.ausWerten(
      punkte.map((wert) => wert.wert),
    );
    return OrtsPreisKennzahl(
      serie: serie,
      anzahl: kennzahlen.anzahl,
      minimum: kennzahlen.minimum,
      maximum: kennzahlen.maximum,
      durchschnitt: kennzahlen.durchschnitt,
      ersterKauf: punkte.first.zeitpunkt,
      letzterKauf: punkte.last.zeitpunkt,
      minimumBeobachtungen: [
        for (final wert in punkte)
          if (wert.wert == kennzahlen.minimum) wert,
      ],
      maximumBeobachtungen: [
        for (final wert in punkte)
          if (wert.wert == kennzahlen.maximum) wert,
      ],
    );
  }
}
