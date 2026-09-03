enum KategorieBereich { produkt, ort }

class Kategorie {
  const Kategorie({
    required this.id,
    required this.name,
    required this.bereich,
    this.elternId,
    this.istStandard = false,
  });

  final String id;
  final String name;
  final KategorieBereich bereich;
  final String? elternId;
  final bool istStandard;

  Kategorie kopiereMit({String? name, String? elternId, bool elternEntfernen = false}) =>
      Kategorie(
        id: id,
        name: name ?? this.name,
        bereich: bereich,
        elternId: elternEntfernen ? null : elternId ?? this.elternId,
        istStandard: istStandard,
      );
}

abstract final class StandardKategorien {
  static const produkt = Kategorie(
    id: '10000000-0000-4000-8000-000000000001',
    name: 'Produkt',
    bereich: KategorieBereich.produkt,
    istStandard: true,
  );
  static const getraenk = Kategorie(
    id: '10000000-0000-4000-8000-000000000002',
    name: 'Getränk',
    bereich: KategorieBereich.produkt,
    elternId: '10000000-0000-4000-8000-000000000001',
    istStandard: true,
  );
  static const bier = Kategorie(
    id: '10000000-0000-4000-8000-000000000003',
    name: 'Bier',
    bereich: KategorieBereich.produkt,
    elternId: '10000000-0000-4000-8000-000000000002',
    istStandard: true,
  );
  static const speise = Kategorie(
    id: '10000000-0000-4000-8000-000000000004',
    name: 'Speise',
    bereich: KategorieBereich.produkt,
    elternId: '10000000-0000-4000-8000-000000000001',
    istStandard: true,
  );
  static const ort = Kategorie(
    id: '20000000-0000-4000-8000-000000000001',
    name: 'Ort',
    bereich: KategorieBereich.ort,
    istStandard: true,
  );
  static const gastronomie = Kategorie(
    id: '20000000-0000-4000-8000-000000000002',
    name: 'Gastronomie',
    bereich: KategorieBereich.ort,
    elternId: '20000000-0000-4000-8000-000000000001',
    istStandard: true,
  );
  static const geschaeft = Kategorie(
    id: '20000000-0000-4000-8000-000000000003',
    name: 'Geschäft',
    bereich: KategorieBereich.ort,
    elternId: '20000000-0000-4000-8000-000000000001',
    istStandard: true,
  );

  static const alle = [produkt, getraenk, bier, speise, ort, gastronomie, geschaeft];
}
