import 'package:taugts/features/datenaustausch/services/import_konfliktentscheidung_service.dart';

enum ImportStrategie { bestandErsetzen, importBevorzugen, lokalBevorzugen }

class ImportStrategieSammlung {
  const ImportStrategieSammlung({
    required this.name,
    required this.hinzufuegen,
    required this.aktualisieren,
    required this.behalten,
    required this.entfernen,
    this.unveraendert = 0,
    this.uebersprungen = 0,
  });

  final String name;
  final int hinzufuegen;
  final int aktualisieren;
  final int behalten;
  final int entfernen;
  final int unveraendert;
  final int uebersprungen;
}

class ImportIdentitaetsKonflikt {
  const ImportIdentitaetsKonflikt({
    required this.sammlung,
    required this.id,
    required this.nachricht,
  });

  final String sammlung;
  final String id;
  final String nachricht;
}

class ImportStrategiePlan {
  const ImportStrategiePlan({
    required this.strategie,
    required this.sammlungen,
    required this.identitaetsKonflikte,
    required this.fachlicheDubletten,
  });

  final ImportStrategie strategie;
  final List<ImportStrategieSammlung> sammlungen;
  final List<ImportIdentitaetsKonflikt> identitaetsKonflikte;
  final List<FachlicheDubletteHinweis> fachlicheDubletten;

  bool get hatKonflikte => identitaetsKonflikte.isNotEmpty;
}

class FachlicheDubletteHinweis {
  const FachlicheDubletteHinweis({
    required this.sammlung,
    required this.importId,
    required this.lokaleId,
  });

  final String sammlung;
  final String importId;
  final String lokaleId;
}

class ImportStrategieService {
  const ImportStrategieService();

  static const _sammlungen = <String>[
    'profile',
    'objekte',
    'orte',
    'kategorien',
    'bewertungskriterien',
    'erlebnisse',
    'erlebnisPositionen',
    'preisbeobachtungen',
    'ortsbewertungen',
    'bewertungen',
    'kategorien',
    'kategorieZuordnungen',
    'objektTags',
    'objektKlassifikationsmerkmale',
    'kategorieKriteriensetRegeln',
    'kategorieKriterien',
  ];

  ImportStrategiePlan plane({
    required ImportStrategie strategie,
    required Map<String, Object?> importDokument,
    required Map<String, Object?> lokalesDokument,
    Iterable<FachlicheDubletteHinweis> fachlicheDubletten = const [],
    ImportKonfliktEntscheidungsStand entscheidungen =
        const ImportKonfliktEntscheidungsStand(),
  }) {
    final ergebnisse = <ImportStrategieSammlung>[];
    final konflikte = <ImportIdentitaetsKonflikt>[];

    for (final sammlung in _sammlungen) {
      final importWerte = _liste(importDokument, sammlung);
      final lokaleWerte = _liste(lokalesDokument, sammlung);
      final importNachId = _nachId(sammlung, importWerte);
      final lokalNachId = _nachId(sammlung, lokaleWerte);

      var hinzufuegen = 0;
      var aktualisieren = 0;
      var behalten = 0;
      var entfernen = 0;
      var unveraendert = 0;
      var uebersprungen = 0;

      for (final eintrag in importNachId.entries) {
        final lokal = lokalNachId[eintrag.key];
        if (lokal == null) {
          final aktion = entscheidungen
              .entscheidungen['$sammlung|${eintrag.key}|${eintrag.key}'];
          if (aktion == ImportKonfliktAktion.ueberspringen &&
              strategie != ImportStrategie.bestandErsetzen) {
            uebersprungen++;
          } else {
            hinzufuegen++;
          }
          continue;
        }
        if (_gleich(eintrag.value, lokal)) {
          unveraendert++;
          behalten++;
          uebersprungen++;
          continue;
        }
        final konflikt = _identitaetsKonflikt(sammlung, eintrag.value, lokal);
        if (konflikt != null) konflikte.add(konflikt);
        final aktion = entscheidungen
            .entscheidungen['$sammlung|${eintrag.key}|${eintrag.key}'];
        if (strategie == ImportStrategie.bestandErsetzen) {
          aktualisieren++;
        } else if (aktion == ImportKonfliktAktion.lokaleVersion ||
            aktion == ImportKonfliktAktion.ueberspringen) {
          behalten++;
          uebersprungen++;
        } else if (aktion == ImportKonfliktAktion.importVersion ||
            strategie == ImportStrategie.importBevorzugen) {
          aktualisieren++;
        } else {
          behalten++;
          uebersprungen++;
        }
      }

      for (final lokaleId in lokalNachId.keys) {
        if (importNachId.containsKey(lokaleId)) continue;
        if (strategie == ImportStrategie.bestandErsetzen) {
          entfernen++;
        } else {
          behalten++;
        }
      }

      ergebnisse.add(
        ImportStrategieSammlung(
          name: sammlung,
          hinzufuegen: hinzufuegen,
          aktualisieren: aktualisieren,
          behalten: behalten,
          entfernen: entfernen,
          unveraendert: unveraendert,
          uebersprungen: uebersprungen,
        ),
      );
    }

    return ImportStrategiePlan(
      strategie: strategie,
      sammlungen: List.unmodifiable(ergebnisse),
      identitaetsKonflikte: List.unmodifiable(konflikte),
      fachlicheDubletten: List.unmodifiable(fachlicheDubletten),
    );
  }

