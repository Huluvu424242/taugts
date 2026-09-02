import 'package:taugts/features/datenaustausch/services/import_konfliktanalyse_service.dart';

enum ImportKonfliktArt {
  versionskonflikt,
  identitaetskonflikt,
  fachlicheDublette
}

enum ImportKonfliktAktion {
  lokaleVersion,
  importVersion,
  ueberspringen,
  beideBehalten,
  zusammenfuehren,
}

class ImportKonfliktUnterschied {
  const ImportKonfliktUnterschied({
    required this.feld,
    required this.lokal,
    required this.import,
  });

  final String feld;
  final Object? lokal;
  final Object? import;
}

class ImportKonfliktKontext {
  const ImportKonfliktKontext({
    this.objektId,
    this.erlebnisId,
    this.ortId,
    this.zeitpunkt,
  });

  final String? objektId;
  final String? erlebnisId;
  final String? ortId;
  final String? zeitpunkt;
}

class ImportEinzelKonflikt {
  const ImportEinzelKonflikt({
    required this.schluessel,
    required this.art,
    required this.sammlung,
    required this.importId,
    required this.lokaleId,
    required this.unterschiede,
    required this.kontext,
    required this.erlaubteAktionen,
  });

  final String schluessel;
  final ImportKonfliktArt art;
  final String sammlung;
  final String importId;
  final String lokaleId;
  final List<ImportKonfliktUnterschied> unterschiede;
  final ImportKonfliktKontext kontext;
  final Set<ImportKonfliktAktion> erlaubteAktionen;
}

class ImportKonfliktEntscheidungsStand {
  const ImportKonfliktEntscheidungsStand([this.entscheidungen = const {}]);

  final Map<String, ImportKonfliktAktion> entscheidungen;

  ImportKonfliktAktion? fuer(ImportEinzelKonflikt konflikt) =>
      entscheidungen[konflikt.schluessel];
}

class ImportKonfliktentscheidungService {
  const ImportKonfliktentscheidungService();

  static const _sammlungen = <String>[
    'profile',
    'objekte',
    'orte',
    'erlebnisse',
    'erlebnisPositionen',
    'preisbeobachtungen',
    'bewertungskriterien',
    'bewertungen',
    'ortsbewertungen',
    'kategorien',
  ];

  List<ImportEinzelKonflikt> ermittle({
    required Map<String, Object?> importDokument,
    required Map<String, Object?> lokalesDokument,
    required ImportKonfliktAnalyse analyse,
  }) {
    final konflikte = <ImportEinzelKonflikt>[];

    for (final sammlung in _sammlungen) {
      final importNachId = _nachId(_liste(importDokument, sammlung));
      final lokalNachId = _nachId(_liste(lokalesDokument, sammlung));
      for (final eintrag in importNachId.entries) {
        final lokal = lokalNachId[eintrag.key];
        if (lokal == null || _gleich(eintrag.value, lokal)) continue;
        final importWert = eintrag.value;
        final identitaetskonflikt = _istHistorisch(sammlung) &&
            !_gleicherHistorischerKontext(sammlung, importWert, lokal);
        final art = identitaetskonflikt
            ? ImportKonfliktArt.identitaetskonflikt
            : ImportKonfliktArt.versionskonflikt;
        konflikte.add(
          ImportEinzelKonflikt(
            schluessel: '$sammlung|${eintrag.key}|${eintrag.key}',
            art: art,
            sammlung: sammlung,
            importId: eintrag.key,
            lokaleId: eintrag.key,
            unterschiede: _unterschiede(lokal, importWert),
            kontext: _kontext(importWert, lokal),
            erlaubteAktionen: const {
              ImportKonfliktAktion.lokaleVersion,
              ImportKonfliktAktion.importVersion,
              ImportKonfliktAktion.ueberspringen,
            },
          ),
        );
      }
    }

    for (final dublette in analyse.fachlicheDubletten) {
      final importWert =
          _finde(importDokument, dublette.sammlung, dublette.importId);
      final lokal =
          _finde(lokalesDokument, dublette.sammlung, dublette.lokaleId);
      konflikte.add(
        ImportEinzelKonflikt(
          schluessel:
              '${dublette.sammlung}|${dublette.importId}|${dublette.lokaleId}',
          art: ImportKonfliktArt.fachlicheDublette,
          sammlung: dublette.sammlung,
          importId: dublette.importId,
          lokaleId: dublette.lokaleId,
          unterschiede: importWert == null || lokal == null
              ? const []
              : _unterschiede(lokal, importWert),
          kontext: _kontext(importWert, lokal),
          erlaubteAktionen: const {
            ImportKonfliktAktion.lokaleVersion,
            ImportKonfliktAktion.importVersion,
            ImportKonfliktAktion.ueberspringen,
            ImportKonfliktAktion.beideBehalten,
            ImportKonfliktAktion.zusammenfuehren,
          },
        ),
      );
    }

    return List.unmodifiable(konflikte);
  }

