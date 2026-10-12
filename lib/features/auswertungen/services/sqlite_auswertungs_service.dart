import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';
import 'package:taugts/features/auswertungen/services/auswertungs_service.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';

class SqliteAuswertungsService
    implements AuswertungsService, AuswertungsFilterOptionenService {
  const SqliteAuswertungsService(this._db);

  final LokaleDatenbank _db;

  @override
  Future<AuswertungsFilterOptionen> ladeFilterOptionen() async =>
      AuswertungsFilterOptionen(
        produkte: _optionen('''
          SELECT p.objekt_id AS id, o.name AS bezeichnung
          FROM produkte p
          JOIN objekte o ON o.id = p.objekt_id
          WHERE p.geloescht = 0
          ORDER BY o.name
        '''),
        orte: _optionen('''
          SELECT id, name AS bezeichnung
          FROM orte
          WHERE geloescht = 0
          ORDER BY name
        '''),
        kategorien: _optionen('''
          SELECT id, name AS bezeichnung
          FROM kategorien
          ORDER BY name
        '''),
        kriterien: _optionen('''
          SELECT id, name AS bezeichnung
          FROM kriterien
          WHERE aktiv = 1
          ORDER BY reihenfolge, name
        '''),
      );

  List<AuswertungsFilterOption> _optionen(String abfrage) => [
        for (final row in _db.verbindung.select(abfrage))
          AuswertungsFilterOption(
            id: row['id']! as String,
            bezeichnung: row['bezeichnung']! as String,
          ),
      ];

  @override
  Future<AuswertungsUebersicht> berechne(AuswertungsFilter filter) async {
    final bewertungsRows = _bewertungsRows(filter);
    return AuswertungsUebersicht(
      bewertungsanzahl: bewertungsRows.length,
      durchschnitte: _durchschnitte(bewertungsRows),
      preisverlauf: _preisverlauf(filter),
      ausgabenverlauf: _ausgabenverlauf(filter),
      qualitaetsverlauf: _qualitaetsverlauf(filter),
      ortsverlauf: _ortsverlauf(filter),
      erlebnisgruppen: _erlebnisgruppen(filter),
      andrangBeobachtungen: _andrang(filter),
      auffaelligkeiten: _auffaelligkeiten(filter),
    );
  }

  List<Map<String, Object?>> _bewertungsRows(AuswertungsFilter filter) =>
      _db.verbindung
          .select('''
        SELECT DISTINCT b.id, e.id AS erlebnis_id, b.kriterium_id,
          COALESCE(e.beginn, ob.bewertet_am, b.erstellt_am) AS ereigniszeit,
          COALESCE(b.kriterium_name, k.name, b.kriterium_id) AS kriterium_name,
          COALESCE(b.kriterium_version, k.version, 1) AS kriterium_version,
          COALESCE(b.kriterium_eingabetyp, k.eingabetyp, 'wertung') AS eingabetyp,
          b.wert, b.erstellt_am, b.herkunft_profil_id,
          ep.produkt_id, ob.ort_id
        FROM bewertungen b
        LEFT JOIN erlebnisse e ON e.id = b.erlebnis_id
        LEFT JOIN ortsbewertungen ob ON ob.id = b.ortsbewertung_id
        LEFT JOIN kriterien k ON k.id = b.kriterium_id
        LEFT JOIN erlebnispositionen ep ON ep.id = b.erlebnis_position_id
        LEFT JOIN produkt_kategorien pk ON pk.produkt_id = ep.produkt_id
        LEFT JOIN ort_kategorien ok ON ok.ort_id = ob.ort_id
        WHERE (? IS NULL OR
            (? = 'produkt' AND ep.produkt_id = ?) OR
            (? = 'ort' AND ob.ort_id = ?))
          AND (? IS NULL OR b.kriterium_id = ?)
          AND (? IS NULL OR b.herkunft_profil_id = ?)
          AND (? IS NULL OR pk.kategorie_id = ? OR ok.kategorie_id = ?)
        ORDER BY ereigniszeit
      ''', [
            filter.objektId,
            filter.objektArt.name,
            filter.objektId,
            filter.objektArt.name,
            filter.objektId,
            filter.kriteriumId,
            filter.kriteriumId,
            filter.herkunftProfilId,
            filter.herkunftProfilId,
            filter.kategorieId,
            filter.kategorieId,
            filter.kategorieId,
          ])
          .cast<Map<String, Object?>>()
          .where((row) {
            final zeit =
                DateTime.tryParse(row['ereigniszeit'] as String? ?? '');
            return zeit != null && filter.enthaeltZeitpunkt(zeit);
          })
          .toList();

  List<Durchschnittswert> _durchschnitte(List<Map<String, Object?>> rows) {
    final gruppen = <String, List<double>>{};
    final namen = <String, String>{};
    final versionen = <String, int>{};
    for (final row in rows) {
      if (row['eingabetyp'] != 'wertung' || row['wert'] == null) continue;
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
          anzahl: StatistikKennzahlen.ausWerten(entry.value).anzahl,
          durchschnitt: StatistikKennzahlen.ausWerten(entry.value).durchschnitt,
        ),
    ]..sort((a, b) => a.kriterium.compareTo(b.kriterium));
  }

  List<Zeitwert> _preisverlauf(AuswertungsFilter filter) {
    final rows = _db.verbindung.select('''
      SELECT pb.beobachtet_am, pb.betrag_minor, pb.waehrung,
        COALESCE(o.name, 'Ohne Ort') AS ort_name,
        COALESCE(prod.name, 'Gelöschtes Produkt') AS produkt_name
      FROM preisbeobachtungen pb
      LEFT JOIN orte o ON o.id = pb.ort_id
      LEFT JOIN objekte prod ON prod.id = pb.produkt_id
      LEFT JOIN produkt_kategorien pk ON pk.produkt_id = pb.produkt_id
      WHERE (? IS NULL OR
          (? = 'produkt' AND pb.produkt_id = ?) OR
          (? = 'ort' AND pb.ort_id = ?))
        AND (? IS NULL OR pk.kategorie_id = ?)
      ORDER BY pb.beobachtet_am
    ''', [
      filter.objektId,
      filter.objektArt.name,
      filter.objektId,
      filter.objektArt.name,
      filter.objektId,
      filter.kategorieId,
      filter.kategorieId,
    ]);
    return [
      for (final row in rows)
        Zeitwert(
          zeitpunkt: DateTime.parse(row['beobachtet_am']! as String),
          wert: (row['betrag_minor']! as int) / 100,
          beschreibung: filter.objektArt == StatistikObjektart.ort
              ? '${row['produkt_name']} · ${row['ort_name']}'
              : '${row['ort_name']} · ${row['waehrung']}',
          serie: filter.objektArt == StatistikObjektart.ort
              ? '${row['produkt_name']} · ${row['waehrung']}'
              : filter.objektId == null
                  ? row['waehrung']! as String
                  : '${row['ort_name']} · ${row['waehrung']}',
        ),
    ].where((wert) => filter.enthaeltZeitpunkt(wert.zeitpunkt)).toList();
  }

  List<Zeitwert> _ausgabenverlauf(AuswertungsFilter filter) {
    final rows = _db.verbindung.select('''
      SELECT e.id, e.typ,
        COALESCE(e.beginn, MIN(pb.beobachtet_am), e.erstellt_am) AS ereigniszeit,
        pb.waehrung, SUM(pb.betrag_minor * ep.anzahl) AS betrag_minor
      FROM preisbeobachtungen pb
      JOIN erlebnispositionen ep ON ep.id = pb.erlebnis_position_id
      JOIN erlebnisse e ON e.id = pb.erlebnis_id
      LEFT JOIN produkt_kategorien pk ON pk.produkt_id = pb.produkt_id
      WHERE (? IS NULL OR
          (? = 'ort' AND pb.ort_id = ?) OR
          (? = 'produkt' AND pb.produkt_id = ?))
        AND (? IS NULL OR e.herkunft_profil_id = ?)
        AND (? IS NULL OR pk.kategorie_id = ?)
      GROUP BY e.id, e.typ, pb.waehrung
      ORDER BY ereigniszeit
    ''', [
      filter.objektId,
      filter.objektArt.name,
      filter.objektId,
      filter.objektArt.name,
      filter.objektId,
      filter.herkunftProfilId,
      filter.herkunftProfilId,
      filter.kategorieId,
      filter.kategorieId,
    ]);
    final ergebnis = <Zeitwert>[];
    for (final row in rows) {
      final zeit = DateTime.tryParse(row['ereigniszeit'] as String? ?? '');
      if (zeit == null || !filter.enthaeltZeitpunkt(zeit)) continue;
      ergebnis.add(
        Zeitwert(
          zeitpunkt: zeit,
          wert: (row['betrag_minor']! as int) / 100,
          beschreibung: 'Tatsächliche Ausgaben',
          serie: row['waehrung']! as String,
        ),
      );
    }
    return ergebnis;
  }

  List<Zeitwert> _qualitaetsverlauf(AuswertungsFilter filter) =>
      _bewertungsRows(filter)
          .where((row) =>
              row['eingabetyp'] == 'wertung' &&
              row['wert'] != null &&
              row['produkt_id'] != null)
          .map(
            (row) => Zeitwert(
              zeitpunkt: DateTime.parse(row['ereigniszeit']! as String),
              wert: (row['wert']! as num).toDouble(),
              beschreibung:
                  '${row['kriterium_name']} · Version ${row['kriterium_version']}',
              serie: 'Produkt',
            ),
          )
          .toList(growable: false);

  List<Zeitwert> _ortsverlauf(AuswertungsFilter filter) =>
      _bewertungsRows(filter)
          .where((row) =>
              row['eingabetyp'] == 'wertung' &&
              row['wert'] != null &&
              row['ort_id'] != null)
          .map(
            (row) => Zeitwert(
              zeitpunkt: DateTime.parse(row['ereigniszeit']! as String),
              wert: (row['wert']! as num).toDouble(),
              beschreibung:
                  '${row['kriterium_name']} · Version ${row['kriterium_version']}',
              serie: 'Ort',
            ),
          )
          .toList(growable: false);

  List<ErlebnisGruppe> _erlebnisgruppen(AuswertungsFilter filter) {
    final rows = _db.verbindung.select('''
      SELECT e.id, e.typ, e.beginn, e.ende,
        COALESCE(e.ort_id, e.konsumort_id, e.kaufort_id) AS ort_id
      FROM erlebnisse e
      WHERE (? IS NULL OR
          (? = 'ort' AND
            COALESCE(e.ort_id, e.konsumort_id, e.kaufort_id) = ?) OR
          (? = 'produkt' AND EXISTS (
            SELECT 1 FROM erlebnispositionen ep
            WHERE ep.erlebnis_id = e.id AND ep.produkt_id = ?
          )))
        AND (? IS NULL OR e.herkunft_profil_id = ?)
        AND e.ende IS NOT NULL
    ''', [
      filter.objektId,
      filter.objektArt.name,
      filter.objektId,
      filter.objektArt.name,
      filter.objektId,
      filter.herkunftProfilId,
      filter.herkunftProfilId,
    ]);
    final gruppen = <String, (int, int)>{};
    for (final row in rows) {
      final beginn = DateTime.tryParse(row['beginn'] as String? ?? '');
      final ende = DateTime.tryParse(row['ende'] as String? ?? '');
      if (beginn == null || !filter.enthaeltZeitpunkt(beginn)) continue;
      final tageszeit = beginn.hour < 11
          ? 'morgens'
          : beginn.hour < 17
              ? 'tagsüber'
              : 'abends';
      final key = '${row['typ']} · Wochentag ${beginn.weekday} · $tageszeit';
      final bisher = gruppen[key] ?? (0, 0);
      final dauer = ende == null
          ? 0
          : ende.difference(beginn).inMinutes.clamp(0, 24 * 60);
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

  List<Zeitwert> _auffaelligkeiten(AuswertungsFilter filter) {
    const schwelle = 2.0;
    final gruppen = <(int, int, String, int), List<(double, DateTime)>>{};
    final namen = <(int, int, String, int), String>{};
    final gruppenErlebnisse = <(int, int, String, int), List<String>>{};
    for (final row in _bewertungsRows(filter)) {
      if (row['eingabetyp'] != 'wertung' || row['wert'] == null) continue;
      final zeit = DateTime.tryParse(row['ereigniszeit'] as String? ?? '');
      if (zeit == null) continue;
      final version = row['kriterium_version']! as int;
      final key = (
        zeit.weekday,
        zeit.hour,
        row['kriterium_id']! as String,
        version,
      );
      gruppen
          .putIfAbsent(key, () => [])
          .add(((row['wert']! as num).toDouble(), zeit));
      gruppenErlebnisse
          .putIfAbsent(key, () => [])
          .add(row['erlebnis_id']! as String);
      namen[key] = row['kriterium_name']! as String;
    }

    final ergebnis = <Zeitwert>[];
    for (final eintrag in gruppen.entries) {
      final stichprobe = eintrag.value;
      final niedrigeWertungen =
          stichprobe.where((wert) => wert.$1 <= schwelle).toList();
      final niedrigeWochen = niedrigeWertungen.map((wert) {
        final zeit = wert.$2.toLocal();
        return DateTime(zeit.year, zeit.month, zeit.day)
            .subtract(Duration(days: zeit.weekday - DateTime.monday));
      }).toSet();
      if (stichprobe.length < 3 ||
          niedrigeWertungen.length < 2 ||
          niedrigeWochen.length < 2) {
        continue;
      }
      final wochentag = eintrag.key.$1;
      final stunde = eintrag.key.$2.toString().padLeft(2, '0');
      ergebnis.add(
        Zeitwert(
          zeitpunkt: DateTime(2000, 1, 3 + wochentag - 1, eintrag.key.$2),
          zeitpunktBeschriftung: 'Wochentag $wochentag · $stunde:00 Uhr',
          wert: niedrigeWertungen.length.toDouble(),
          beschreibung: '${namen[eintrag.key]} · Version ${eintrag.key.$4} · '
              '${niedrigeWertungen.length} von ${stichprobe.length} höchstens 2 '
              'an ${niedrigeWochen.length} Wochen',
          erlebnisIds: gruppenErlebnisse[eintrag.key]!.toSet().toList(),
          serie: 'Wiederkehrende niedrige Wertungen',
        ),
      );
    }
    return ergebnis..sort((a, b) => a.zeitpunkt.compareTo(b.zeitpunkt));
  }

  List<Zeitwert> _andrang(AuswertungsFilter filter) {
    final rows = _db.verbindung.select('''
      SELECT b.wert, ob.bewertet_am, o.name
      FROM bewertungen b
      JOIN ortsbewertungen ob ON ob.id = b.ortsbewertung_id
      JOIN orte o ON o.id = ob.ort_id
      WHERE COALESCE(b.kriterium_name, '') = 'Andrang / Auslastung'
        AND (? IS NULL OR
          (? = 'ort' AND ob.ort_id = ?) OR
          (? = 'produkt' AND 0))
        AND (? IS NULL OR b.kriterium_id = ?)
        AND (? IS NULL OR b.herkunft_profil_id = ?)
      ORDER BY ob.bewertet_am
    ''', [
      filter.objektId,
      filter.objektArt.name,
      filter.objektId,
      filter.objektArt.name,
      filter.kriteriumId,
      filter.kriteriumId,
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
    ].where((wert) => filter.enthaeltZeitpunkt(wert.zeitpunkt)).toList();
  }
}
