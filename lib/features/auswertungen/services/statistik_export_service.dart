import 'package:taugts/features/auswertungen/models/statistik_export_modelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';

abstract interface class StatistikExportService {
  Future<StatistikExportDaten> ladeDaten();
}

class SqliteStatistikExportService implements StatistikExportService {
  const SqliteStatistikExportService(this._db);

  final LokaleDatenbank _db;

  @override
  Future<StatistikExportDaten> ladeDaten() async => StatistikExportDaten(
        produktbewertungen: _produktbewertungen(),
        ortsbewertungen: _ortsbewertungen(),
        ortsverlauf: _ortsverlauf(),
      );

  List<ProduktOrtKennzahlen> _produktbewertungen() {
    final rows = _db.verbindung.select('''
      SELECT
        obj.id AS produkt_id,
        obj.name AS produkt_name,
        COALESCE(ort.id, '') AS ort_id,
        COALESCE(ort.name, 'Ohne Ort') AS ort_name,
        b.wert
      FROM bewertungen b
      JOIN erlebnispositionen ep ON ep.id = b.erlebnis_position_id
      JOIN objekte obj ON obj.id = ep.produkt_id
      JOIN erlebnisse e ON e.id = ep.erlebnis_id
      LEFT JOIN orte ort
        ON ort.id = COALESCE(e.konsumort_id, e.kaufort_id, e.ort_id)
      LEFT JOIN kriterien k ON k.id = b.kriterium_id
      WHERE b.wert IS NOT NULL
        AND COALESCE(b.kriterium_eingabetyp, k.eingabetyp, 'wertung') = 'wertung'
      ORDER BY obj.name, ort_name, b.erstellt_am
    ''');

    final gruppen = <String, _WertGruppe>{};
    for (final row in rows) {
      final produktId = row['produkt_id']! as String;
      final ortId = row['ort_id']! as String;
      final key = '$produktId\u0000$ortId';
      gruppen
          .putIfAbsent(
            key,
            () => _WertGruppe(
              objektId: produktId,
              objektName: row['produkt_name']! as String,
              ortId: ortId,
              ortName: row['ort_name']! as String,
            ),
          )
          .werte
          .add((row['wert']! as num).toDouble());
    }

    final ergebnis = [
      for (final gruppe in gruppen.values)
        ProduktOrtKennzahlen(
          produktId: gruppe.objektId,
          produktName: gruppe.objektName,
          ortId: gruppe.ortId,
          ortName: gruppe.ortName,
          kennzahlen: _kennzahlen(gruppe.werte),
        ),
    ];
    ergebnis.sort((a, b) {
      final produkt = a.produktName.compareTo(b.produktName);
      return produkt != 0 ? produkt : a.ortName.compareTo(b.ortName);
    });
    return ergebnis;
  }

  List<OrtsKennzahlen> _ortsbewertungen() {
    final rows = _ortsbewertungsRows();
    final gruppen = <String, _WertGruppe>{};
    for (final row in rows) {
      final ortId = row['ort_id']! as String;
      gruppen
          .putIfAbsent(
            ortId,
            () => _WertGruppe(
              objektId: ortId,
              objektName: row['ort_name']! as String,
              ortId: ortId,
              ortName: row['ort_name']! as String,
            ),
          )
          .werte
          .add((row['wert']! as num).toDouble());
    }

    final ergebnis = [
      for (final gruppe in gruppen.values)
        OrtsKennzahlen(
          ortId: gruppe.ortId,
          ortName: gruppe.ortName,
          kennzahlen: _kennzahlen(gruppe.werte),
        ),
    ]..sort((a, b) => a.ortName.compareTo(b.ortName));
    return ergebnis;
  }

  List<OrtsVerlaufsPunkt> _ortsverlauf() {
    final rows = _ortsbewertungsRows();
    final gruppen = <String, _VerlaufsGruppe>{};
    for (final row in rows) {
      final ortId = row['ort_id']! as String;
      final bewertungId = row['ortsbewertung_id']! as String;
      final key = '$ortId\u0000$bewertungId';
      gruppen
          .putIfAbsent(
            key,
            () => _VerlaufsGruppe(
              ortId: ortId,
              ortName: row['ort_name']! as String,
              zeitpunkt: DateTime.parse(row['bewertet_am']! as String),
            ),
          )
          .werte
          .add((row['wert']! as num).toDouble());
    }

    final ergebnis = [
      for (final gruppe in gruppen.values)
        OrtsVerlaufsPunkt(
          ortId: gruppe.ortId,
          ortName: gruppe.ortName,
          zeitpunkt: gruppe.zeitpunkt,
          durchschnitt: _kennzahlen(gruppe.werte).durchschnitt,
        ),
    ];
    ergebnis.sort((a, b) {
      final zeit = a.zeitpunkt.compareTo(b.zeitpunkt);
      return zeit != 0 ? zeit : a.ortName.compareTo(b.ortName);
    });
    return ergebnis;
  }

  List<Map<String, Object?>> _ortsbewertungsRows() =>
      _db.verbindung.select('''
        SELECT
          ob.id AS ortsbewertung_id,
          ob.ort_id,
          ort.name AS ort_name,
          ob.bewertet_am,
          b.wert
        FROM bewertungen b
        JOIN ortsbewertungen ob ON ob.id = b.ortsbewertung_id
        JOIN orte ort ON ort.id = ob.ort_id
        LEFT JOIN kriterien k ON k.id = b.kriterium_id
        WHERE b.wert IS NOT NULL
          AND COALESCE(b.kriterium_eingabetyp, k.eingabetyp, 'wertung') = 'wertung'
        ORDER BY ob.bewertet_am, ort.name
      ''').cast<Map<String, Object?>>();

  BewertungsKennzahlen _kennzahlen(List<double> werte) {
    final summe = werte.fold<double>(0, (summe, wert) => summe + wert);
    return BewertungsKennzahlen(
      beste: werte.reduce((a, b) => a > b ? a : b),
      schlechteste: werte.reduce((a, b) => a < b ? a : b),
      durchschnitt: summe / werte.length,
      anzahl: werte.length,
    );
  }
}

class _WertGruppe {
  _WertGruppe({
    required this.objektId,
    required this.objektName,
    required this.ortId,
    required this.ortName,
  });

  final String objektId;
  final String objektName;
  final String ortId;
  final String ortName;
  final List<double> werte = [];
}

class _VerlaufsGruppe {
  _VerlaufsGruppe({
    required this.ortId,
    required this.ortName,
    required this.zeitpunkt,
  });

  final String ortId;
  final String ortName;
  final DateTime zeitpunkt;
  final List<double> werte = [];
}
