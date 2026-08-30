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
  Future<List<Erlebnis>> ladeEntwuerfe();
  Future<void> loescheErlebnis(String id);
  Future<void> speichereKriterium(Bewertungskriterium kriterium);
  Future<List<Bewertungskriterium>> ladeAktiveGetraenkekriterien();
  Future<void> speichereBewertung(Bewertung bewertung);
  Future<void> speichereGetraenkebewertung({
    required Erlebnis erlebnis,
    required List<Bewertung> bewertungen,
  });
  Future<List<Bewertung>> ladeBewertungenFuerErlebnis(String erlebnisId);
  Future<List<Bewertung>> ladeBewertungenFuerProdukt(String produktId);
}
