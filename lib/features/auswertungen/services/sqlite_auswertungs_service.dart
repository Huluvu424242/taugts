import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';
import 'package:taugts/features/auswertungen/services/auswertungs_service.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';

class SqliteAuswertungsService implements AuswertungsService {
  const SqliteAuswertungsService(this._db);

  final LokaleDatenbank _db;

  @override
  Future<AuswertungsUebersicht> berechne(AuswertungsFilter filter) async {
    final bewertungsRows = _bewertungsRows(filter);
    return AuswertungsUebersicht(
      bewertungsanzahl: bewertungsRows.length,
      durchschnitte: _durchschnitte(bewertungsRows),
      preisverlauf: _preisverlauf(filter),
      qualitaetsverlauf: _qualitaetsverlauf(filter),
      ortsverlauf: _ortsverlauf(filter),
      erlebnisgruppen: _erlebnisgruppen(filter),
      andrangBeobachtungen: _andrang(filter),
    );
  }

  List<Map<String, Object?>> _bewertungsRows(AuswertungsFilter filter) =>
      _db.verbindung.select('''
        SELECT DISTINCT b.id, b.kriterium_id,
          COALESCE(b.kriterium_name, k.name, b.kriterium_id) AS kriterium_name,
          COALESCE(b.kriterium_version, k.version, 1) AS kriterium_version,
          COALESCE(b.kriterium_eingabetyp, k.eingabetyp, 'wertung') AS eingabetyp,
          b.wert, b.erstellt_am, b.herkunft_profil_id,
          ep.produkt_id, ob.ort_id
        FROM bewertungen b
        LEFT JOIN kriterien k ON k.id = b.kriterium_id
        LEFT JOIN erlebnispositionen ep ON ep.id = b.erlebnis_position_id
        LEFT JOIN ortsbewertungen ob ON ob.id = b.ortsbewertung_id
        LEFT JOIN produkt_kategorien pk ON pk.produkt_id = ep.produkt_id
        LEFT JOIN ort_kategorien ok ON ok.ort_id = ob.ort_id
        WHERE (? IS NULL OR COALESCE(ep.produkt_id, ob.ort_id) = ?)
          AND (? IS NULL OR b.herkunft_profil_id = ?)
          AND (? IS NULL OR pk.kategorie_id = ? OR ok.kategorie_id = ?)
        ORDER BY b.erstellt_am
      ''', [
        filter.objektId,
        filter.objektId,
        filter.herkunftProfilId,
        filter.herkunftProfilId,
        filter.kategorieId,
        filter.kategorieId,
        filter.kategorieId,
      ]).cast<Map<String, Object?>>();

  List<Durchschnittswert> _durchschnitte(List<Map<String, Object?>> rows) {
    final gruppen = <String, List<double>>{};
    final namen = <String, String>{};
    final versionen = <String, int>{};
    for (final row in rows) {
      if (row['eingabetyp'] != 'wertung') continue;
      final id = '${row['kriterium_id']}#${row['kriterium_version']}';
      gruppen.putIfAbsent(id, () => []).add((row['wert']! as num).toDouble());
      namen[id] = row['kriterium_name']! as String;
      versionen[id] = row['kriterium_version']! as int;
    }
    return [
      for (final entry in gruppen.entries)
        Durchschnittswert(
          kriterium: namen[entry.key]!,
          kriteriumVersion: versionen[entry.key]!,
          anzahl: entry.value.length,
          durchschnitt:
              entry.value.reduce((a, b) => a + b) / entry.value.length,
        ),
    ]..sort((a, b) => a.kriterium.compareTo(b.kriterium));
  }

  List<Zeitwert> _preisverlauf(AuswertungsFilter filter) {
    final rows = _db.verbindung.select('''
      SELECT pb.beobachtet_am, pb.betrag_minor, pb.waehrung,
        COALESCE(o.name, 'Ohne Ort') AS ort_name
      FROM preisbeobachtungen pb
      LEFT JOIN orte o ON o.id = pb.ort_id
      LEFT JOIN produkt_kategorien pk ON pk.produkt_id = pb.produkt_id
      WHERE (? IS NULL OR pb.produkt_id = ?)
        AND (? IS NULL OR pk.kategorie_id = ?)
      ORDER BY pb.beobachtet_am
    ''', [filter.objektId, filter.objektId, filter.kategorieId, filter.kategorieId]);
    return [
      for (final row in rows)
        Zeitwert(
          zeitpunkt: DateTime.parse(row['beobachtet_am']! as String),
          wert: (row['betrag_minor']! as int) / 100,
          beschreibung: '${row['ort_name']} · ${row['waehrung']}',
        ),
    ];
  }

