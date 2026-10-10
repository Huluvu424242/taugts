import 'dart:convert';

import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';

class ExportService {
  ExportService(this.datenbank,
      {required this.appVersion, DateTime Function()? jetzt})
      : jetzt = jetzt ?? DateTime.now;

  final LokaleDatenbank datenbank;
  final String appVersion;
  final DateTime Function() jetzt;

  String erzeugeJson() => const JsonEncoder.withIndent('  ').convert({
        'format': 'taugts-export',
        'schemaVersion': 3,
        'exportiertAm': jetzt().toUtc().toIso8601String(),
        'appVersion': appVersion,
        'profile': _profile(),
        'objekte': _objekte(),
        'orte': _orte(),
        'erlebnisse': _erlebnisse(),
        'erlebnisPositionen': _erlebnisPositionen(),
        'preisbeobachtungen': _preisbeobachtungen(),
        'bewertungskriterien': _kriterien(),
        'bewertungen': _bewertungen(),
        'ortsbewertungen': _ortsbewertungen(),
        'kategorien': _kategorien(),
        'kategorieZuordnungen': _kategorieZuordnungen(),
        'objektTags': _objektTags(),
        'objektKlassifikationsmerkmale': _objektKlassifikationsmerkmale(),
        'kategorieKriteriensetRegeln': _kategorieKriteriensetRegeln(),
        'kategorieKriterien': _kategorieKriterien(),
      });

  // Die Kategorie-Tabelle besitzt keine Zeitstempel. Der feste Wert
  // kennzeichnet dies ohne bei jedem Export künstliche Änderungen zu erzeugen.
  static const _ohneKategorieZeit = '1970-01-01T00:00:00.000Z';

  List<Map<String, Object?>> _kategorien() => _zeilen('kategorien')
      .map((z) => {
            'id': z['id'],
            'name': z['name'],
            'zielart': z['bereich'] == 'ort' ? 'ort' : 'objekt',
            'elternKategorieId': z['eltern_id'],
            'istStandard': z['ist_standard'] == 1,
            'erstelltAm': _ohneKategorieZeit,
            'geaendertAm': _ohneKategorieZeit,
          })
      .toList();

  List<Map<String, Object?>> _kategorieZuordnungen() => [
        for (final z in _zeilen('produkt_kategorien'))
          {'kategorieId': z['kategorie_id'], 'zielId': z['produkt_id']},
        for (final z in _zeilen('ort_kategorien'))
          {'kategorieId': z['kategorie_id'], 'zielId': z['ort_id']},
      ];

  List<Map<String, Object?>> _objektTags() => _zeilen('objekt_tags')
      .map((z) => {
            'objektId': z['objekt_id'],
            'normalisiert': z['normalisiert'],
            'text': z['text'],
          })
      .toList();

  List<Map<String, Object?>> _objektKlassifikationsmerkmale() =>
      _zeilen('objekt_klassifikationsmerkmale')
          .map((z) => {
                'objektId': z['objekt_id'],
                'dimension': z['dimension'],
                'schluessel': z['schluessel'],
                'wert': z['wert'],
              })
          .toList();

  List<Map<String, Object?>> _kategorieKriteriensetRegeln() =>
      _zeilen('kategorie_kriterienset_regeln')
          .map((z) => {
                'kategorieId': z['kategorie_id'],
                'fallbackObjektart': z['fallback_objektart'],
                'modus': z['modus'],
                'version': z['version'],
              })
          .toList();

  List<Map<String, Object?>> _kategorieKriterien() => _zeilen('kategorie_kriterien')
      .map((z) => {
            'kategorieId': z['kategorie_id'],
            'kriteriumId': z['kriterium_id'],
            'reihenfolge': z['reihenfolge'],
          })
      .toList();

  List<Map<String, Object?>> _profile() => _zeilen('profile')
      .map((z) => {
            'id': z['id'],
            'anzeigename': z['anzeigename'],
            'erstelltAm': z['erstellt_am'],
            'geaendertAm': z['geaendert_am'],
          })
      .toList();

  List<Map<String, Object?>> _objekte() {
    final zeilen = datenbank.verbindung.select('''
      SELECT o.*, p.marke, p.produktart, p.brauerei, p.sorte,
        p.alkoholgehalt, p.herkunft, p.gebinde, p.fuellmenge_ml,
        p.barcode, p.notiz
      FROM objekte o JOIN produkte p ON p.objekt_id = o.id ORDER BY o.id
    ''');
    return zeilen
        .map((z) => {
              'id': z['id'],
              'name': z['name'],
              'art': z['art'],
              'produktart': z['produktart'],
              'marke': z['marke'],
              'brauerei': z['brauerei'],
              'sorte': z['sorte'],
              'alkoholgehalt': _dezimal(z['alkoholgehalt']),
              'herkunft': z['herkunft'],
              'gebinde': z['gebinde'],
              'fuellmengeMl': z['fuellmenge_ml'],
              'barcode': z['barcode'],
              'notiz': z['notiz'],
              'erstelltAm': z['erstellt_am'],
              'geaendertAm': z['geaendert_am'],
            })
        .toList();
  }

