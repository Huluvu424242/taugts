import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';

class SqliteBewertungsRepository implements BewertungsRepository {
  SqliteBewertungsRepository(this.datenbank);

  final LokaleDatenbank datenbank;

  @override
  Future<void> speichereProdukt(Produkt produkt) async {
    if (!produkt.hatMinimalangabe) {
      throw ArgumentError.value(
        produkt,
        'produkt',
        'Name oder Barcode ist erforderlich.',
      );
    }
    datenbank.transaktion(() {
      datenbank.verbindung.execute(
        '''
          INSERT INTO objekte VALUES (?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            name = excluded.name,
            art = excluded.art,
            geaendert_am = excluded.geaendert_am
        ''',
        [
          produkt.id,
          produkt.name,
          produkt.art.name,
          _zeit(produkt.erstelltAm),
          _zeit(produkt.geaendertAm),
        ],
      );
      datenbank.verbindung.execute(
        '''
          INSERT INTO produkte (
            objekt_id, marke, produktart, brauerei, sorte, alkoholgehalt,
            herkunft, gebinde, fuellmenge_ml, barcode, notiz
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(objekt_id) DO UPDATE SET
            marke = excluded.marke,
            produktart = excluded.produktart,
            brauerei = excluded.brauerei,
            sorte = excluded.sorte,
            alkoholgehalt = excluded.alkoholgehalt,
            herkunft = excluded.herkunft,
            gebinde = excluded.gebinde,
            fuellmenge_ml = excluded.fuellmenge_ml,
            barcode = excluded.barcode,
            notiz = excluded.notiz
        ''',
        [
          produkt.id,
          _leerAlsNull(produkt.marke),
          produkt.produktart.name,
          _leerAlsNull(produkt.brauerei),
          _leerAlsNull(produkt.sorte),
          produkt.alkoholgehalt,
          _leerAlsNull(produkt.herkunft),
          _leerAlsNull(produkt.gebinde),
          produkt.fuellmengeMl,
          _leerAlsNull(produkt.barcode),
          _leerAlsNull(produkt.notiz),
        ],
      );
    });
  }

  @override
  Future<Produkt?> ladeProdukt(String id) async {
    final rows = datenbank.verbindung.select('''
      SELECT o.*, p.* FROM objekte o
      JOIN produkte p ON p.objekt_id = o.id WHERE o.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    final row = rows.single;
    return _produktAusZeile(row);
  }

  @override
  Future<List<Produkt>> ladeProdukte() async {
    final rows = datenbank.verbindung.select('''
      SELECT o.*, p.* FROM objekte o
      JOIN produkte p ON p.objekt_id = o.id
      ORDER BY o.geaendert_am DESC, o.name COLLATE NOCASE
    ''');
    return rows.map(_produktAusZeile).toList();
  }

  Produkt _produktAusZeile(Map<String, Object?> row) {
    return Produkt(
      id: row['id'] as String,
      name: row['name'] as String,
      produktart: Produktart.values.byName(row['produktart'] as String),
      marke: row['marke'] as String?,
      brauerei: row['brauerei'] as String?,
      sorte: row['sorte'] as String?,
      alkoholgehalt: (row['alkoholgehalt'] as num?)?.toDouble(),
      herkunft: row['herkunft'] as String?,
      gebinde: row['gebinde'] as String?,
      fuellmengeMl: (row['fuellmenge_ml'] as num?)?.toInt(),
      barcode: row['barcode'] as String?,
      notiz: row['notiz'] as String?,
      erstelltAm: DateTime.parse(row['erstellt_am'] as String),
      geaendertAm: DateTime.parse(row['geaendert_am'] as String),
    );
  }

  @override
  Future<void> speichereOrt(Ort ort) async {
    datenbank.verbindung.execute(
      '''
        INSERT INTO orte VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          name = excluded.name,
          typ = excluded.typ,
          geaendert_am = excluded.geaendert_am
      ''',
      [
        ort.id,
        ort.name,
        ort.typ.name,
        _zeit(ort.erstelltAm),
        _zeit(ort.geaendertAm),
      ],
    );
  }

  @override
  Future<void> speichereErlebnis(Erlebnis erlebnis) async {
    datenbank.verbindung.execute(
      'INSERT INTO erlebnisse VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [
        erlebnis.id,
        erlebnis.produktId,
        erlebnis.kaufortId,
        erlebnis.konsumortId,
        _zeit(erlebnis.erlebtAm),
        _zeit(erlebnis.erstelltAm),
        _zeit(erlebnis.geaendertAm),
        erlebnis.herkunftProfilId,
      ],
    );
  }

  @override
  Future<void> speichereKriterium(Bewertungskriterium kriterium) async {
    datenbank.verbindung.execute(
      '''
        INSERT INTO kriterien VALUES (?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          name = excluded.name,
          geaendert_am = excluded.geaendert_am
      ''',
      [
        kriterium.id,
        kriterium.name,
        _zeit(kriterium.erstelltAm),
        _zeit(kriterium.geaendertAm),
      ],
    );
  }

  @override
  Future<void> speichereBewertung(Bewertung bewertung) async {
    datenbank.verbindung.execute(
      'INSERT INTO bewertungen VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        bewertung.id,
        bewertung.erlebnisId,
        bewertung.kriteriumId,
        bewertung.wert,
        _zeit(bewertung.erstelltAm),
        _zeit(bewertung.geaendertAm),
        bewertung.herkunftProfilId,
      ],
    );
  }

  @override
  Future<List<Bewertung>> ladeBewertungenFuerProdukt(String produktId) async {
    final rows = datenbank.verbindung.select('''
      SELECT b.* FROM bewertungen b JOIN erlebnisse e ON e.id = b.erlebnis_id
      WHERE e.produkt_id = ? ORDER BY b.erstellt_am
    ''', [produktId]);
    return rows
        .map(
          (row) => Bewertung(
            id: row['id'] as String,
            erlebnisId: row['erlebnis_id'] as String,
            kriteriumId: row['kriterium_id'] as String,
            herkunftProfilId: row['herkunft_profil_id'] as String,
            wert: row['wert'] as double,
            erstelltAm: DateTime.parse(row['erstellt_am'] as String),
            geaendertAm: DateTime.parse(row['geaendert_am'] as String),
          ),
        )
        .toList();
  }

  String _zeit(DateTime wert) => wert.toUtc().toIso8601String();

  String? _leerAlsNull(String? wert) {
    final getrimmt = wert?.trim();
    return getrimmt == null || getrimmt.isEmpty ? null : getrimmt;
  }
}
