import 'package:taugts/features/auswertungen/models/produktvergleich_modelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';

/// Vergleicht dokumentierte Käufe. Keine Abfrage aktueller Marktpreise.
class SqliteProduktpreisvergleichService implements ProduktPreisvergleichService {
  const SqliteProduktpreisvergleichService(this._db);

  final LokaleDatenbank _db;

  @override
  Future<List<ProduktPreisRang>> ladeLetztePreise(
    ProduktvergleichFilter filter,
  ) async {
    final rows = _db.verbindung.select(
      '''
      SELECT pb.id AS preis_id, pb.betrag_minor, pb.waehrung,
        pb.beobachtet_am, COALESCE(e.beginn, pb.beobachtet_am) AS zeitpunkt,
        o.id AS ort_id, o.name AS ort_name, o.typ AS ort_typ,
        p.fuellmenge_ml
      FROM preisbeobachtungen pb
      JOIN erlebnisse e ON e.id = pb.erlebnis_id
      JOIN erlebnispositionen ep ON ep.id = pb.erlebnis_position_id
        AND ep.produkt_id = pb.produkt_id
      JOIN produkte p ON p.objekt_id = pb.produkt_id
      LEFT JOIN orte o ON o.id = COALESCE(
        pb.ort_id, e.ort_id, e.konsumort_id, e.kaufort_id
      )
      WHERE pb.produkt_id = ?
      ORDER BY zeitpunkt DESC, pb.beobachtet_am DESC, pb.id DESC
      ''',
      [filter.produktId],
    );
    final letzte = <String, ProduktPreisRang>{};
    for (final row in rows) {
      final ortId = row['ort_id'] as String?;
      final ortTyp = row['ort_typ'] as String?;
      if (ortId == null ||
          ortTyp == null ||
          !filter.enthaeltOrtstyp(ortTyp)) {
        continue;
      }
      final zeit = DateTime.tryParse(row['zeitpunkt'] as String? ?? '');
      if (zeit == null || !filter.enthaelt(zeit)) {
        continue;
      }
      // Die Sortierung stellt sicher, dass der erste Treffer der letzte
      // dokumentierte Kauf ist; ältere Käufe ersetzen ihn niemals.
      if (letzte.containsKey(ortId)) {
        continue;
      }
      final minor = row['betrag_minor'] as int;
      final waehrung = row['waehrung'] as String;
      final menge = row['fuellmenge_ml'] as int?;
      final grund = waehrung != 'EUR'
          ? 'Währung $waehrung wird nicht umgerechnet.'
          : menge == null || menge <= 0
          ? 'Keine positive Füllmenge für dieses Produkt erfasst.'
          : null;
      final preis = minor / 100;
      letzte[ortId] = ProduktPreisRang(
        ortId: ortId,
        ortName: row['ort_name'] as String,
        ortTyp: ortTyp,
        zeitpunkt: zeit,
        preisId: row['preis_id'] as String,
        preis: preis,
        waehrung: waehrung,
        mengeMl: menge,
        euroProLiter: grund == null ? preis * 1000 / menge! : null,
        nichtVergleichbar: grund,
      );
    }
    return letzte.values.toList()
      ..sort((a, b) {
        if (a.euroProLiter == null) return b.euroProLiter == null
            ? a.ortName.compareTo(b.ortName)
            : 1;
        if (b.euroProLiter == null) return -1;
        final cmp = a.euroProLiter!.compareTo(b.euroProLiter!);
        return cmp == 0 ? a.ortName.compareTo(b.ortName) : cmp;
      });
  }
}
