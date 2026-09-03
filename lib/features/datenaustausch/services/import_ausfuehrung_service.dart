import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/datenaustausch/services/import_alias_repository.dart';
import 'package:taugts/features/datenaustausch/services/import_dubletten_merge_service.dart';
import 'package:taugts/features/datenaustausch/services/import_konfliktentscheidung_service.dart';
import 'package:taugts/features/datenaustausch/services/import_protokoll_repository.dart';
import 'package:taugts/features/datenaustausch/services/import_strategie_service.dart';

class ImportErgebnisZaehler {
  const ImportErgebnisZaehler({
    this.hinzugefuegt = 0,
    this.aktualisiert = 0,
    this.uebersprungen = 0,
    this.zusammengefuehrt = 0,
    this.fehlerhaft = 0,
  });

  final int hinzugefuegt;
  final int aktualisiert;
  final int uebersprungen;
  final int zusammengefuehrt;
  final int fehlerhaft;

  ImportErgebnisZaehler plus({
    int hinzugefuegt = 0,
    int aktualisiert = 0,
    int uebersprungen = 0,
    int zusammengefuehrt = 0,
    int fehlerhaft = 0,
  }) =>
      ImportErgebnisZaehler(
        hinzugefuegt: this.hinzugefuegt + hinzugefuegt,
        aktualisiert: this.aktualisiert + aktualisiert,
        uebersprungen: this.uebersprungen + uebersprungen,
        zusammengefuehrt: this.zusammengefuehrt + zusammengefuehrt,
        fehlerhaft: this.fehlerhaft + fehlerhaft,
      );
}

class ImportAusfuehrungsErgebnis {
  const ImportAusfuehrungsErgebnis(this.nachSammlung);

  final Map<String, ImportErgebnisZaehler> nachSammlung;

  ImportErgebnisZaehler get gesamt => nachSammlung.values.fold(
        const ImportErgebnisZaehler(),
        (summe, wert) => summe.plus(
          hinzugefuegt: wert.hinzugefuegt,
          aktualisiert: wert.aktualisiert,
          uebersprungen: wert.uebersprungen,
          zusammengefuehrt: wert.zusammengefuehrt,
          fehlerhaft: wert.fehlerhaft,
        ),
      );
}

class ImportAusfuehrungService {
  const ImportAusfuehrungService({
    this.protokollRepository = const ImportProtokollRepository(),
    this.aliasRepository = const ImportAliasRepository(),
  });

  final ImportProtokollRepository protokollRepository;
  final ImportAliasRepository aliasRepository;

  static final Set<LokaleDatenbank> _laufendeDatenbanken = <LokaleDatenbank>{};

  static const _reihenfolge = <String>[
    'profile',
    'objekte',
    'orte',
    'bewertungskriterien',
    'erlebnisse',
    'erlebnisPositionen',
    'preisbeobachtungen',
    'ortsbewertungen',
    'bewertungen',
  ];

  Map<String, Object?> normalisiereBekannteAliase(
    LokaleDatenbank datenbank,
    Map<String, Object?> importDokument,
  ) =>
      aliasRepository.normalisiereDokument(datenbank, importDokument);

  ImportAusfuehrungsErgebnis ausfuehren({
    required LokaleDatenbank datenbank,
    required Map<String, Object?> importDokument,
    required ImportStrategie strategie,
    ImportKonfliktEntscheidungsStand entscheidungen =
        const ImportKonfliktEntscheidungsStand(),
    Map<String, String> mergeAliase = const {},
    List<ImportAliasReferenz> aliase = const [],
    Map<String, int> zusammengefuehrtNachSammlung = const {},
    DateTime? ausgefuehrtAm,
  }) {
    if (!_laufendeDatenbanken.add(datenbank)) {
      throw StateError('Für diese Datenbank läuft bereits ein Import.');
    }
    try {
      return _ausfuehrenGesperrt(
        datenbank: datenbank,
        importDokument: importDokument,
        strategie: strategie,
        entscheidungen: entscheidungen,
        mergeAliase: mergeAliase,
        aliase: aliase,
        zusammengefuehrtNachSammlung: zusammengefuehrtNachSammlung,
        ausgefuehrtAm: ausgefuehrtAm,
      );
    } finally {
      _laufendeDatenbanken.remove(datenbank);
    }
  }

