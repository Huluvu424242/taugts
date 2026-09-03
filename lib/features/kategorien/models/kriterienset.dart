import 'package:taugts/features/bewertungen/models/fachmodelle.dart';

enum KriteriensetModus { erweitern, ersetzen }

class KategorieKriteriensetRegel {
  const KategorieKriteriensetRegel({
    required this.kategorieId,
    required this.fallbackObjektart,
    this.modus = KriteriensetModus.erweitern,
    this.version = 1,
  });

  final String kategorieId;
  final KriteriumObjektart fallbackObjektart;
  final KriteriensetModus modus;
  final int version;
}

class KategorieKriteriumZuordnung {
  const KategorieKriteriumZuordnung({
    required this.kategorieId,
    required this.kriteriumId,
    required this.reihenfolge,
  });

  final String kategorieId;
  final String kriteriumId;
  final int reihenfolge;
}

class WirksamesKriterium {
  const WirksamesKriterium({
    required this.kriterium,
    required this.quelle,
    required this.geerbt,
  });

  final Bewertungskriterium kriterium;
  final String quelle;
  final bool geerbt;
}

class WirksamesKriterienset {
  const WirksamesKriterienset({
    required this.kategorieId,
    required this.fallbackObjektart,
    required this.version,
    required this.eintraege,
  });

  final String kategorieId;
  final KriteriumObjektart fallbackObjektart;
  final int version;
  final List<WirksamesKriterium> eintraege;
}
