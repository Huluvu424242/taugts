enum Objektart { allgemein, produkt }

enum Ortstyp { gastronomie, geschaeft, privat, sonstiger }

class BewertbaresObjekt {
  const BewertbaresObjekt({
    required this.id,
    required this.name,
    required this.art,
    required this.erstelltAm,
    required this.geaendertAm,
  });

  final String id;
  final String name;
  final Objektart art;
  final DateTime erstelltAm;
  final DateTime geaendertAm;
}

class Produkt extends BewertbaresObjekt {
  const Produkt({
    required super.id,
    required super.name,
    required super.erstelltAm,
    required super.geaendertAm,
    this.marke,
  }) : super(art: Objektart.produkt);

  final String? marke;
}

class Ort {
  const Ort({
    required this.id,
    required this.name,
    required this.typ,
    required this.erstelltAm,
    required this.geaendertAm,
  });

  final String id;
  final String name;
  final Ortstyp typ;
  final DateTime erstelltAm;
  final DateTime geaendertAm;
}

class Erlebnis {
  const Erlebnis({
    required this.id,
    required this.produktId,
    required this.herkunftProfilId,
    required this.erlebtAm,
    required this.erstelltAm,
    required this.geaendertAm,
    this.kaufortId,
    this.konsumortId,
  });

  final String id;
  final String produktId;
  final String herkunftProfilId;
  final String? kaufortId;
  final String? konsumortId;
  final DateTime erlebtAm;
  final DateTime erstelltAm;
  final DateTime geaendertAm;
}

class Bewertungskriterium {
  const Bewertungskriterium({
    required this.id,
    required this.name,
    required this.erstelltAm,
    required this.geaendertAm,
  });

  final String id;
  final String name;
  final DateTime erstelltAm;
  final DateTime geaendertAm;
}

class Bewertung {
  const Bewertung({
    required this.id,
    required this.erlebnisId,
    required this.kriteriumId,
    required this.herkunftProfilId,
    required this.wert,
    required this.erstelltAm,
    required this.geaendertAm,
  });

  final String id;
  final String erlebnisId;
  final String kriteriumId;
  final String herkunftProfilId;
  final double wert;
  final DateTime erstelltAm;
  final DateTime geaendertAm;
}
