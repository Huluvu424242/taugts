import 'package:taugts/features/kategorien/models/kategorie.dart';

abstract interface class KategorieRepository {
  List<Kategorie> alle();
  Kategorie? finde(String id);
  void speichern(Kategorie kategorie);
  void umbenennen(String id, String name);
  void verschieben(String id, String? elternId);
  void ordneProduktZu(String produktId, String kategorieId);
  void ordneOrtZu(String ortId, String kategorieId);
  Set<String> kategorienFuerProdukt(String produktId);
  Set<String> kategorienFuerOrt(String ortId);
  void entfernen(String id);
}

class KategorieInBenutzungException implements Exception {
  const KategorieInBenutzungException(this.id);
  final String id;
}

class UngueltigeKategorieHierarchieException implements Exception {
  const UngueltigeKategorieHierarchieException(this.nachricht);
  final String nachricht;
}
