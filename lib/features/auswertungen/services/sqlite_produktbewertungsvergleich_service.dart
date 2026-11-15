import 'package:taugts/features/auswertungen/models/produktvergleich_modelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';

/// Aggregiert ausschließlich qualitätsbezogene Produktbewertungen.
class SqliteProduktbewertungsvergleichService
    implements ProduktBewertungsvergleichService {
  const SqliteProduktbewertungsvergleichService(this._db);
  final LokaleDatenbank _db;

  @override
  Future<List<ProduktBewertungsRang>> ladeBewertungen(
    ProduktvergleichFilter filter,
  ) async {
    final rows = _db.verbindung.select('''
      SELECT b.id, b.erlebnis_id, b.kriterium_id,
        COALESCE(b.kriterium_version, k.version, 1) AS version,
        COALESCE(b.kriterium_name, k.name, '') AS kriterium_name,
        b.wert,
        COALESCE(e.beginn, b.erstellt_am) AS zeitpunkt,
        o.id AS ort_id, o.name AS ort_name, o.typ AS ort_typ
      FROM bewertungen b
      JOIN erlebnispositionen ep ON ep.id = b.erlebnis_position_id
      JOIN erlebnisse e ON e.id = ep.erlebnis_id
      LEFT JOIN preisbeobachtungen pb
        ON pb.erlebnis_position_id = ep.id
      LEFT JOIN orte o ON o.id = COALESCE(
        pb.ort_id, e.ort_id, e.konsumort_id, e.kaufort_id
      )
      LEFT JOIN kriterien k ON k.id = b.kriterium_id
      WHERE ep.produkt_id = ?
        AND b.ortsbewertung_id IS NULL
        AND COALESCE(b.kriterium_eingabetyp, k.eingabetyp, 'wertung') = 'wertung'
        AND b.wert IS NOT NULL
      ORDER BY zeitpunkt, b.id
    ''', [filter.produktId]);
    final relevante = <Map<String, Object?>>[];
    final neuesteVersionen = <String, int>{};
    for (final row in rows) {
      final typ = row['ort_typ'] as String?;
      final zeit = DateTime.tryParse(row['zeitpunkt'] as String? ?? '');
      if (row['ort_id'] == null ||
          typ == null ||
          !filter.enthaeltOrtstyp(typ) ||
          zeit == null ||
          !filter.enthaelt(zeit)) {
        continue;
      }
      relevante.add(row);
      final id = row['kriterium_id'] as String;
      final version = row['version'] as int;
      if (version > (neuesteVersionen[id] ?? 0)) {
        neuesteVersionen[id] = version;
      }
    }
    // Kriterienversionen nicht still vermengen.
    final proErlebnis = <String, List<Map<String, Object?>>>{};
    for (final row in relevante) {
      if (row['version'] != neuesteVersionen[row['kriterium_id']]) {
        continue;
      }
      final key = "${row['ort_id']}:${row['erlebnis_id']}";
      proErlebnis.putIfAbsent(key, () => []).add(row);
    }
    final gruppen = <String, List<double>>{};
    final namen = <String, String>{};
    final letzte = <String, DateTime>{};
    for (final rows in proErlebnis.values) {
      final gesamt = rows
          .where((row) => row['kriterium_name'] == 'Gesamturteil')
          .toList();
      final werte = gesamt.isNotEmpty ? gesamt : rows;
      final summe = werte.fold<double>(
        0,
        (summe, row) => summe + (row['wert'] as num).toDouble(),
      );
      final eintrag = rows.first;
      final id = eintrag['ort_id'] as String;
      final zeit = DateTime.parse(eintrag['zeitpunkt'] as String);
      gruppen.putIfAbsent(id, () => []).add(summe / werte.length);
      namen[id] = eintrag['ort_name'] as String;
      if (letzte[id] == null || zeit.isAfter(letzte[id]!)) {
        letzte[id] = zeit;
      }
    }
    return <ProduktBewertungsRang>[
      for (final gruppe in gruppen.entries)
        ProduktBewertungsRang(
          ortId: gruppe.key,
          ortName: namen[gruppe.key]!,
          durchschnitt:
              gruppe.value.reduce((a, b) => a + b) / gruppe.value.length,
          anzahlErlebnisse: gruppe.value.length,
          letzteBewertung: letzte[gruppe.key]!,
        ),
    ]..sort((a, b) {
        final vergleich = b.durchschnitt.compareTo(a.durchschnitt);
        return vergleich == 0
            ? a.ortName.compareTo(b.ortName)
            : vergleich;
      });
  }
}
