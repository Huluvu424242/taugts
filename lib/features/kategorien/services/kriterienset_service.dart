import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/kategorien/models/kriterienset.dart';
import 'package:taugts/features/kategorien/services/kategorie_repository.dart';
import 'package:taugts/features/kategorien/services/kriterienset_repository.dart';

class KriteriensetService {
  const KriteriensetService({
    required this.kategorien,
    required this.kriteriensets,
    required this.bewertungen,
  });

  final KategorieRepository kategorien;
  final KriteriensetRepository kriteriensets;
  final BewertungsRepository bewertungen;

  Future<WirksamesKriterienset> ermittle({
    required String kategorieId,
    required KriteriumObjektart fallbackObjektart,
  }) async {
    final alleKriterien = await bewertungen.ladeKriterien(nurAktive: true);
    final nachId = {for (final kriterium in alleKriterien) kriterium.id: kriterium};
    final pfad = _pfad(kategorieId);
    final wirksam = <String, WirksamesKriterium>{};
    var wirksamerFallback = fallbackObjektart;
    var versionsSignatur = 17;

    for (final kriterium in alleKriterien.where(
      (wert) => wert.wirksameObjektart == fallbackObjektart,
    )) {
      wirksam[kriterium.id] = WirksamesKriterium(
        kriterium: kriterium,
        quelle: 'Standard ${_objektartLabel(fallbackObjektart)}',
        geerbt: true,
      );
    }

    for (final kategorie in pfad) {
      final regel = kriteriensets.regelFuer(kategorie.id);
      if (regel == null) continue;
      wirksamerFallback = regel.fallbackObjektart;
      versionsSignatur = versionsSignatur * 31 + regel.version;
      if (regel.modus == KriteriensetModus.ersetzen) {
        wirksam.clear();
      }
      for (final zuordnung in kriteriensets.zuordnungenFuer(kategorie.id)) {
        final kriterium = nachId[zuordnung.kriteriumId];
        if (kriterium == null) continue;
        wirksam[kriterium.id] = WirksamesKriterium(
          kriterium: kriterium,
          quelle: kategorie.name,
          geerbt: kategorie.id != kategorieId,
        );
      }
    }

    final eintraege = wirksam.values.toList()
      ..sort((a, b) {
        final reihenfolge =
            a.kriterium.reihenfolge.compareTo(b.kriterium.reihenfolge);
        return reihenfolge != 0
            ? reihenfolge
            : a.kriterium.name.compareTo(b.kriterium.name);
      });
    return WirksamesKriterienset(
      kategorieId: kategorieId,
      fallbackObjektart: wirksamerFallback,
      version: versionsSignatur.abs(),
      eintraege: eintraege,
    );
  }

  List<dynamic> _pfad(String kategorieId) {
    final pfad = <dynamic>[];
    final besucht = <String>{};
    var aktuell = kategorien.finde(kategorieId);
    while (aktuell != null && besucht.add(aktuell.id)) {
      pfad.add(aktuell);
      final elternId = aktuell.elternId;
      aktuell = elternId == null ? null : kategorien.finde(elternId);
    }
    return pfad.reversed.toList(growable: false);
  }

  String _objektartLabel(KriteriumObjektart art) => switch (art) {
        KriteriumObjektart.getraenk => 'Getränk',
        KriteriumObjektart.speise => 'Speise',
        KriteriumObjektart.sonstigesProdukt => 'Produkt',
        KriteriumObjektart.gastronomie => 'Gastronomie',
        KriteriumObjektart.geschaeft => 'Geschäft',
      };
}