  ImportIdentitaetsKonflikt? _identitaetsKonflikt(
    String sammlung,
    Map<String, Object?> importWert,
    Map<String, Object?> lokalerWert,
  ) {
    if (!_historischeSammlung(sammlung)) return null;
    final importBezug = _historischerBezug(sammlung, importWert);
    final lokalerBezug = _historischerBezug(sammlung, lokalerWert);
    if (_gleich(importBezug, lokalerBezug)) return null;
    return ImportIdentitaetsKonflikt(
      sammlung: sammlung,
      id: importWert['id'] as String,
      nachricht:
          'Dieselbe stabile ID verweist auf einen anderen historischen Kontext.',
    );
  }

  bool _historischeSammlung(String sammlung) =>
      sammlung == 'erlebnisse' ||
      sammlung == 'erlebnisPositionen' ||
      sammlung == 'preisbeobachtungen' ||
      sammlung == 'ortsbewertungen' ||
      sammlung == 'bewertungen';

  Map<String, Object?> _historischerBezug(
    String sammlung,
    Map<String, Object?> wert,
  ) {
    const schluessel = <String>[
      'objektId',
      'produktId',
      'ortId',
      'erlebnisId',
      'erlebnisPositionId',
      'ortsbewertungId',
      'herkunftProfilId',
      'bewertetAm',
      'beobachtetAm',
      'beginn',
      'ende',
    ];
    return {
      for (final key in schluessel)
        if (wert.containsKey(key)) key: wert[key],
    };
  }

  Map<String, Map<String, Object?>> _nachId(
    String sammlung,
    List<Map<String, Object?>> werte,
  ) =>
      {
        for (final wert in werte)
          if (_identitaet(sammlung, wert).isNotEmpty)
            _identitaet(sammlung, wert): wert,
      };

  String _identitaet(String sammlung, Map<String, Object?> wert) =>
      switch (sammlung) {
        'kategorieZuordnungen' => '${wert['kategorieId']}:${wert['zielId']}',
        'objektTags' => '${wert['objektId']}:${wert['normalisiert']}',
        'objektKlassifikationsmerkmale' =>
          '${wert['objektId']}:${wert['dimension']}:${wert['schluessel']}',
        'kategorieKriteriensetRegeln' => '${wert['kategorieId']}',
        'kategorieKriterien' => '${wert['kategorieId']}:${wert['kriteriumId']}',
        _ => wert['id'] as String? ?? '',
      };

  List<Map<String, Object?>> _liste(
    Map<String, Object?> dokument,
    String name,
  ) =>
      ((dokument[name] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, Object?>.from(e))
          .toList();

  bool _gleich(Object? a, Object? b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_gleich(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_gleich(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }
}
