import 'package:taugts/features/kategorien/models/klassifikation.dart';

abstract interface class KlassifikationsRepository {
  ObjektKlassifikation lade(String objektId);
  void setzeTags(String objektId, Iterable<String> tags);
  void entferneTag(String objektId, String tag);
  void setzeHerkunft(String objektId, String? wert);
  void setzeHersteller(String objektId, String? wert);
  void setzeEigenschaft(String objektId, String schluessel, String? wert);
  void entferneEigenschaft(String objektId, String schluessel);
}