  ImportKonfliktEntscheidungsStand entscheide({
    required ImportKonfliktEntscheidungsStand stand,
    required ImportEinzelKonflikt konflikt,
    required ImportKonfliktAktion aktion,
    required List<ImportEinzelKonflikt> alleKonflikte,
    bool aufGleichenTypAnwenden = false,
  }) {
    if (!konflikt.erlaubteAktionen.contains(aktion)) {
      throw ArgumentError('Aktion ist für diesen Konflikt nicht zulässig.');
    }
    final neu = Map<String, ImportKonfliktAktion>.from(stand.entscheidungen);
    neu[konflikt.schluessel] = aktion;
    if (aufGleichenTypAnwenden) {
      for (final weiterer in alleKonflikte) {
        if (weiterer.art == konflikt.art &&
            weiterer.sammlung == konflikt.sammlung &&
            weiterer.erlaubteAktionen.contains(aktion)) {
          neu[weiterer.schluessel] = aktion;
        }
      }
    }
    return ImportKonfliktEntscheidungsStand(Map.unmodifiable(neu));
  }

  List<ImportKonfliktUnterschied> _unterschiede(
    Map<String, Object?> lokal,
    Map<String, Object?> import,
  ) {
    final keys = {...lokal.keys, ...import.keys}.toList()..sort();
    return List.unmodifiable([
      for (final key in keys)
        if (!_gleich(lokal[key], import[key]))
          ImportKonfliktUnterschied(
            feld: key,
            lokal: lokal[key],
            import: import[key],
          ),
    ]);
  }

  ImportKonfliktKontext _kontext(
    Map<String, Object?>? import,
    Map<String, Object?>? lokal,
  ) {
    String? ersterString(List<String> keys) {
      for (final key in keys) {
        final wert = import?[key] ?? lokal?[key];
        if (wert is String && wert.isNotEmpty) return wert;
      }
      return null;
    }

    return ImportKonfliktKontext(
      objektId: ersterString(const ['objektId', 'produktId']),
      erlebnisId: ersterString(const ['erlebnisId']),
      ortId: ersterString(const ['ortId']),
      zeitpunkt: ersterString(const [
        'bewertetAm',
        'beobachtetAm',
        'tatsaechlicherBeginn',
        'geplanterTag',
        'erstelltAm',
      ]),
    );
  }

  bool _istHistorisch(String sammlung) =>
      sammlung == 'erlebnisse' ||
      sammlung == 'erlebnisPositionen' ||
      sammlung == 'preisbeobachtungen' ||
      sammlung == 'bewertungen' ||
      sammlung == 'ortsbewertungen';

  bool _gleicherHistorischerKontext(
    String sammlung,
    Map<String, Object?> import,
    Map<String, Object?> lokal,
  ) {
    final keys = switch (sammlung) {
      'erlebnisse' => const ['ortId', 'tatsaechlicherBeginn', 'geplanterTag'],
      'erlebnisPositionen' => const ['erlebnisId', 'produktId'],
      'preisbeobachtungen' => const [
          'erlebnisId',
          'erlebnisPositionId',
          'produktId',
          'ortId',
          'beobachtetAm',
        ],
      'bewertungen' => const [
          'objektId',
          'erlebnisId',
          'erlebnisPositionId',
          'ortId',
          'bewertetAm',
        ],
      'ortsbewertungen' => const ['erlebnisId', 'ortId', 'bewertetAm'],
      _ => const <String>[],
    };
    return keys.every((key) => _gleich(import[key], lokal[key]));
  }

  Map<String, Object?>? _finde(
    Map<String, Object?> dokument,
    String sammlung,
    String id,
  ) =>
      _nachId(_liste(dokument, sammlung))[id];

  Map<String, Map<String, Object?>> _nachId(List<Map<String, Object?>> werte) =>
      {
        for (final wert in werte)
          if (wert['id'] is String) wert['id'] as String: wert,
      };

  List<Map<String, Object?>> _liste(
          Map<String, Object?> dokument, String name) =>
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
