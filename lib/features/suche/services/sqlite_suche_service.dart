import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/suche/models/suchmodelle.dart';
import 'package:taugts/features/suche/services/suche_service.dart';

class SqliteSucheService implements SucheService {
  SqliteSucheService(this._db) {
    _indizesBereitstellen();
  }

  final LokaleDatenbank _db;

  void _indizesBereitstellen() {
    for (final statement in const [
      'CREATE INDEX IF NOT EXISTS idx_objekte_name ON objekte(name)',
      'CREATE INDEX IF NOT EXISTS idx_produkte_barcode ON produkte(barcode)',
      'CREATE INDEX IF NOT EXISTS idx_orte_name ON orte(name)',
      'CREATE INDEX IF NOT EXISTS idx_erlebnisse_typ_status ON erlebnisse(typ, status)',
      'CREATE INDEX IF NOT EXISTS idx_erlebnisse_zeit ON erlebnisse(tatsaechlicher_beginn, erlebt_am, erstellt_am)',
      'CREATE INDEX IF NOT EXISTS idx_bewertungen_erlebnis ON bewertungen(erlebnis_id)',
      'CREATE INDEX IF NOT EXISTS idx_preise_produkt_ort_zeit ON preisbeobachtungen(produkt_id, ort_id, beobachtet_am)',
    ]) {
      _db.verbindung.execute(statement);
    }
  }

  @override
  Future<List<Suchtreffer>> suche(Suchfilter filter) async => switch (filter.ziel) {
        Suchziel.produkte => _produkte(filter),
        Suchziel.orte => _orte(filter),
        Suchziel.erlebnisse => _erlebnisse(filter),
        Suchziel.historie => _historie(filter),
      };

  List<Suchtreffer> _produkte(Suchfilter filter) {
    final text = '%${filter.text.trim().toLowerCase()}%';
    final rows = _db.verbindung.select('''
      SELECT DISTINCT o.id, o.name, p.marke, p.barcode, p.produktart
      FROM objekte o
      JOIN produkte p ON p.objekt_id = o.id
      LEFT JOIN produkt_kategorien pk ON pk.produkt_id = o.id
      LEFT JOIN kategorien k ON k.id = pk.kategorie_id
      LEFT JOIN objekt_tags t ON t.objekt_id = o.id
      WHERE (? = '%%'
        OR LOWER(o.name) LIKE ?
        OR LOWER(COALESCE(p.marke, '')) LIKE ?
        OR LOWER(COALESCE(p.barcode, '')) LIKE ?
        OR LOWER(COALESCE(k.name, '')) LIKE ?
        OR LOWER(COALESCE(t.text, '')) LIKE ?)
        AND (? IS NULL OR pk.kategorie_id = ?)
      ORDER BY o.name COLLATE NOCASE
      LIMIT 500
    ''', [text, text, text, text, text, text, filter.kategorieId, filter.kategorieId]);
    return [
      for (final row in rows)
        Suchtreffer(
          id: row['id']! as String,
          art: Suchziel.produkte,
          titel: row['name']! as String,
          untertitel:
              '${row['marke'] ?? 'Ohne Marke'} · ${row['produktart']}${row['barcode'] == null ? '' : ' · ${row['barcode']}'}',
          produktId: row['id']! as String,
        ),
    ];
  }

  List<Suchtreffer> _orte(Suchfilter filter) {
    final text = '%${filter.text.trim().toLowerCase()}%';
    final rows = _db.verbindung.select('''
      SELECT DISTINCT o.id, o.name, o.typ, o.adresse
      FROM orte o
      LEFT JOIN ort_kategorien ok ON ok.ort_id = o.id
      LEFT JOIN kategorien k ON k.id = ok.kategorie_id
      LEFT JOIN objekt_tags t ON t.objekt_id = o.id
      WHERE (? = '%%'
        OR LOWER(o.name) LIKE ?
        OR LOWER(o.typ) LIKE ?
        OR LOWER(COALESCE(o.adresse, '')) LIKE ?
        OR LOWER(COALESCE(k.name, '')) LIKE ?
        OR LOWER(COALESCE(t.text, '')) LIKE ?)
        AND (? IS NULL OR ok.kategorie_id = ?)
      ORDER BY o.name COLLATE NOCASE
      LIMIT 500
    ''', [text, text, text, text, text, text, filter.kategorieId, filter.kategorieId]);
    return [
      for (final row in rows)
        Suchtreffer(
          id: row['id']! as String,
          art: Suchziel.orte,
          titel: row['name']! as String,
          untertitel:
              '${row['typ']}${row['adresse'] == null ? '' : ' · ${row['adresse']}'}',
          ortId: row['id']! as String,
        ),
    ];
  }

