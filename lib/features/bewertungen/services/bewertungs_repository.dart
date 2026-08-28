import 'package:taugts/features/bewertungen/models/fachmodelle.dart';

abstract interface class BewertungsRepository {
  Future<void> speichereProdukt(Produkt produkt);
  Future<Produkt?> ladeProdukt(String id);
  Future<List<Produkt>> ladeProdukte();
  Future<void> speichereOrt(Ort ort);
  Future<void> speichereErlebnis(Erlebnis erlebnis);
  Future<void> speichereKriterium(Bewertungskriterium kriterium);
  Future<void> speichereBewertung(Bewertung bewertung);
  Future<List<Bewertung>> ladeBewertungenFuerProdukt(String produktId);
}
