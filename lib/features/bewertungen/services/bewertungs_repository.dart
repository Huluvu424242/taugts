import 'package:taugts/features/bewertungen/models/fachmodelle.dart';

abstract interface class BewertungsRepository {
  Future<void> speichereProdukt(Produkt produkt);
  Future<Produkt?> ladeProdukt(String id);
  Future<List<Produkt>> ladeProdukte({String suchtext = ''});
  Future<void> speichereOrt(Ort ort);
  Future<Ort?> ladeOrt(String id);
  Future<List<Ort>> ladeOrte({String suchtext = ''});
  Future<List<Ort>> findeAehnlicheOrte({
    required String name,
    String? adresse,
    String? ausgenommenId,
  });
  Future<void> speichereErlebnis(Erlebnis erlebnis);
  Future<Erlebnis?> ladeErlebnis(String id);
  Future<List<Erlebnis>> ladeErlebnisse();
  Future<List<Erlebnis>> ladeEntwuerfe();
  Future<void> loescheErlebnis(String id);
  Future<List<ErlebnispositionMitProdukt>> ladeErlebnispositionen(
    String erlebnisId,
  );
  Future<void> speichereErlebnisposition({
    required ErlebnisPosition position,
    Preisbeobachtung? preis,
  });
  Future<void> loescheErlebnisposition(String id);
  Future<Preisbeobachtung?> ladeLetztenPreis({
    required String produktId,
    required String waehrung,
  });
  Future<void> speichereKriterium(Bewertungskriterium kriterium);
  Future<void> sortiereKriterien(List<String> kriteriumIds);
  Future<bool> entferneKriterium(String kriteriumId);
  Future<List<Bewertungskriterium>> ladeKriterien({bool nurAktive = false});
  Future<List<Bewertungskriterium>> ladeAktiveKriterienFuerObjektart(
    KriteriumObjektart objektart,
  );
  Future<List<Bewertungskriterium>> ladeAktiveGetraenkekriterien();
  Future<List<Bewertungskriterium>> ladeAktiveKriterienFuerProduktart(
    Produktart produktart,
  );
  Future<void> speichereBewertung(Bewertung bewertung);
  Future<void> speichereGetraenkebewertung({
    required Erlebnis erlebnis,
    required List<Bewertung> bewertungen,
  });
  Future<void> speichereProduktbewertung({
    required Erlebnis erlebnis,
    required ErlebnisPosition position,
    required List<Bewertung> bewertungen,
  });
  Future<List<Bewertung>> ladeBewertungenFuerErlebnis(String erlebnisId);
  Future<List<Bewertung>> ladeBewertungenFuerErlebnisposition(
      String positionId);
  Future<List<Bewertung>> ladeBewertungenFuerProdukt(String produktId);
}
