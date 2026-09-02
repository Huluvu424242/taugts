import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/datenaustausch/services/import_dubletten_merge_service.dart';

class ImportAliasRepository {
  const ImportAliasRepository();

  void stelleTabelleBereit(LokaleDatenbank datenbank) {
    datenbank.verbindung.execute('''
      CREATE TABLE IF NOT EXISTS import_aliases (
        sammlung TEXT NOT NULL,
        alias_id TEXT NOT NULL,
        kanonische_id TEXT NOT NULL,
        erstellt_am TEXT NOT NULL,
        PRIMARY KEY (sammlung, alias_id),
        CHECK (sammlung IN ('objekte', 'orte')),
        CHECK (alias_id <> kanonische_id)
      )
    ''');
  }

  List<ImportAliasReferenz> lade(LokaleDatenbank datenbank) {
    stelleTabelleBereit(datenbank);
    return datenbank.verbindung
        .select(
          'SELECT sammlung, alias_id, kanonische_id '
          'FROM import_aliases ORDER BY sammlung, alias_id',
        )
        .map(
          (zeile) => ImportAliasReferenz(
            sammlung: zeile['sammlung'] as String,
            aliasId: zeile['alias_id'] as String,
            kanonischeId: zeile['kanonische_id'] as String,
          ),
        )
        .toList(growable: false);
  }

  void speichere(
    LokaleDatenbank datenbank,
    ImportAliasReferenz alias, {
    DateTime? erstelltAm,
  }) {
    _pruefeSammlung(alias.sammlung);
    if (alias.aliasId == alias.kanonischeId) {
      throw ArgumentError('Alias und kanonische ID müssen verschieden sein.');
    }
    stelleTabelleBereit(datenbank);
    final vorhanden = datenbank.verbindung.select(
      'SELECT kanonische_id FROM import_aliases '
      'WHERE sammlung = ? AND alias_id = ?',
      [alias.sammlung, alias.aliasId],
    );
    if (vorhanden.isNotEmpty) {
      final bisher = vorhanden.single['kanonische_id'] as String;
      if (bisher == alias.kanonischeId) return;
      throw StateError(
        'Alias ${alias.aliasId} ist bereits auf $bisher abgebildet.',
      );
    }

    final aliases = [...lade(datenbank), alias];
    kanonischeIdFuer(
      sammlung: alias.sammlung,
      id: alias.aliasId,
      aliases: aliases,
    );
    datenbank.verbindung.execute(
      'INSERT INTO import_aliases '
      '(sammlung, alias_id, kanonische_id, erstellt_am) VALUES (?, ?, ?, ?)',
      [
        alias.sammlung,
        alias.aliasId,
        alias.kanonischeId,
        (erstelltAm ?? DateTime.now()).toUtc().toIso8601String(),
      ],
    );
  }

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

  Map<String, Object?> normalisiereDokument(
    LokaleDatenbank datenbank,
    Map<String, Object?> dokument,
  ) {
    final aliases = lade(datenbank);
    if (aliases.isEmpty) return _tiefeKopie(dokument);
    final normalisiert = _tiefeKopie(dokument);

    for (final alias in aliases) {
      final ziel = kanonischeIdFuer(
        sammlung: alias.sammlung,
        id: alias.aliasId,
        aliases: aliases,
      );
      _idErsetzen(normalisiert, alias.sammlung, alias.aliasId, ziel);
      _referenzenUmschreiben(
        dokument: normalisiert,
        sammlung: alias.sammlung,
        vonId: alias.aliasId,
        aufId: ziel,
      );
    }
    _dublettenNachIdEntfernen(normalisiert, 'objekte');
    _dublettenNachIdEntfernen(normalisiert, 'orte');
    return normalisiert;
  }

  void _pruefeSammlung(String sammlung) {
    if (sammlung != 'objekte' && sammlung != 'orte') {
      throw ArgumentError('Alias-Sammlung $sammlung wird nicht unterstützt.');
    }
  }

  void _idErsetzen(
    Map<String, Object?> dokument,
    String sammlung,
    String vonId,
    String aufId,
  ) {
    final werte = _liste(dokument, sammlung);
    for (final wert in werte) {
      if (wert['id'] == vonId) wert['id'] = aufId;
    }
    dokument[sammlung] = werte;
  }

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
      _ersetze(dokument, 'bewertungen', 'objektId', vonId, aufId);
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

  void _dublettenNachIdEntfernen(
    Map<String, Object?> dokument,
    String sammlung,
  ) {
    final nachId = <String, Map<String, Object?>>{};
    final ohneId = <Map<String, Object?>>[];
    for (final wert in _liste(dokument, sammlung)) {
      final id = wert['id'];
      if (id is String) {
        nachId[id] = wert;
      } else {
        ohneId.add(wert);
      }
    }
    dokument[sammlung] = [...nachId.values, ...ohneId];
  }

  List<Map<String, Object?>> _liste(
    Map<String, Object?> dokument,
    String name,
  ) =>
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