  List<Zeitwert> _qualitaetsverlauf(AuswertungsFilter filter) =>
      _bewertungsRows(filter)
          .where((row) => row['eingabetyp'] == 'wertung' && row['produkt_id'] != null)
          .map(
            (row) => Zeitwert(
              zeitpunkt: DateTime.parse(row['erstellt_am']! as String),
              wert: (row['wert']! as num).toDouble(),
              beschreibung:
                  '${row['kriterium_name']} · Version ${row['kriterium_version']}',
            ),
          )
          .toList(growable: false);

  List<Zeitwert> _ortsverlauf(AuswertungsFilter filter) =>
      _bewertungsRows(filter)
          .where((row) => row['eingabetyp'] == 'wertung' && row['ort_id'] != null)
          .map(
            (row) => Zeitwert(
              zeitpunkt: DateTime.parse(row['erstellt_am']! as String),
              wert: (row['wert']! as num).toDouble(),
              beschreibung:
                  '${row['kriterium_name']} · Version ${row['kriterium_version']}',
            ),
          )
          .toList(growable: false);

  List<ErlebnisGruppe> _erlebnisgruppen(AuswertungsFilter filter) {
    final rows = _db.verbindung.select('''
      SELECT e.id, e.typ, e.tatsaechlicher_beginn, e.tatsaechliches_ende,
        COALESCE(e.ort_id, e.konsumort_id, e.kaufort_id) AS ort_id
      FROM erlebnisse e
      WHERE (? IS NULL OR COALESCE(e.ort_id, e.konsumort_id, e.kaufort_id) = ?)
        AND (? IS NULL OR e.herkunft_profil_id = ?)
        AND e.status = 'beendet'
    ''', [
      filter.objektId,
      filter.objektId,
      filter.herkunftProfilId,
      filter.herkunftProfilId,
    ]);
    final gruppen = <String, (int, int)>{};
    for (final row in rows) {
      final beginn = DateTime.tryParse(row['tatsaechlicher_beginn'] as String? ?? '');
      final ende = DateTime.tryParse(row['tatsaechliches_ende'] as String? ?? '');
      if (beginn == null) continue;
      final tageszeit = beginn.hour < 11
          ? 'morgens'
          : beginn.hour < 17
              ? 'tagsüber'
              : 'abends';
      final key = '${row['typ']} · Wochentag ${beginn.weekday} · $tageszeit';
      final bisher = gruppen[key] ?? (0, 0);
      final dauer = ende == null ? 0 : ende.difference(beginn).inMinutes.clamp(0, 24 * 60);
      gruppen[key] = (bisher.$1 + 1, bisher.$2 + dauer);
    }
    return [
      for (final entry in gruppen.entries)
        ErlebnisGruppe(
          schluessel: entry.key,
          anzahl: entry.value.$1,
          gesamtdauerMinuten: entry.value.$2,
        ),
    ]..sort((a, b) => a.schluessel.compareTo(b.schluessel));
  }

  List<Zeitwert> _andrang(AuswertungsFilter filter) {
    final rows = _db.verbindung.select('''
      SELECT b.wert, ob.bewertet_am, o.name
      FROM bewertungen b
      JOIN ortsbewertungen ob ON ob.id = b.ortsbewertung_id
      JOIN orte o ON o.id = ob.ort_id
      WHERE COALESCE(b.kriterium_name, '') = 'Andrang / Auslastung'
        AND (? IS NULL OR ob.ort_id = ?)
        AND (? IS NULL OR b.herkunft_profil_id = ?)
      ORDER BY ob.bewertet_am
    ''', [
      filter.objektId,
      filter.objektId,
      filter.herkunftProfilId,
      filter.herkunftProfilId,
    ]);
    return [
      for (final row in rows)
        Zeitwert(
          zeitpunkt: DateTime.parse(row['bewertet_am']! as String),
          wert: (row['wert']! as num).toDouble(),
          beschreibung:
              '${row['name']} · beobachteter Andrang, keine Kausalaussage',
        ),
    ];
  }
}
