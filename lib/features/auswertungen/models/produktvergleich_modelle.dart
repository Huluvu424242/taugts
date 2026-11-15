enum VergleichOrtstyp { gaststaetten, geschaefte, beide }

class ProduktvergleichFilter {
  const ProduktvergleichFilter({
    required this.produktId,
    this.ortstyp = VergleichOrtstyp.gaststaetten,
    this.von,
    this.bis,
  });

  final String produktId;
  final VergleichOrtstyp ortstyp;
  final DateTime? von;
  final DateTime? bis;

  bool enthaelt(DateTime zeitpunkt) {
    final tag = zeitpunkt.toLocal();
    final start = von?.toLocal();
    final ende = bis?.toLocal();
    return (start == null || !tag.isBefore(start)) &&
        (ende == null || !tag.isAfter(ende));
  }

  bool enthaeltOrtstyp(String typ) => switch (ortstyp) {
    VergleichOrtstyp.gaststaetten =>
      typ == 'gaststaette' || typ == 'gastronomie',
    VergleichOrtstyp.geschaefte => typ == 'geschaeft',
    VergleichOrtstyp.beide =>
      typ == 'gaststaette' || typ == 'gastronomie' || typ == 'geschaeft',
  };
}

class ProduktPreisRang {
  const ProduktPreisRang({
    required this.ortId,
    required this.ortName,
    required this.ortTyp,
    required this.zeitpunkt,
    required this.preis,
    required this.waehrung,
    required this.preisId,
    this.mengeMl,
    this.euroProLiter,
    this.nichtVergleichbar,
  });

  final String ortId;
  final String ortName;
  final String ortTyp;
  final DateTime zeitpunkt;
  final String preisId;
  final double preis;
  final String waehrung;
  final int? mengeMl;
  final double? euroProLiter;
  final String? nichtVergleichbar;
}

abstract interface class ProduktPreisvergleichService {
  Future<List<ProduktPreisRang>> ladeLetztePreise(
    ProduktvergleichFilter filter,
  );
}

class ProduktBewertungsRang {
  const ProduktBewertungsRang({
    required this.ortId,
    required this.ortName,
    required this.durchschnitt,
    required this.anzahlErlebnisse,
    required this.letzteBewertung,
  });
  final String ortId;
  final String ortName;
  final double durchschnitt;
  final int anzahlErlebnisse;
  final DateTime letzteBewertung;
}

abstract interface class ProduktBewertungsvergleichService {
  Future<List<ProduktBewertungsRang>> ladeBewertungen(
    ProduktvergleichFilter filter,
  );
}
