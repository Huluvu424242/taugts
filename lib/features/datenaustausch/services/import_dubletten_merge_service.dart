enum DublettenFeldQuelle { lokal, import }

class DublettenFeldAuswahl {
  const DublettenFeldAuswahl({required this.feld, required this.quelle});

  final String feld;
  final DublettenFeldQuelle quelle;
}

class ImportAliasReferenz {
  const ImportAliasReferenz({
    required this.sammlung,
    required this.aliasId,
    required this.kanonischeId,
  });

  final String sammlung;
  final String aliasId;
  final String kanonischeId;
}

class ImportDublettenMergeErgebnis {
  const ImportDublettenMergeErgebnis({
    required this.dokument,
    required this.alias,
  });

  final Map<String, Object?> dokument;
  final ImportAliasReferenz alias;
}

class ImportDublettenMergeService {
  const ImportDublettenMergeService();

  String kanonischeIdFuer({
    required String sammlung,
    required String id,
    required Iterable<ImportAliasReferenz> aliases,
  }) {
    var aktuell = id;
    final besucht = <String>{};
    while (besucht.add(aktuell)) {
      ImportAliasReferenz? treffer;
      for (final alias in aliases) {
        if (alias.sammlung == sammlung && alias.aliasId == aktuell) {
          treffer = alias;
          break;
        }
      }
      if (treffer == null) return aktuell;
      aktuell = treffer.kanonischeId;
    }
    throw StateError('Zyklische Aliasreferenz für $sammlung/$id.');
  }

  ImportDublettenMergeErgebnis plane({
    required String sammlung,
    required String importId,
    required String lokaleId,
    required Map<String, Object?> importDokument,
    required Map<String, Object?> lokalesDokument,
    required Map<String, DublettenFeldQuelle> feldauswahl,
  }) {
    if (!_unterstuetzteSammlung(sammlung)) {
      throw ArgumentError('Zusammenführen wird für $sammlung nicht unterstützt.');
    }
    final importWert = _finde(importDokument, sammlung, importId);
    final lokalWert = _finde(lokalesDokument, sammlung, lokaleId);
    if (importWert == null || lokalWert == null) {
      throw ArgumentError('Beide Dubletten müssen vorhanden sein.');
    }

    final dokument = _tiefeKopie(importDokument);
    final sammlungsListe = _liste(dokument, sammlung);
    final index = sammlungsListe.indexWhere((wert) => wert['id'] == importId);
    final zusammengefuehrt = Map<String, Object?>.from(importWert);
    for (final feld in {...importWert.keys, ...lokalWert.keys}) {
      if (feld == 'id') continue;
      final quelle = feldauswahl[feld] ?? DublettenFeldQuelle.lokal;
      zusammengefuehrt[feld] =
          quelle == DublettenFeldQuelle.import ? importWert[feld] : lokalWert[feld];
    }
    zusammengefuehrt['id'] = lokaleId;
    if (index >= 0) {
      sammlungsListe[index] = zusammengefuehrt;
    }
    dokument[sammlung] = sammlungsListe;

    _referenzenUmschreiben(
      dokument: dokument,
      sammlung: sammlung,
      vonId: importId,
      aufId: lokaleId,
    );

    return ImportDublettenMergeErgebnis(
      dokument: dokument,
      alias: ImportAliasReferenz(
        sammlung: sammlung,
        aliasId: importId,
        kanonischeId: lokaleId,
      ),
    );
  }

  bool _unterstuetzteSammlung(String sammlung) =>
      sammlung == 'objekte' || sammlung == 'orte';

  void _referenzenUmschreiben({
    required Map<String, Object?> dokument,
    required String sammlung,
    required String vonId,
    required String aufId,
  }) {
    if (sammlung == 'objekte') {
      _ersetze(dokument, 'erlebnisPositionen', 'produktId', vonId, aufId);
      _ersetze(dokument, 'preisbeobachtungen', 'produktId', vonId, aufId);
      _ersetze(dokument, 'bewertungen', 'objektId', vonId, aufId);
      _ersetze(dokument, 'kategorieZuordnungen', 'zielId', vonId, aufId);
    } else if (sammlung == 'orte') {
      _ersetze(dokument, 'erlebnisse', 'ortId', vonId, aufId);
      _ersetze(dokument, 'preisbeobachtungen', 'ortId', vonId, aufId);
      _ersetze(dokument, 'bewertungen', 'ortId', vonId, aufId);
      _ersetze(dokument, 'ortsbewertungen', 'ortId', vonId, aufId);
    }
  }

  void _ersetze(
    Map<String, Object?> dokument,
    String sammlung,
    String feld,
    String vonId,
    String aufId,
  ) {
    final werte = _liste(dokument, sammlung);
    for (final wert in werte) {
      if (wert[feld] == vonId) wert[feld] = aufId;
    }
    dokument[sammlung] = werte;
  }

  Map<String, Object?>? _finde(
    Map<String, Object?> dokument,
    String sammlung,
    String id,
  ) {
    for (final wert in _liste(dokument, sammlung)) {
      if (wert['id'] == id) return wert;
    }
    return null;
  }

  List<Map<String, Object?>> _liste(Map<String, Object?> dokument, String name) =>
      ((dokument[name] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, Object?>.from(e))
          .toList();

  Map<String, Object?> _tiefeKopie(Map<String, Object?> dokument) => {
        for (final eintrag in dokument.entries)
          eintrag.key: _kopiereWert(eintrag.value),
      };

  Object? _kopiereWert(Object? wert) {
    if (wert is Map) {
      return {
        for (final eintrag in wert.entries)
          eintrag.key.toString(): _kopiereWert(eintrag.value),
      };
    }
    if (wert is List) return wert.map(_kopiereWert).toList();
    return wert;
  }
}
