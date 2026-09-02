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
        'schemaVersion': 1,
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
        'kategorien': const <Object?>[],
        'kategorieZuordnungen': const <Object?>[],
      });

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
            'status': z['status'],
            'ortId': z['ort_id'],
            'geplanterTag': z['geplanter_tag'],
            'geplanteMinute': z['geplante_minute'],
            'geplanteDauerMinuten': z['geplante_dauer_minuten'],
            'tatsaechlicherBeginn': z['tatsaechlicher_beginn'],
            'tatsaechlichesEnde': z['tatsaechliches_ende'],
            'notiz': z['notiz'],
            'istEntwurf': z['ist_entwurf'] == 1,
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

  List<Map<String, Object?>> _bewertungen() =>
      _zeilen('bewertungen').map((z) {
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
          'erstelltAm': z['erstellt_am'],
          'geaendertAm': z['geaendert_am'],
        };
      }).toList();

  List<Map<String, Object?>> _ortsbewertungen() =>
      _zeilen('ortsbewertungen')
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