  ImportAusfuehrungsErgebnis _ausfuehrenGesperrt({
    required LokaleDatenbank datenbank,
    required Map<String, Object?> importDokument,
    required ImportStrategie strategie,
    required ImportKonfliktEntscheidungsStand entscheidungen,
    required Map<String, String> mergeAliase,
    required List<ImportAliasReferenz> aliase,
    required Map<String, int> zusammengefuehrtNachSammlung,
    required DateTime? ausgefuehrtAm,
  }) {
    final zeitpunkt = (ausgefuehrtAm ?? DateTime.now()).toUtc();
    final ergebnis = <String, ImportErgebnisZaehler>{};

    try {
      datenbank.transaktion(() {
        aliasRepository.stelleTabelleBereit(datenbank);
        if (strategie == ImportStrategie.bestandErsetzen) {
          _ersetzeBestand(datenbank);
        }
        for (final sammlung in _reihenfolge) {
          for (final ergebnisSammlung in _ergebnisSammlungen(sammlung)) {
            ergebnis.putIfAbsent(
              ergebnisSammlung,
              () => const ImportErgebnisZaehler(),
            );
          }
          for (final roh in (importDokument[sammlung] as List? ?? const [])) {
            if (roh is! Map) {
              throw const FormatException('Importeintrag ist kein Objekt.');
            }
            final wert = Map<String, Object?>.from(roh);
            final ergebnisSammlung = _ergebnisSammlung(sammlung, wert);
            final zaehler = ergebnis[ergebnisSammlung]!;
            final importId = wert['id'] as String?;
            if (importId == null || importId.isEmpty) {
              throw const FormatException(
                'Importeintrag besitzt keine stabile ID.',
              );
            }
            final zielId = mergeAliase[importId] ?? importId;
            final aktion = _entscheidung(sammlung, importId, entscheidungen);
            if (aktion == ImportKonfliktAktion.ueberspringen ||
                aktion == ImportKonfliktAktion.lokaleVersion) {
              ergebnis[ergebnisSammlung] = zaehler.plus(uebersprungen: 1);
              continue;
            }
            if (aktion == ImportKonfliktAktion.zusammenfuehren &&
                mergeAliase.containsKey(importId)) {
              ergebnis[ergebnisSammlung] =
                  zaehler.plus(zusammengefuehrt: 1);
              continue;
            }
            final existiert = _existiert(datenbank, sammlung, zielId);
            if (existiert &&
                strategie == ImportStrategie.lokalBevorzugen &&
                aktion != ImportKonfliktAktion.importVersion) {
              ergebnis[ergebnisSammlung] = zaehler.plus(uebersprungen: 1);
              continue;
            }
            _schreibe(
              datenbank,
              sammlung,
              {...wert, 'id': zielId},
              existiert,
            );
            ergebnis[ergebnisSammlung] = existiert
                ? zaehler.plus(aktualisiert: 1)
                : zaehler.plus(hinzugefuegt: 1);
          }
        }
        for (final alias in aliase) {
          aliasRepository.speichere(
            datenbank,
            alias,
            erstelltAm: zeitpunkt,
          );
        }
      });
    } catch (_) {
      _protokolliereSicher(
        datenbank: datenbank,
        zeitpunkt: zeitpunkt,
        erfolgreich: false,
        strategie: strategie,
        ergebnis: ergebnis,
        zusaetzlichFehlerhaft: 1,
      );
      rethrow;
    }

    _beruecksichtigeMerges(ergebnis, zusammengefuehrtNachSammlung);
    final result = ImportAusfuehrungsErgebnis(Map.unmodifiable(ergebnis));
    _protokolliereSicher(
      datenbank: datenbank,
      zeitpunkt: zeitpunkt,
      erfolgreich: true,
      strategie: strategie,
      ergebnis: ergebnis,
    );
    return result;
  }

