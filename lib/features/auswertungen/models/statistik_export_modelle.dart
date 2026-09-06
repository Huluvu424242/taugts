class BewertungsKennzahlen {
  const BewertungsKennzahlen({
    required this.beste,
    required this.schlechteste,
    required this.durchschnitt,
    required this.anzahl,
  });

  final double beste;
  final double schlechteste;
  final double durchschnitt;
  final int anzahl;
}

class ProduktOrtKennzahlen {
  const ProduktOrtKennzahlen({
    required this.produktId,
    required this.produktName,
    required this.ortId,
    required this.ortName,
    required this.kennzahlen,
  });

  final String produktId;
  final String produktName;
  final String ortId;
  final String ortName;
  final BewertungsKennzahlen kennzahlen;
}

class OrtsKennzahlen {
  const OrtsKennzahlen({
    required this.ortId,
    required this.ortName,
    required this.kennzahlen,
  });

  final String ortId;
  final String ortName;
  final BewertungsKennzahlen kennzahlen;
}

class OrtsVerlaufsPunkt {
  const OrtsVerlaufsPunkt({
    required this.ortId,
    required this.ortName,
    required this.zeitpunkt,
    required this.durchschnitt,
  });

  final String ortId;
  final String ortName;
  final DateTime zeitpunkt;
  final double durchschnitt;
}

class StatistikExportDaten {
  const StatistikExportDaten({
    required this.produktbewertungen,
    required this.ortsbewertungen,
    required this.ortsverlauf,
  });

  final List<ProduktOrtKennzahlen> produktbewertungen;
  final List<OrtsKennzahlen> ortsbewertungen;
  final List<OrtsVerlaufsPunkt> ortsverlauf;

  bool get hatAuswertbareWertungen =>
      produktbewertungen.isNotEmpty || ortsbewertungen.isNotEmpty;
}
