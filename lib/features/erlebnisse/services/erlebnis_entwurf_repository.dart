import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';

/// Bearbeitungszustand eines Erlebnisses. Keine der Erlebnis-Unteraktionen
/// verändert die Datenbank vor der ausdrücklichen Gesamt-Speicheraktion.
class ErlebnisEntwurfRepository
    implements BewertungsRepository, StammdatenLoeschRepository {
  ErlebnisEntwurfRepository(this.basis, this.erlebnisId);

  final BewertungsRepository basis;

  @override
  Future<void> loescheProdukt(String id) async {
    final verwaltung = basis;
    if (verwaltung is! StammdatenLoeschRepository) {
      throw UnsupportedError('Produktlöschung nicht verfügbar');
    }
    await (verwaltung as StammdatenLoeschRepository).loescheProdukt(id);
  }

  @override
  Future<void> loescheOrt(String id) async {
    final verwaltung = basis;
    if (verwaltung is! StammdatenLoeschRepository) {
      throw UnsupportedError('Ortslöschung nicht verfügbar');
    }
    await (verwaltung as StammdatenLoeschRepository).loescheOrt(id);
  }

  final String erlebnisId;
  Erlebnis? _erlebnis;
  final _positionen = <String, ErlebnispositionMitProdukt>{};
  final _entferntePositionen = <String>{};
  final _produktbewertungen = <String, List<Bewertung>>{};
  OrtsbewertungMitWerten? _ortsbewertung;
  bool _ortsbewertungGeaendert = false;
  List<Bewertung>? _legacyBewertungen;

  @override
  Future<void> speichereErlebnis(Erlebnis erlebnis) async {
    if (erlebnis.id != erlebnisId) throw ArgumentError('Falsches Erlebnis');
    _erlebnis = erlebnis;
  }

  @override
  Future<Erlebnis?> ladeErlebnis(String id) =>
      id == erlebnisId && _erlebnis != null
          ? Future.value(_erlebnis)
          : basis.ladeErlebnis(id);

  @override
  Future<List<ErlebnispositionMitProdukt>> ladeErlebnispositionen(
    String id,
  ) async {
    final vorhanden = await basis.ladeErlebnispositionen(id);
    if (id != erlebnisId) return vorhanden;
    final ergebnis = <String, ErlebnispositionMitProdukt>{
      for (final eintrag in vorhanden)
        if (!_entferntePositionen.contains(eintrag.position.id))
          eintrag.position.id: eintrag,
      ..._positionen,
    };
    return ergebnis.values.toList();
  }

  @override
  Future<void> speichereErlebnisposition({
    required ErlebnisPosition position,
    Preisbeobachtung? preis,
  }) async {
    if (position.erlebnisId != erlebnisId || position.anzahl < 1) {
      throw ArgumentError('Ungültige Erlebnisposition');
    }
    final produkt = await basis.ladeProdukt(position.produktId);
    final alte = (await ladeErlebnispositionen(erlebnisId))
        .where((eintrag) => eintrag.position.id == position.id);
    if (produkt == null && alte.isEmpty) {
      throw ArgumentError('Produkt nicht gefunden');
    }
    _entferntePositionen.remove(position.id);
    _positionen[position.id] = ErlebnispositionMitProdukt(
      position: position,
      produkt: produkt ?? alte.first.produkt,
      preis: preis,
    );
  }

  @override
  Future<void> loescheErlebnisposition(String id) async {
    _positionen.remove(id);
    _produktbewertungen.remove(id);
    _entferntePositionen.add(id);
  }

  @override
  Future<void> speichereProduktbewertung({
    required Erlebnis erlebnis,
    required ErlebnisPosition position,
    required List<Bewertung> bewertungen,
  }) async {
    if (erlebnis.id != erlebnisId ||
        position.erlebnisId != erlebnisId ||
        bewertungen.any((wert) =>
            wert.erlebnisPositionId != position.id ||
            wert.erlebnisId != erlebnisId)) {
      throw ArgumentError('Produktbewertung gehört nicht zum Erlebnis');
    }
    _produktbewertungen[position.id] = List.of(bewertungen);
  }

  @override
  Future<List<Bewertung>> ladeBewertungenFuerErlebnisposition(
    String positionId,
  ) =>
      _produktbewertungen.containsKey(positionId)
          ? Future.value(List.of(_produktbewertungen[positionId]!))
          : basis.ladeBewertungenFuerErlebnisposition(positionId);

  @override
  Future<void> speichereOrtsbewertung({
    required Erlebnis erlebnis,
    required Ort ort,
    required Ortsbewertung ortsbewertung,
    required List<Bewertung> bewertungen,
  }) async {
    if (erlebnis.id != erlebnisId ||
        ortsbewertung.erlebnisId != erlebnisId ||
        ort.id != ortsbewertung.ortId) {
      throw ArgumentError('Ortsbewertung gehört nicht zum Erlebnis');
    }
    _ortsbewertung = OrtsbewertungMitWerten(
      ortsbewertung: ortsbewertung,
      werte: List.of(bewertungen),
    );
    _ortsbewertungGeaendert = true;
  }

  @override
  Future<OrtsbewertungMitWerten?> ladeOrtsbewertungFuerErlebnis(
    String id,
  ) =>
      id == erlebnisId && _ortsbewertungGeaendert
          ? Future.value(_ortsbewertung)
          : basis.ladeOrtsbewertungFuerErlebnis(id);

  @override
  Future<void> speichereGetraenkebewertung({
    required Erlebnis erlebnis,
    required List<Bewertung> bewertungen,
  }) async {
    if (erlebnis.id != erlebnisId) throw ArgumentError('Falsches Erlebnis');
    _legacyBewertungen = List.of(bewertungen);
  }

  @override
  Future<List<Bewertung>> ladeBewertungenFuerErlebnis(String id) =>
      id == erlebnisId && _legacyBewertungen != null
          ? Future.value(List.of(_legacyBewertungen!))
          : basis.ladeBewertungenFuerErlebnis(id);

  Future<void> uebernehmen(Erlebnis erlebnis) async {
    final repository = basis;
    if (repository is! ErlebnisGesamtstandRepository) {
      throw StateError('Gemeinsame Transaktionsspeicherung nicht verfügbar.');
    }
    await (repository as ErlebnisGesamtstandRepository)
        .speichereErlebnisGesamtstand(
      erlebnis: erlebnis,
      geaendertePositionen: _positionen.values.toList(),
      entferntePositionen: _entferntePositionen,
      produktbewertungen: _produktbewertungen,
      ortsbewertung: _ortsbewertungGeaendert ? _ortsbewertung : null,
      legacyBewertungen: _legacyBewertungen,
    );
    _positionen.clear();
    _entferntePositionen.clear();
    _produktbewertungen.clear();
    _ortsbewertung = null;
    _ortsbewertungGeaendert = false;
    _legacyBewertungen = null;
    _erlebnis = erlebnis;
  }

  @override
  Future<void> speichereProdukt(Produkt produkt) =>
      basis.speichereProdukt(produkt);

  @override
  Future<Produkt?> ladeProdukt(String id) => basis.ladeProdukt(id);

  @override
  Future<List<Produkt>> ladeProdukte({String suchtext = ''}) =>
      basis.ladeProdukte(suchtext: suchtext);

  @override
  Future<Produkt?> ladeProduktMitBarcode(String barcode) =>
      basis.ladeProduktMitBarcode(barcode);

  @override
  Future<void> speichereOrt(Ort ort) => basis.speichereOrt(ort);

  @override
  Future<Ort?> ladeOrt(String id) => basis.ladeOrt(id);

  @override
  Future<List<Ort>> ladeOrte({String suchtext = ''}) =>
      basis.ladeOrte(suchtext: suchtext);

  @override
  Future<List<Ort>> findeAehnlicheOrte({
    required String name,
    String? adresse,
    String? ausgenommenId,
  }) =>
      basis.findeAehnlicheOrte(
          name: name, adresse: adresse, ausgenommenId: ausgenommenId);

  @override
  Future<List<Erlebnis>> ladeErlebnisse() => basis.ladeErlebnisse();

  @override
  Future<void> loescheErlebnis(String id) => basis.loescheErlebnis(id);

  @override
  Future<Preisbeobachtung?> ladeLetztenPreis({
    required String produktId,
    required String waehrung,
  }) =>
      basis.ladeLetztenPreis(produktId: produktId, waehrung: waehrung);

  @override
  Future<void> speichereKriterium(Bewertungskriterium kriterium) =>
      basis.speichereKriterium(kriterium);

  @override
  Future<void> sortiereKriterien(List<String> kriteriumIds) =>
      basis.sortiereKriterien(kriteriumIds);

  @override
  Future<bool> entferneKriterium(String kriteriumId) =>
      basis.entferneKriterium(kriteriumId);

  @override
  Future<List<Bewertungskriterium>> ladeKriterien({bool nurAktive = false}) =>
      basis.ladeKriterien(nurAktive: nurAktive);

  @override
  Future<List<Bewertungskriterium>> ladeAktiveKriterienFuerObjektart(
    KriteriumObjektart objektart,
  ) =>
      basis.ladeAktiveKriterienFuerObjektart(objektart);

  @override
  Future<List<Bewertungskriterium>> ladeAktiveGetraenkekriterien() =>
      basis.ladeAktiveGetraenkekriterien();

  @override
  Future<List<Bewertungskriterium>> ladeAktiveKriterienFuerProduktart(
    Produktart produktart,
  ) =>
      basis.ladeAktiveKriterienFuerProduktart(produktart);

  @override
  Future<void> speichereBewertung(Bewertung bewertung) =>
      basis.speichereBewertung(bewertung);

  @override
  Future<List<Bewertung>> ladeBewertungenFuerProdukt(String produktId) =>
      basis.ladeBewertungenFuerProdukt(produktId);

  @override
  Future<List<BewertungsverlaufEintrag>> ladeProduktverlauf(String produktId) =>
      basis.ladeProduktverlauf(produktId);

  @override
  Future<List<BewertungsverlaufEintrag>> ladeOrtsverlauf(String ortId) =>
      basis.ladeOrtsverlauf(ortId);
}