  List<ImportProtokollEintrag> ladeProtokoll(
    LokaleDatenbank datenbank, {
    int limit = 20,
  }) =>
      protokollRepository.lade(datenbank, limit: limit);

  List<String> _ergebnisSammlungen(String sammlung) =>
      sammlung == 'bewertungen'
          ? const ['produktbewertungen', 'ortsbewertungswerte']
          : [sammlung];

  String _ergebnisSammlung(
    String sammlung,
    Map<String, Object?> wert,
  ) {
    if (sammlung != 'bewertungen') return sammlung;
    return wert['zielart'] == 'ort'
        ? 'ortsbewertungswerte'
        : 'produktbewertungen';
  }

  void _beruecksichtigeMerges(
    Map<String, ImportErgebnisZaehler> ergebnis,
    Map<String, int> merges,
  ) {
    for (final eintrag in merges.entries) {
      if (eintrag.value <= 0) continue;
      final bisher = ergebnis[eintrag.key] ?? const ImportErgebnisZaehler();
      final abziehbar = bisher.aktualisiert < eintrag.value
          ? bisher.aktualisiert
          : eintrag.value;
      ergebnis[eintrag.key] = ImportErgebnisZaehler(
        hinzugefuegt: bisher.hinzugefuegt,
        aktualisiert: bisher.aktualisiert - abziehbar,
        uebersprungen: bisher.uebersprungen,
        zusammengefuehrt: bisher.zusammengefuehrt + eintrag.value,
        fehlerhaft: bisher.fehlerhaft,
      );
    }
  }

  void _ersetzeBestand(LokaleDatenbank datenbank) {
    for (final tabelle in const [
      'bewertungen',
      'ortsbewertungen',
      'preisbeobachtungen',
      'erlebnispositionen',
      'erlebnisse',
      'produkte',
      'objekte',
      'orte',
      'kriterien',
      'profile',
    ]) {
      datenbank.verbindung.execute('DELETE FROM $tabelle');
    }
  }

  void _protokolliereSicher({
    required LokaleDatenbank datenbank,
    required DateTime zeitpunkt,
    required bool erfolgreich,
    required ImportStrategie strategie,
    required Map<String, ImportErgebnisZaehler> ergebnis,
    int zusaetzlichFehlerhaft = 0,
  }) {
    final gesamt = ImportAusfuehrungsErgebnis(ergebnis).gesamt;
    try {
      protokollRepository.speichere(
        datenbank: datenbank,
        ausgefuehrtAm: zeitpunkt,
        erfolgreich: erfolgreich,
        strategie: strategie,
        hinzugefuegt: gesamt.hinzugefuegt,
        aktualisiert: gesamt.aktualisiert,
        uebersprungen: gesamt.uebersprungen,
        zusammengefuehrt: gesamt.zusammengefuehrt,
        fehlerhaft: gesamt.fehlerhaft + zusaetzlichFehlerhaft,
      );
    } catch (_) {
      // Das Protokoll darf die eigentliche Importtransaktion nicht beeinflussen.
    }
  }

  ImportKonfliktAktion? _entscheidung(
    String sammlung,
    String id,
    ImportKonfliktEntscheidungsStand stand,
  ) {
    for (final eintrag in stand.entscheidungen.entries) {
      final teile = eintrag.key.split('|');
      if (teile.length >= 2 && teile[0] == sammlung && teile[1] == id) {
        return eintrag.value;
      }
    }
    return null;
  }

