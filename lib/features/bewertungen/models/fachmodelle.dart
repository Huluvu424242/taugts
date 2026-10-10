enum Objektart { allgemein, produkt }

enum Produktart { bier, getraenk, speise, sonstiges }

enum Ortstyp { gastronomie, geschaeft, privat, sonstiger }

enum KriteriumEingabetyp {
  wertung,
  intensitaet,
  jaNein,
  zahl,
  auswahl,
  freitext
}

enum KriteriumObjektart {
  getraenk,
  speise,
  sonstigesProdukt,
  gastronomie,
  geschaeft
}

enum Erlebnistyp { restaurantbesuch, einkauf }

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
    required this.herkunftProfilId,
    required this.erstelltAm,
    required this.geaendertAm,
    this.typ = Erlebnistyp.restaurantbesuch,
    this.ortId,
    this.beginn,
    this.ende,
    this.produktId,
    this.kaufortId,
    this.konsumortId,
    this.preis,
    this.menge,
    this.gebinde,
    this.notiz,
  });

  final String id;
  final String herkunftProfilId;
  final Erlebnistyp typ;
  final String? ortId;
  final DateTime? beginn;
  final DateTime? ende;
  final String? produktId;
  final String? kaufortId;
  final String? konsumortId;
  final double? preis;
  final double? menge;
  final String? gebinde;
  final String? notiz;
  final DateTime erstelltAm;
  final DateTime geaendertAm;

  String? get wirksamerOrtId => ortId ?? konsumortId ?? kaufortId;
  DateTime get erlebtAm => beginn ?? erstelltAm;

  List<String> get zeitfehler {
    final fehler = <String>[];
    if (ende != null && beginn == null) {
      fehler.add('Ein Ende benötigt einen Beginn.');
    }
    if (beginn != null && ende != null && ende!.isBefore(beginn!)) {
      fehler.add('Das Ende darf nicht vor dem Beginn liegen.');
    }
    return fehler;
  }

  static const _nichtGesetzt = Object();

  Erlebnis kopiereMit({
    Erlebnistyp? typ,
    Object? ortId = _nichtGesetzt,
    Object? beginn = _nichtGesetzt,
    Object? ende = _nichtGesetzt,
    Object? notiz = _nichtGesetzt,
    DateTime? geaendertAm,
  }) =>
      Erlebnis(
        id: id,
        herkunftProfilId: herkunftProfilId,
        typ: typ ?? this.typ,
        ortId: identical(ortId, _nichtGesetzt) ? this.ortId : ortId as String?,
        beginn: identical(beginn, _nichtGesetzt)
            ? this.beginn
            : beginn as DateTime?,
        ende: identical(ende, _nichtGesetzt) ? this.ende : ende as DateTime?,
        produktId: produktId,
        kaufortId: kaufortId,
        konsumortId: konsumortId,
        preis: preis,
        menge: menge,
        gebinde: gebinde,
        notiz: identical(notiz, _nichtGesetzt) ? this.notiz : notiz as String?,
        erstelltAm: erstelltAm,
        geaendertAm: geaendertAm ?? this.geaendertAm,
      );
}

class Geldbetrag {
  const Geldbetrag({
    required this.minorEinheiten,
    this.waehrung = 'EUR',
  });

  final int minorEinheiten;
  final String waehrung;

  static Geldbetrag? ausEingabe(String eingabe, String waehrung) {
    final normalisiert = eingabe.trim().replaceAll(',', '.');
    final treffer = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(normalisiert);
    if (treffer == null) return null;
    final ganze = int.parse(treffer.group(1)!);
    final nachkomma = (treffer.group(2) ?? '').padRight(2, '0');
    return Geldbetrag(
      minorEinheiten:
          ganze * 100 + (nachkomma.isEmpty ? 0 : int.parse(nachkomma)),
      waehrung: waehrung,
    );
  }

  String get dezimalText {
    final absolut = minorEinheiten.abs();
    final vorzeichen = minorEinheiten < 0 ? '-' : '';
    return '$vorzeichen${absolut ~/ 100},'
        '${(absolut % 100).toString().padLeft(2, '0')}';
  }
}

class ErlebnisPosition {
  const ErlebnisPosition({
    required this.id,
    required this.erlebnisId,
    required this.produktId,
    required this.anzahl,
    required this.erstelltAm,
    required this.geaendertAm,
  });

  final String id;
  final String erlebnisId;
  final String produktId;
  final int anzahl;
  final DateTime erstelltAm;
  final DateTime geaendertAm;

