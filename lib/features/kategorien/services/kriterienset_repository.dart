import 'package:taugts/features/kategorien/models/kriterienset.dart';

abstract interface class KriteriensetRepository {
  KategorieKriteriensetRegel? regelFuer(String kategorieId);
  List<KategorieKriteriumZuordnung> zuordnungenFuer(String kategorieId);
  void speichereRegel(KategorieKriteriensetRegel regel);
  void setzeZuordnungen(
    String kategorieId,
    Iterable<String> kriteriumIds,
  );
}
