enum Objektart { allgemein, produkt }

enum Produktart { bier, sonstiges }

enum Ortstyp { gastronomie, geschaeft, privat, sonstiger }

enum KriteriumEingabetyp { wertung, intensitaet }

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
    this.produktart = Produktart.bier,
    this.marke,
    this.brauerei,
    this.sorte,
    this.alkoholgehalt,
    this.herkunft,
    this.gebinde,
    this.fuellmengeMl,
    this.barcode,
    this.notiz,
  }) : super(art: Objektart.produkt);

  final Produktart produktart;
  final String? marke;
  final String? brauerei;
  final String? sorte;
  final double? alkoholgehalt;
  final String? herkunft;
  final String? gebinde;
  final int? fuellmengeMl;
  final String? barcode;
  final String? notiz;

  bool get hatMinimalangabe =>
      name.trim().isNotEmpty || (barcode?.trim().isNotEmpty ?? false);

  bool get istUnvollstaendig {
    if (name.trim().isEmpty) return true;
    if (produktart == Produktart.sonstiges) return false;
    return [marke, brauerei, sorte].any(
      (wert) => wert == null || wert.trim().isEmpty,
    );
  }

  String get anzeigetitel => name.trim().isNotEmpty
      ? name.trim()
      : (barcode?.trim().isNotEmpty ?? false)
          ? barcode!.trim()
          : 'Unbenanntes Produkt';
}

class Ort {
  const Ort({
    required this.id,
    required this.name,
    required this.typ,
    required this.erstelltAm,
    required this.geaendertAm,
    this.adresse,
    this.breitengrad,
    this.laengengrad,
    this.osmReferenz,
    this.notiz,
  });

  final String id;
  final String name;
  final Ortstyp typ;
  final String? adresse;
  final double? breitengrad;
  final double? laengengrad;
  final String? osmReferenz;
  final String? notiz;
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
    this.preis,
    this.menge,
    this.gebinde,
    this.notiz,
    this.istEntwurf = true,
  });

  final String id;
  final String produktId;
  final String herkunftProfilId;
  final String? kaufortId;
  final String? konsumortId;
  final double? preis;
  final double? menge;
  final String? gebinde;
  final String? notiz;
  final bool istEntwurf;
  final DateTime erlebtAm;
  final DateTime erstelltAm;
  final DateTime geaendertAm;

  static const _nichtGesetzt = Object();

  Erlebnis kopiereMit({
    Object? notiz = _nichtGesetzt,
    bool? istEntwurf,
    DateTime? geaendertAm,
  }) =>
      Erlebnis(
        id: id,
        produktId: produktId,
        herkunftProfilId: herkunftProfilId,
        kaufortId: kaufortId,
        konsumortId: konsumortId,
        preis: preis,
        menge: menge,
        gebinde: gebinde,
        notiz: identical(notiz, _nichtGesetzt) ? this.notiz : notiz as String?,
        istEntwurf: istEntwurf ?? this.istEntwurf,
        erlebtAm: erlebtAm,
        erstelltAm: erstelltAm,
        geaendertAm: geaendertAm ?? this.geaendertAm,
      );
}

class Bewertungskriterium {
  const Bewertungskriterium({
    required this.id,
    required this.name,
    required this.erstelltAm,
    required this.geaendertAm,
    this.beschreibung,
    this.eingabetyp = KriteriumEingabetyp.wertung,
    this.reihenfolge = 0,
    this.aktiv = true,
  });

  final String id;
  final String name;
  final String? beschreibung;
  final KriteriumEingabetyp eingabetyp;
  final int reihenfolge;
  final bool aktiv;
  final DateTime erstelltAm;
  final DateTime geaendertAm;
}

abstract final class StandardGetraenkekriterien {
  static const gesamturteilId =
      'c0000000-0000-4000-8000-000000000001';
  static const geschmackId = 'c0000000-0000-4000-8000-000000000002';
  static const aromaId = 'c0000000-0000-4000-8000-000000000003';
  static const frischeId = 'c0000000-0000-4000-8000-000000000004';
  static const preisLeistungId =
      'c0000000-0000-4000-8000-000000000005';
  static const bitterkeitId = 'c0000000-0000-4000-8000-000000000006';
  static const farbintensitaetId =
      'c0000000-0000-4000-8000-000000000007';

  static List<Bewertungskriterium> alle(DateTime zeitpunkt) => [
        Bewertungskriterium(
          id: gesamturteilId,
          name: 'Gesamturteil',
          beschreibung: 'Unabhängige Gesamtwertung des Getränks.',
          reihenfolge: 0,
          erstelltAm: zeitpunkt,
          geaendertAm: zeitpunkt,
        ),
        Bewertungskriterium(
          id: geschmackId,
          name: 'Geschmack',
          beschreibung: 'Wie gut hat das Getränk geschmeckt?',
          reihenfolge: 10,
          erstelltAm: zeitpunkt,
          geaendertAm: zeitpunkt,
        ),
        Bewertungskriterium(
          id: aromaId,
          name: 'Aroma',
          beschreibung: 'Wie angenehm war das wahrgenommene Aroma?',
          reihenfolge: 20,
          erstelltAm: zeitpunkt,
          geaendertAm: zeitpunkt,
        ),
        Bewertungskriterium(
          id: frischeId,
          name: 'Frische',
          beschreibung: 'Wie frisch wirkte das Getränk?',
          reihenfolge: 30,
          erstelltAm: zeitpunkt,
          geaendertAm: zeitpunkt,
        ),
        Bewertungskriterium(
          id: preisLeistungId,
          name: 'Preis-Leistung',
          beschreibung: 'Wie passend war der Preis für dieses Erlebnis?',
          reihenfolge: 40,
          erstelltAm: zeitpunkt,
          geaendertAm: zeitpunkt,
        ),
        Bewertungskriterium(
          id: bitterkeitId,
          name: 'Bitterkeit',
          beschreibung: 'Beschreibende Intensität, keine Qualitätswertung.',
          eingabetyp: KriteriumEingabetyp.intensitaet,
          reihenfolge: 50,
          erstelltAm: zeitpunkt,
          geaendertAm: zeitpunkt,
        ),
        Bewertungskriterium(
          id: farbintensitaetId,
          name: 'Farbintensität',
          beschreibung: 'Beschreibende Intensität, keine Qualitätswertung.',
          eingabetyp: KriteriumEingabetyp.intensitaet,
          reihenfolge: 60,
          erstelltAm: zeitpunkt,
          geaendertAm: zeitpunkt,
        ),
      ];
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