  bool _existiert(LokaleDatenbank db, String sammlung, String id) {
    final tabelle = _tabelle(sammlung);
    if (tabelle == null) return false;
    return db.verbindung
        .select('SELECT 1 FROM $tabelle WHERE id = ?', [id]).isNotEmpty;
  }

  String? _tabelle(String sammlung) => switch (sammlung) {
        'profile' => 'profile',
        'objekte' => 'objekte',
        'orte' => 'orte',
        'bewertungskriterien' => 'kriterien',
        'erlebnisse' => 'erlebnisse',
        'erlebnisPositionen' => 'erlebnispositionen',
        'preisbeobachtungen' => 'preisbeobachtungen',
        'ortsbewertungen' => 'ortsbewertungen',
        'bewertungen' => 'bewertungen',
        _ => null,
      };

  void _schreibe(
    LokaleDatenbank db,
    String sammlung,
    Map<String, Object?> wert,
    bool existiert,
  ) {
    if (sammlung == 'objekte') {
      _upsert(
        db,
        'objekte',
        _werte(wert, const {
          'id': 'id',
          'name': 'name',
          'art': 'art',
          'erstelltAm': 'erstellt_am',
          'geaendertAm': 'geaendert_am',
        }),
        existiert,
      );
      final produktExistiert = db.verbindung.select(
        'SELECT 1 FROM produkte WHERE objekt_id = ?',
        [wert['id']],
      ).isNotEmpty;
      _upsert(
        db,
        'produkte',
        _werte(wert, const {
          'id': 'objekt_id',
          'marke': 'marke',
          'produktart': 'produktart',
          'brauerei': 'brauerei',
          'sorte': 'sorte',
          'alkoholgehalt': 'alkoholgehalt',
          'herkunft': 'herkunft',
          'gebinde': 'gebinde',
          'fuellmengeMl': 'fuellmenge_ml',
          'barcode': 'barcode',
          'notiz': 'notiz',
        }),
        produktExistiert,
        idSpalte: 'objekt_id',
      );
      return;
    }

    final mapping = _mapping(sammlung);
    final tabelle = _tabelle(sammlung);
    if (mapping == null || tabelle == null) return;
    _upsert(db, tabelle, _werte(wert, mapping), existiert);
  }