  List<Map<String, Object?>> _orte() => _zeilen('orte')
      .map((z) => {
            'id': z['id'],
            'name': z['name'],
            'typ': z['typ'],
            'adresse': z['adresse'],
            'breitengrad': _dezimal(z['breitengrad']),
            'laengengrad': _dezimal(z['laengengrad']),
            'osmReferenz': z['osm_referenz'],
            'notiz': z['notiz'],
            'erstelltAm': z['erstellt_am'],
            'geaendertAm': z['geaendert_am'],
          })
      .toList();

  List<Map<String, Object?>> _erlebnisse() => _zeilen('erlebnisse')
      .map((z) => {
            'id': z['id'],
            'herkunftProfilId': z['herkunft_profil_id'],
            'typ': z['typ'],
            'ortId': z['ort_id'],
            'beginn': z['beginn'],
            'ende': z['ende'],
            'notiz': z['notiz'],
            'erstelltAm': z['erstellt_am'],
            'geaendertAm': z['geaendert_am'],
          })
      .toList();

  List<Map<String, Object?>> _erlebnisPositionen() =>
      _zeilen('erlebnispositionen')
          .map((z) => {
                'id': z['id'],
                'erlebnisId': z['erlebnis_id'],
                'produktId': z['produkt_id'],
                'anzahl': z['anzahl'],
                'erstelltAm': z['erstellt_am'],
                'geaendertAm': z['geaendert_am'],
              })
          .toList();

  List<Map<String, Object?>> _preisbeobachtungen() =>
      _zeilen('preisbeobachtungen')
          .map((z) => {
                'id': z['id'],
                'erlebnisId': z['erlebnis_id'],
                'erlebnisPositionId': z['erlebnis_position_id'],
                'produktId': z['produkt_id'],
                'ortId': z['ort_id'],
                'betragMinor': z['betrag_minor'],
                'waehrung': z['waehrung'],
                'beobachtetAm': z['beobachtet_am'],
                'erstelltAm': z['erstellt_am'],
                'geaendertAm': z['geaendert_am'],
              })
          .toList();

  List<Map<String, Object?>> _kriterien() => _zeilen('kriterien')
      .map((z) => {
            'id': z['id'],
            'name': z['name'],
            'beschreibung': z['beschreibung'],
            'eingabetyp': z['eingabetyp'],
            'reihenfolge': z['reihenfolge'],
            'aktiv': z['aktiv'] == 1,
            'produktart': z['produktart'],
            'objektart': z['objektart'],
            'version': z['version'],
            'auswahlwerte': _auswahlwerte(z['auswahlwerte']),
            'erstelltAm': z['erstellt_am'],
            'geaendertAm': z['geaendert_am'],
          })
      .toList();

  List<Map<String, Object?>> _bewertungen() => _zeilen('bewertungen').map((z) {
        final istOrt = z['ortsbewertung_id'] != null;
        return {
          'id': z['id'],
          'zielart': istOrt ? 'ort' : 'produkt',
          'objektId':
              istOrt ? z['ort_id'] : _produktId(z['erlebnis_position_id']),
          'erlebnisId': z['erlebnis_id'],
          'erlebnisPositionId': z['erlebnis_position_id'],
          'ortsbewertungId': z['ortsbewertung_id'],
          'ortId': z['ort_id'],
          'herkunftProfilId': z['herkunft_profil_id'],
          'bewertetAm': z['erstellt_am'],
          'kriterium': {
            'id': z['kriterium_id'],
            'name': z['kriterium_name'],
            'beschreibung': z['kriterium_beschreibung'],
            'eingabetyp': z['kriterium_eingabetyp'],
            'reihenfolge': z['kriterium_reihenfolge'],
            'version': z['kriterium_version'],
            'auswahlwerte': _auswahlwerte(z['kriterium_auswahlwerte']),
          },
          'wert': _dezimal(z['wert']),
          'textWert': z['text_wert'],
          'erstelltAm': z['erstellt_am'],
          'geaendertAm': z['geaendert_am'],
        };
      }).toList();

  List<Map<String, Object?>> _ortsbewertungen() => _zeilen('ortsbewertungen')
      .map((z) => {
            'id': z['id'],
            'erlebnisId': z['erlebnis_id'],
            'ortId': z['ort_id'],
            'herkunftProfilId': z['herkunft_profil_id'],
            'bewertetAm': z['bewertet_am'],
            'notiz': z['notiz'],
            'erstelltAm': z['erstellt_am'],
            'geaendertAm': z['geaendert_am'],
          })
      .toList();

  List<Map<String, Object?>> _zeilen(String tabelle) => datenbank.verbindung
      .select('SELECT * FROM $tabelle ORDER BY id')
      .map((z) => Map<String, Object?>.from(z))
      .toList();

  String? _produktId(Object? positionsId) {
    if (positionsId == null) return null;
    final zeilen = datenbank.verbindung.select(
      'SELECT produkt_id FROM erlebnispositionen WHERE id = ?',
      [positionsId],
    );
    return zeilen.isEmpty ? null : zeilen.single['produkt_id'] as String?;
  }

  String? _dezimal(Object? wert) =>
      wert == null ? null : (wert as num).toString();

  List<String> _auswahlwerte(Object? wert) {
    final text = wert as String? ?? '';
    if (text.isEmpty) return const [];
    return text.split('\n').where((element) => element.isNotEmpty).toList();
  }
}