  List<Suchtreffer> _erlebnisse(Suchfilter filter) {
    final text = '%${filter.text.trim().toLowerCase()}%';
    final von = filter.von?.toUtc().toIso8601String();
    final bis = filter.bis?.toUtc().toIso8601String();
    final rows = _db.verbindung.select('''
      SELECT DISTINCT e.id, e.typ, e.status,
        COALESCE(e.tatsaechlicher_beginn, e.erlebt_am, e.geplanter_tag, e.erstellt_am) AS zeit,
        o.name AS ort_name, COALESCE(e.ort_id, e.konsumort_id, e.kaufort_id) AS ort_id
      FROM erlebnisse e
      LEFT JOIN orte o ON o.id = COALESCE(e.ort_id, e.konsumort_id, e.kaufort_id)
      LEFT JOIN erlebnispositionen ep ON ep.erlebnis_id = e.id
      LEFT JOIN objekte p ON p.id = ep.produkt_id
      WHERE (? = '%%' OR LOWER(COALESCE(o.name, '')) LIKE ? OR LOWER(COALESCE(p.name, '')) LIKE ?)
        AND (? IS NULL OR e.typ = ?)
        AND (? IS NULL OR e.status = ?)
        AND (? IS NULL OR COALESCE(e.ort_id, e.konsumort_id, e.kaufort_id) = ?)
        AND (? IS NULL OR ep.produkt_id = ?)
        AND (? IS NULL OR COALESCE(e.tatsaechlicher_beginn, e.erlebt_am, e.geplanter_tag, e.erstellt_am) >= ?)
        AND (? IS NULL OR COALESCE(e.tatsaechlicher_beginn, e.erlebt_am, e.geplanter_tag, e.erstellt_am) <= ?)
      ORDER BY zeit DESC
      LIMIT 500
    ''', [
      text, text, text,
      filter.erlebnistyp?.name, filter.erlebnistyp?.name,
      filter.erlebnisstatus?.name, filter.erlebnisstatus?.name,
      filter.ortId, filter.ortId,
      filter.produktId, filter.produktId,
      von, von,
      bis, bis,
    ]);
    return [
      for (final row in rows)
        Suchtreffer(
          id: row['id']! as String,
          art: Suchziel.erlebnisse,
          titel: row['typ'] == 'einkauf' ? 'Einkauf' : 'Restaurantbesuch',
          untertitel:
              '${row['status']} · ${row['ort_name'] ?? 'Ohne Ort'} · ${row['zeit']}',
          erlebnisId: row['id']! as String,
          ortId: row['ort_id'] as String?,
          zeitpunkt: DateTime.tryParse(row['zeit']! as String),
        ),
    ];
  }

  List<Suchtreffer> _historie(Suchfilter filter) {
    final ergebnis = <Suchtreffer>[];
    if (filter.historienart == null ||
        filter.historienart == Historienart.produktbewertung) {
      ergebnis.addAll(_produktbewertungen(filter));
    }
    if (filter.historienart == null ||
        filter.historienart == Historienart.gaststaettenbewertung ||
        filter.historienart == Historienart.geschaeftsbewertung) {
      ergebnis.addAll(_ortsbewertungen(filter));
    }
    if (filter.historienart == null ||
        filter.historienart == Historienart.preisbeobachtung) {
      ergebnis.addAll(_preise(filter));
    }
    ergebnis.sort((a, b) =>
        (b.zeitpunkt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          a.zeitpunkt ?? DateTime.fromMillisecondsSinceEpoch(0),
        ));
    return ergebnis.take(500).toList(growable: false);
  }

  List<Suchtreffer> _produktbewertungen(Suchfilter filter) {
    final von = filter.von?.toUtc().toIso8601String();
    final bis = filter.bis?.toUtc().toIso8601String();
    final rows = _db.verbindung.select('''
      SELECT DISTINCT b.id, b.erlebnis_id, ep.produkt_id, p.name AS produkt_name,
        COALESCE(b.kriterium_name, k.name, b.kriterium_id) AS kriterium_name,
        b.wert, b.herkunft_profil_id, b.erstellt_am,
        COALESCE(e.ort_id, e.konsumort_id, e.kaufort_id) AS ort_id,
        o.name AS ort_name
      FROM bewertungen b
      JOIN erlebnispositionen ep ON ep.id = b.erlebnis_position_id
      JOIN objekte p ON p.id = ep.produkt_id
      JOIN erlebnisse e ON e.id = b.erlebnis_id
      LEFT JOIN kriterien k ON k.id = b.kriterium_id
      LEFT JOIN orte o ON o.id = COALESCE(e.ort_id, e.konsumort_id, e.kaufort_id)
      LEFT JOIN produkt_kategorien pk ON pk.produkt_id = ep.produkt_id
      WHERE b.ortsbewertung_id IS NULL
        AND (? IS NULL OR ep.produkt_id = ?)
        AND (? IS NULL OR COALESCE(e.ort_id, e.konsumort_id, e.kaufort_id) = ?)
        AND (? IS NULL OR b.herkunft_profil_id = ?)
        AND (? IS NULL OR pk.kategorie_id = ?)
        AND (? IS NULL OR b.erstellt_am >= ?)
        AND (? IS NULL OR b.erstellt_am <= ?)
      ORDER BY b.erstellt_am DESC
    ''', [
      filter.produktId, filter.produktId,
      filter.ortId, filter.ortId,
      filter.herkunftProfilId, filter.herkunftProfilId,
      filter.kategorieId, filter.kategorieId,
      von, von, bis, bis,
    ]);
    return [
      for (final row in rows)
        Suchtreffer(
          id: row['id']! as String,
          art: Suchziel.historie,
          titel: 'Produktbewertung · ${row['produkt_name']}',
          untertitel:
              '${row['kriterium_name']}: ${row['wert']} · ${row['ort_name'] ?? 'Ohne Ort'}',
          erlebnisId: row['erlebnis_id']! as String,
          produktId: row['produkt_id']! as String,
          ortId: row['ort_id'] as String?,
          zeitpunkt: DateTime.parse(row['erstellt_am']! as String),
        ),
    ];
  }