  ErlebnisPosition mitAnzahl(int wert, DateTime geaendertAm) =>
      ErlebnisPosition(
        id: id,
        erlebnisId: erlebnisId,
        produktId: produktId,
        anzahl: wert,
        erstelltAm: erstelltAm,
        geaendertAm: geaendertAm,
      );
}

class Preisbeobachtung {
  const Preisbeobachtung({
    required this.id,
    required this.erlebnisId,
    required this.erlebnisPositionId,
    required this.produktId,
    required this.betrag,
    required this.beobachtetAm,
    required this.erstelltAm,
    required this.geaendertAm,
    this.ortId,
  });

  final String id;
  final String erlebnisId;
  final String erlebnisPositionId;
  final String produktId;
  final String? ortId;
  final Geldbetrag betrag;
  final DateTime beobachtetAm;
  final DateTime erstelltAm;
  final DateTime geaendertAm;
}

class ErlebnispositionMitProdukt {
  const ErlebnispositionMitProdukt({
    required this.position,
    required this.produkt,
    this.preis,
  });

  final ErlebnisPosition position;
  final Produkt produkt;
  final Preisbeobachtung? preis;
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
    this.produktart = Produktart.bier,
    this.objektart,
    this.version = 1,
    this.auswahlwerte = const [],
  });

  final String id;
  final String name;
  final String? beschreibung;
  final KriteriumEingabetyp eingabetyp;
  final int reihenfolge;
  final bool aktiv;
  final Produktart produktart;
  final KriteriumObjektart? objektart;
  final int version;
  final List<String> auswahlwerte;
  final DateTime erstelltAm;
  final DateTime geaendertAm;

  KriteriumObjektart get wirksameObjektart =>
      objektart ??
      switch (produktart) {
        Produktart.bier || Produktart.getraenk => KriteriumObjektart.getraenk,
        Produktart.speise => KriteriumObjektart.speise,
        Produktart.sonstiges => KriteriumObjektart.sonstigesProdukt,
      };
}

abstract final class StandardGetraenkekriterien {
  static const gesamturteilId = 'c0000000-0000-4000-8000-000000000001';
  static const geschmackId = 'c0000000-0000-4000-8000-000000000002';
  static const aromaId = 'c0000000-0000-4000-8000-000000000003';
  static const frischeId = 'c0000000-0000-4000-8000-000000000004';
  static const preisLeistungId = 'c0000000-0000-4000-8000-000000000005';
  static const bitterkeitId = 'c0000000-0000-4000-8000-000000000006';
  static const farbintensitaetId = 'c0000000-0000-4000-8000-000000000007';

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

abstract final class StandardSpeisekriterien {
  static const gesamturteilId = 'd0000000-0000-4000-8000-000000000001';
  static const geschmackId = 'd0000000-0000-4000-8000-000000000002';
  static const frischeZubereitungId = 'd0000000-0000-4000-8000-000000000003';
  static const konsistenzId = 'd0000000-0000-4000-8000-000000000004';
  static const temperaturId = 'd0000000-0000-4000-8000-000000000005';
  static const preisLeistungId = 'd0000000-0000-4000-8000-000000000006';

  static List<Bewertungskriterium> alle(DateTime zeitpunkt) {
    const namen = [
      ('Gesamturteil', 'Unabhängige Gesamtwertung der Speise.'),
      ('Geschmack', 'Wie gut hat die Speise geschmeckt?'),
      ('Frische / Zubereitung', 'Wie frisch und passend zubereitet war sie?'),
      ('Konsistenz', 'Wie passend war die Konsistenz?'),
      ('Temperatur', 'Wie passend war die Serviertemperatur?'),
      ('Preis-Leistung', 'Wie passend war der Preis für dieses Erlebnis?'),
    ];
    const ids = [
      gesamturteilId,
      geschmackId,
      frischeZubereitungId,
      konsistenzId,
      temperaturId,
      preisLeistungId,
    ];
    return [
      for (var index = 0; index < ids.length; index++)
        Bewertungskriterium(
          id: ids[index],
          name: namen[index].$1,
          beschreibung: namen[index].$2,
          reihenfolge: index * 10,
          produktart: Produktart.speise,
          erstelltAm: zeitpunkt,
          geaendertAm: zeitpunkt,
        ),
    ];
  }
}

abstract final class StandardFallbackKriterien {
  static const gesamturteilId = 'e0000000-0000-4000-8000-000000000001';

