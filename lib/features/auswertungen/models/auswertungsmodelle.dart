enum StatistikZeitraum { tag, woche, monat, jahr }

enum StatistikObjektart { produkt, ort }

class AuswertungsFilter {
  const AuswertungsFilter({
    this.kategorieId,
    this.objektId,
    this.objektArt = StatistikObjektart.produkt,
    this.kriteriumId,
    this.herkunftProfilId,
    this.von,
    this.bis,
  });

  final String? kategorieId;
  final String? objektId;
  final StatistikObjektart objektArt;
  final String? kriteriumId;
  final String? herkunftProfilId;

  /// Inklusive Untergrenze der fachlichen Ereigniszeit.
  final DateTime? von;

  /// Inklusive Obergrenze der fachlichen Ereigniszeit.
  final DateTime? bis;

  bool get hatGueltigenZeitraum {
    final start = von;
    final ende = bis;
    return start == null || ende == null || !ende.isBefore(start);
  }

  bool enthaeltZeitpunkt(DateTime zeitpunkt) {
    final lokal = zeitpunkt.toLocal();
    final start = von?.toLocal();
    final ende = bis?.toLocal();
    return (start == null || !lokal.isBefore(start)) &&
        (ende == null || !lokal.isAfter(ende));
  }
}

class StatistikKennzahlen {
  const StatistikKennzahlen({
    required this.anzahl,
    required this.minimum,
    required this.maximum,
    required this.durchschnitt,
  });

  factory StatistikKennzahlen.ausWerten(Iterable<num> werte) {
    final sortiert = werte.map((wert) => wert.toDouble()).toList()..sort();
    if (sortiert.isEmpty) {
      throw ArgumentError.value(werte, 'werte', 'Darf nicht leer sein.');
    }
    final summe = sortiert.fold<double>(0, (summe, wert) => summe + wert);
    return StatistikKennzahlen(
      anzahl: sortiert.length,
      minimum: sortiert.first,
      maximum: sortiert.last,
      durchschnitt: summe / sortiert.length,
    );
  }

  final int anzahl;
  final double minimum;
  final double maximum;
  final double durchschnitt;
}

class StatistikZeitpunkt {
  const StatistikZeitpunkt({
    required this.zeitpunkt,
    required this.schluessel,
  });

  final DateTime zeitpunkt;
  final String schluessel;

  DateTime runde(StatistikZeitraum zeitraum) {
    final zeit = zeitpunkt.toLocal();
    switch (zeitraum) {
      case StatistikZeitraum.tag:
        return DateTime(zeit.year, zeit.month, zeit.day);
      case StatistikZeitraum.woche:
        final wochenbeginn = DateTime(zeit.year, zeit.month, zeit.day)
            .subtract(Duration(days: zeit.weekday - DateTime.monday));
        return wochenbeginn;
      case StatistikZeitraum.monat:
        return DateTime(zeit.year, zeit.month);
      case StatistikZeitraum.jahr:
        return DateTime(zeit.year);
    }
  }
}

class AuswertungsFilterOption {
  const AuswertungsFilterOption({
    required this.id,
    required this.bezeichnung,
  });

  final String id;
  final String bezeichnung;
}

class AuswertungsFilterOptionen {
  const AuswertungsFilterOptionen({
    required this.produkte,
    required this.orte,
    required this.kategorien,
    required this.kriterien,
  });

  final List<AuswertungsFilterOption> produkte;
  final List<AuswertungsFilterOption> orte;
  final List<AuswertungsFilterOption> kategorien;
  final List<AuswertungsFilterOption> kriterien;
}

class Durchschnittswert {
  const Durchschnittswert({
    required this.kriterium,
    required this.kriteriumVersion,
    required this.anzahl,
    required this.durchschnitt,
  });

  final String kriterium;
  final int kriteriumVersion;
  final int anzahl;
  final double durchschnitt;
}

class Zeitwert {
  const Zeitwert({
    required this.zeitpunkt,
    required this.wert,
    required this.beschreibung,
    this.serie,
    this.kennzahlen,
  });

  final DateTime zeitpunkt;
  final double wert;
  final String beschreibung;

  /// Gruppierung, die niemals mit anderen Einheiten vermischt werden darf.
  final String? serie;
  final StatistikKennzahlen? kennzahlen;
}

class StatistikRechnung {
  const StatistikRechnung._();

  static List<Zeitwert> aggregiere(
    Iterable<Zeitwert> werte,
    StatistikZeitraum zeitraum, {
    bool summieren = false,
  }) {
    final gruppen = <(DateTime, String?, String), List<double>>{};
    for (final wert in werte) {
      final start = StatistikZeitpunkt(
        zeitpunkt: wert.zeitpunkt,
        schluessel: wert.beschreibung,
      ).runde(zeitraum);
      gruppen.putIfAbsent(
          (start, wert.serie, wert.beschreibung), () => []).add(wert.wert);
    }

    final ergebnis = [
      for (final eintrag in gruppen.entries)
        Zeitwert(
          zeitpunkt: eintrag.key.$1,
          wert: summieren
              ? eintrag.value.fold<double>(0, (summe, wert) => summe + wert)
              : StatistikKennzahlen.ausWerten(eintrag.value).durchschnitt,
          beschreibung: eintrag.key.$3,
          serie: eintrag.key.$2,
          kennzahlen:
              summieren ? null : StatistikKennzahlen.ausWerten(eintrag.value),
        ),
    ]..sort((a, b) {
        final zeit = a.zeitpunkt.compareTo(b.zeitpunkt);
        return zeit != 0 ? zeit : a.beschreibung.compareTo(b.beschreibung);
      });
    return ergebnis;
  }
}

class ErlebnisGruppe {
  const ErlebnisGruppe({
    required this.schluessel,
    required this.anzahl,
    required this.gesamtdauerMinuten,
  });

  final String schluessel;
  final int anzahl;
  final int gesamtdauerMinuten;
}

class AuswertungsUebersicht {
  const AuswertungsUebersicht({
    required this.bewertungsanzahl,
    required this.durchschnitte,
    required this.preisverlauf,
    required this.ausgabenverlauf,
    required this.qualitaetsverlauf,
    required this.ortsverlauf,
    required this.erlebnisgruppen,
    required this.andrangBeobachtungen,
  });

  final int bewertungsanzahl;
  final List<Durchschnittswert> durchschnitte;
  final List<Zeitwert> preisverlauf;
  final List<Zeitwert> ausgabenverlauf;
  final List<Zeitwert> qualitaetsverlauf;
  final List<Zeitwert> ortsverlauf;
  final List<ErlebnisGruppe> erlebnisgruppen;
  final List<Zeitwert> andrangBeobachtungen;
}
