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
  Future<void> speichereBewertung(Bewertung bewertung);
  Future<List<Bewertung>> ladeBewertungenFuerProdukt(String produktId);
}