  Map<String, String>? _mapping(String sammlung) => switch (sammlung) {
        'profile' => const {
            'id': 'id',
            'anzeigename': 'anzeigename',
            'erstelltAm': 'erstellt_am',
            'geaendertAm': 'geaendert_am',
          },
        'orte' => const {
            'id': 'id',
            'name': 'name',
            'typ': 'typ',
            'adresse': 'adresse',
            'breitengrad': 'breitengrad',
            'laengengrad': 'laengengrad',
            'osmReferenz': 'osm_referenz',
            'notiz': 'notiz',
            'erstelltAm': 'erstellt_am',
            'geaendertAm': 'geaendert_am',
          },
        'erlebnisse' => const {
            'id': 'id',
            'herkunftProfilId': 'herkunft_profil_id',
            'typ': 'typ',
            'status': 'status',
            'ortId': 'ort_id',
            'geplanterTag': 'geplanter_tag',
            'geplanteMinute': 'geplante_minute',
            'geplanteDauerMinuten': 'geplante_dauer_minuten',
            'tatsaechlicherBeginn': 'tatsaechlicher_beginn',
            'tatsaechlichesEnde': 'tatsaechliches_ende',
            'notiz': 'notiz',
            'istEntwurf': 'ist_entwurf',
            'erstelltAm': 'erstellt_am',
            'geaendertAm': 'geaendert_am',
          },
        'erlebnisPositionen' => const {
            'id': 'id',
            'erlebnisId': 'erlebnis_id',
            'produktId': 'produkt_id',
            'anzahl': 'anzahl',
            'erstelltAm': 'erstellt_am',
            'geaendertAm': 'geaendert_am',
          },
        'preisbeobachtungen' => const {
            'id': 'id',
            'erlebnisId': 'erlebnis_id',
            'erlebnisPositionId': 'erlebnis_position_id',
            'produktId': 'produkt_id',
            'ortId': 'ort_id',
            'betragMinor': 'betrag_minor',
            'waehrung': 'waehrung',
            'beobachtetAm': 'beobachtet_am',
            'erstelltAm': 'erstellt_am',
            'geaendertAm': 'geaendert_am',
          },
        'ortsbewertungen' => const {
            'id': 'id',
            'erlebnisId': 'erlebnis_id',
            'ortId': 'ort_id',
            'herkunftProfilId': 'herkunft_profil_id',
            'bewertetAm': 'bewertet_am',
            'notiz': 'notiz',
            'erstelltAm': 'erstellt_am',
            'geaendertAm': 'geaendert_am',
          },
        'bewertungskriterien' => const {
            'id': 'id',
            'name': 'name',
            'beschreibung': 'beschreibung',
            'eingabetyp': 'eingabetyp',
            'reihenfolge': 'reihenfolge',
            'aktiv': 'aktiv',
            'produktart': 'produktart',
            'objektart': 'objektart',
            'version': 'version',
            'erstelltAm': 'erstellt_am',
            'geaendertAm': 'geaendert_am',
          },
        'bewertungen' => const {
            'id': 'id',
            'erlebnisId': 'erlebnis_id',
            'erlebnisPositionId': 'erlebnis_position_id',
            'ortsbewertungId': 'ortsbewertung_id',
            'ortId': 'ort_id',
            'herkunftProfilId': 'herkunft_profil_id',
            'wert': 'wert',
            'erstelltAm': 'erstellt_am',
            'geaendertAm': 'geaendert_am',
          },
        _ => null,
      };

  Map<String, Object?> _werte(
    Map<String, Object?> quelle,
    Map<String, String> mapping,
  ) {
    final ziel = <String, Object?>{};
    for (final eintrag in mapping.entries) {
      var wert = quelle[eintrag.key];
      if (wert is bool) wert = wert ? 1 : 0;
      ziel[eintrag.value] = wert;
    }
    if (quelle['kriterium'] case final Map kriterium) {
      ziel['kriterium_id'] = kriterium['id'];
      ziel['kriterium_name'] = kriterium['name'];
      ziel['kriterium_beschreibung'] = kriterium['beschreibung'];
      ziel['kriterium_eingabetyp'] = kriterium['eingabetyp'];
      ziel['kriterium_reihenfolge'] = kriterium['reihenfolge'];
      ziel['kriterium_version'] = kriterium['version'];
      ziel['kriterium_auswahlwerte'] =
          (kriterium['auswahlwerte'] as List? ?? const []).join('\n');
    }
    if (quelle['auswahlwerte'] is List) {
      ziel['auswahlwerte'] = (quelle['auswahlwerte'] as List).join('\n');
    }
    return ziel;
  }

  void _upsert(
    LokaleDatenbank db,
    String tabelle,
    Map<String, Object?> werte,
    bool existiert, {
    String idSpalte = 'id',
  }) {
    if (existiert) {
      final set = werte.keys
          .where((k) => k != idSpalte)
          .map((k) => '$k = ?')
          .join(', ');
      final params = [
        for (final e in werte.entries)
          if (e.key != idSpalte) e.value,
        werte[idSpalte],
      ];
      db.verbindung.execute(
        'UPDATE $tabelle SET $set WHERE $idSpalte = ?',
        params,
      );
      return;
    }

    final spalten = werte.keys.join(', ');
    final platzhalter = List.filled(werte.length, '?').join(', ');
    db.verbindung.execute(
      'INSERT INTO $tabelle ($spalten) VALUES ($platzhalter)',
      werte.values.toList(),
    );
  }
}