  List<Suchtreffer> _ortsbewertungen(Suchfilter filter) {
    final von = filter.von?.toUtc().toIso8601String();
    final bis = filter.bis?.toUtc().toIso8601String();
    final rows = _db.verbindung.select('''
      SELECT DISTINCT b.id, b.erlebnis_id, ob.ort_id, o.name AS ort_name, o.typ,
        COALESCE(b.kriterium_name, k.name, b.kriterium_id) AS kriterium_name,
        b.wert, b.herkunft_profil_id, ob.bewertet_am
      FROM bewertungen b
      JOIN ortsbewertungen ob ON ob.id = b.ortsbewertung_id
      JOIN orte o ON o.id = ob.ort_id
      LEFT JOIN kriterien k ON k.id = b.kriterium_id
      LEFT JOIN ort_kategorien ok ON ok.ort_id = ob.ort_id
      WHERE (? IS NULL OR ob.ort_id = ?)
        AND (? IS NULL OR b.herkunft_profil_id = ?)
        AND (? IS NULL OR ok.kategorie_id = ?)
        AND (? IS NULL OR ob.bewertet_am >= ?)
        AND (? IS NULL OR ob.bewertet_am <= ?)
      ORDER BY ob.bewertet_am DESC
    ''', [
      filter.ortId, filter.ortId,
      filter.herkunftProfilId, filter.herkunftProfilId,
      filter.kategorieId, filter.kategorieId,
      von, von, bis, bis,
    ]);
    return [
      for (final row in rows)
        if (_passtOrtshistorienart(row['typ']! as String, filter.historienart))
          Suchtreffer(
            id: row['id']! as String,
            art: Suchziel.historie,
            titel:
                '${row['typ'] == 'geschaeft' ? 'Geschäftsbewertung' : 'Gaststättenbewertung'} · ${row['ort_name']}',
            untertitel: '${row['kriterium_name']}: ${row['wert']}',
            erlebnisId: row['erlebnis_id']! as String,
            ortId: row['ort_id']! as String,
            zeitpunkt: DateTime.parse(row['bewertet_am']! as String),
          ),
    ];
  }

  bool _passtOrtshistorienart(String typ, Historienart? art) {
    if (art == null) return true;
    if (art == Historienart.geschaeftsbewertung) return typ == 'geschaeft';
    if (art == Historienart.gaststaettenbewertung) return typ == 'gastronomie';
    return false;
  }

  List<Suchtreffer> _preise(Suchfilter filter) {
    final von = filter.von?.toUtc().toIso8601String();
    final bis = filter.bis?.toUtc().toIso8601String();
    final rows = _db.verbindung.select('''
      SELECT DISTINCT pb.id, pb.erlebnis_id, pb.produkt_id, pb.ort_id,
        pb.beobachtet_am, pb.betrag_minor, pb.waehrung,
        p.name AS produkt_name, o.name AS ort_name
      FROM preisbeobachtungen pb
      JOIN objekte p ON p.id = pb.produkt_id
      LEFT JOIN orte o ON o.id = pb.ort_id
      LEFT JOIN produkt_kategorien pk ON pk.produkt_id = pb.produkt_id
      WHERE (? IS NULL OR pb.produkt_id = ?)
        AND (? IS NULL OR pb.ort_id = ?)
        AND (? IS NULL OR pk.kategorie_id = ?)
        AND (? IS NULL OR pb.beobachtet_am >= ?)
        AND (? IS NULL OR pb.beobachtet_am <= ?)
      ORDER BY pb.beobachtet_am DESC
    ''', [
      filter.produktId, filter.produktId,
      filter.ortId, filter.ortId,
      filter.kategorieId, filter.kategorieId,
      von, von, bis, bis,
    ]);
    return [
      for (final row in rows)
        Suchtreffer(
          id: row['id']! as String,
          art: Suchziel.historie,
          titel: 'Preisbeobachtung · ${row['produkt_name']}',
          untertitel:
              '${((row['betrag_minor']! as int) / 100).toStringAsFixed(2)} ${row['waehrung']} · ${row['ort_name'] ?? 'Ohne Ort'}',
          erlebnisId: row['erlebnis_id']! as String,
          produktId: row['produkt_id']! as String,
          ortId: row['ort_id'] as String?,
          zeitpunkt: DateTime.parse(row['beobachtet_am']! as String),
        ),
    ];
  }
}