  static Bewertungskriterium gesamturteil(DateTime zeitpunkt) =>
      Bewertungskriterium(
        id: gesamturteilId,
        name: 'Gesamturteil',
        beschreibung: 'Unabhängige Gesamtwertung des Produkts.',
        produktart: Produktart.sonstiges,
        erstelltAm: zeitpunkt,
        geaendertAm: zeitpunkt,
      );
}

abstract final class StandardOrtskriterien {
  static List<Bewertungskriterium> gastronomie(DateTime zeitpunkt) => _erstelle(
        zeitpunkt,
        KriteriumObjektart.gastronomie,
        'f1',
        const [
          'Gesamturteil',
          'Service',
          'Freundlichkeit',
          'Sauberkeit',
          'Atmosphäre',
          'Auswahl',
          'Preis-Leistung'
        ],
      );

  static List<Bewertungskriterium> geschaeft(DateTime zeitpunkt) => _erstelle(
        zeitpunkt,
        KriteriumObjektart.geschaeft,
        'f2',
        const [
          'Gesamturteil',
          'Andrang / Auslastung',
          'Wartezeit',
          'Sauberkeit',
          'Auffindbarkeit',
          'Sortiment',
          'Verfügbarkeit',
          'Service'
        ],
      );

  static List<Bewertungskriterium> _erstelle(
    DateTime zeitpunkt,
    KriteriumObjektart objektart,
    String praefix,
    List<String> namen,
  ) =>
      [
        for (var index = 0; index < namen.length; index++)
          Bewertungskriterium(
            id: '$praefix${index.toString().padLeft(2, '0')}0000-0000-4000-8000-000000000001',
            name: namen[index],
            beschreibung:
                'Bewertung für ${objektart == KriteriumObjektart.gastronomie ? 'Gastronomie' : 'Geschäfte'}.',
            eingabetyp: namen[index] == 'Andrang / Auslastung'
                ? KriteriumEingabetyp.intensitaet
                : namen[index] == 'Wartezeit'
                    ? KriteriumEingabetyp.zahl
                    : KriteriumEingabetyp.wertung,
            reihenfolge: index * 10,
            objektart: objektart,
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
    required this.erstelltAm,
    required this.geaendertAm,
    this.wert,
    this.textWert,
    this.erlebnisPositionId,
    this.ortId,
    this.kriteriumName,
    this.kriteriumBeschreibung,
    this.kriteriumEingabetyp,
    this.kriteriumReihenfolge,
    this.kriteriumVersion,
    this.kriteriumAuswahlwerte = const [],
    this.ortsbewertungId,
  })  : assert(wert != null || textWert != null),
        assert(wert == null || textWert == null);

  final String id;
  final String erlebnisId;
  final String? erlebnisPositionId;
  final String? ortId;
  final String? ortsbewertungId;
  final String kriteriumId;
  final String herkunftProfilId;
  final double? wert;
  final String? textWert;
  final DateTime erstelltAm;
  final DateTime geaendertAm;
  final String? kriteriumName;
  final String? kriteriumBeschreibung;
  final KriteriumEingabetyp? kriteriumEingabetyp;
  final int? kriteriumReihenfolge;
  final int? kriteriumVersion;
  final List<String> kriteriumAuswahlwerte;
}

class Ortsbewertung {
  const Ortsbewertung({
    required this.id,
    required this.erlebnisId,
    required this.ortId,
    required this.herkunftProfilId,
    required this.bewertetAm,
    required this.erstelltAm,
    required this.geaendertAm,
    this.notiz,
  });

  final String id;
  final String erlebnisId;
  final String ortId;
  final String herkunftProfilId;
  final DateTime bewertetAm;
  final String? notiz;
  final DateTime erstelltAm;
  final DateTime geaendertAm;
}

class OrtsbewertungMitWerten {
  const OrtsbewertungMitWerten(
      {required this.ortsbewertung, required this.werte});

  final Ortsbewertung ortsbewertung;
  final List<Bewertung> werte;
}

class BewertungsverlaufEintrag {
  const BewertungsverlaufEintrag({
    required this.erlebnis,
    required this.bewertungen,
    required this.herkunftProfilId,
    this.ort,
    this.position,
    this.preis,
    this.historischerPreis,
    this.historischeMenge,
    this.historischesGebinde,
    this.notiz,
  });

  final Erlebnis erlebnis;
  final Ort? ort;
  final ErlebnisPosition? position;
  final Preisbeobachtung? preis;
  final double? historischerPreis;
  final double? historischeMenge;
  final String? historischesGebinde;
  final List<Bewertung> bewertungen;
  final String herkunftProfilId;
  final String? notiz;
}
