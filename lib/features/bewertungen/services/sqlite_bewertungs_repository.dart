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
    if (ort.name.trim().isEmpty) {
      throw ArgumentError.value(ort, 'ort', 'Der Name ist erforderlich.');
    }
    datenbank.verbindung.execute(
      '''
        INSERT INTO orte (
          id, name, typ, erstellt_am, geaendert_am, adresse,
          breitengrad, laengengrad, osm_referenz, notiz
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          name = excluded.name,
          typ = excluded.typ,
          geaendert_am = excluded.geaendert_am,
          adresse = excluded.adresse,
          breitengrad = excluded.breitengrad,
          laengengrad = excluded.laengengrad,
          osm_referenz = excluded.osm_referenz,
          notiz = excluded.notiz
      ''',
      [
        ort.id,
        ort.name.trim(),
        ort.typ.name,
        _zeit(ort.erstelltAm),
        _zeit(ort.geaendertAm),
        _leerAlsNull(ort.adresse),
        ort.breitengrad,
        ort.laengengrad,
        _leerAlsNull(ort.osmReferenz),
        _leerAlsNull(ort.notiz),
      ],
    );
  }

  @override
  Future<Ort?> ladeOrt(String id) async {
    final rows = datenbank.verbindung.select(
      'SELECT * FROM orte WHERE id = ?',
      [id],
    );
    return rows.isEmpty ? null : _ortAusZeile(rows.single);
  }

  @override
  Future<List<Ort>> ladeOrte({String suchtext = ''}) async {
    final suche = '%${suchtext.trim().toLowerCase()}%';
    final rows = datenbank.verbindung.select(
      '''
        SELECT * FROM orte
        WHERE ? = '%%'
           OR LOWER(name) LIKE ?
           OR LOWER(typ) LIKE ?
           OR LOWER(COALESCE(adresse, '')) LIKE ?
           OR LOWER(COALESCE(osm_referenz, '')) LIKE ?
        ORDER BY name COLLATE NOCASE, geaendert_am DESC
      ''',
      [suche, suche, suche, suche, suche],
    );
    return rows.map(_ortAusZeile).toList();
  }

  @override
  Future<List<Ort>> findeAehnlicheOrte({
    required String name,
    String? adresse,
    String? ausgenommenId,
  }) async {
    final normalisierterName = name.trim().toLowerCase();
    final normalisierteAdresse = adresse?.trim().toLowerCase();
    final rows = datenbank.verbindung.select(
      '''
        SELECT * FROM orte
        WHERE LOWER(TRIM(name)) = ?
          AND (? IS NULL OR id <> ?)
        ORDER BY name COLLATE NOCASE
      ''',
      [normalisierterName, ausgenommenId, ausgenommenId],
    );
    final orte = rows.map(_ortAusZeile);
    if (normalisierteAdresse == null || normalisierteAdresse.isEmpty) {
      return orte.toList();
    }
    return orte.where((ort) {
      final vorhandeneAdresse = ort.adresse?.trim().toLowerCase();
      return vorhandeneAdresse == null ||
          vorhandeneAdresse.isEmpty ||
          vorhandeneAdresse == normalisierteAdresse;
    }).toList();
  }

  Ort _ortAusZeile(Map<String, Object?> row) => Ort(
        id: row['id'] as String,
        name: row['name'] as String,
        typ: Ortstyp.values.byName(row['typ'] as String),
        adresse: row['adresse'] as String?,
        breitengrad: (row['breitengrad'] as num?)?.toDouble(),
        laengengrad: (row['laengengrad'] as num?)?.toDouble(),
        osmReferenz: row['osm_referenz'] as String?,
        notiz: row['notiz'] as String?,
        erstelltAm: DateTime.parse(row['erstellt_am'] as String),
        geaendertAm: DateTime.parse(row['geaendert_am'] as String),
      );

  @override
  Future<void> speichereErlebnis(Erlebnis erlebnis) async {
    datenbank.verbindung.execute(
      '''
        INSERT INTO erlebnisse (
          id, produkt_id, kaufort_id, konsumort_id, erlebt_am, erstellt_am,
          geaendert_am, herkunft_profil_id, preis, menge, gebinde, notiz,
          ist_entwurf
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          produkt_id = excluded.produkt_id,
          kaufort_id = excluded.kaufort_id,
          konsumort_id = excluded.konsumort_id,
          erlebt_am = excluded.erlebt_am,
          geaendert_am = excluded.geaendert_am,
          preis = excluded.preis,
          menge = excluded.menge,
          gebinde = excluded.gebinde,
          notiz = excluded.notiz,
          ist_entwurf = excluded.ist_entwurf
      ''',
      [
        erlebnis.id,
        erlebnis.produktId,
        erlebnis.kaufortId,
        erlebnis.konsumortId,
        _zeit(erlebnis.erlebtAm),
        _zeit(erlebnis.erstelltAm),
        _zeit(erlebnis.geaendertAm),
        erlebnis.herkunftProfilId,
        erlebnis.preis,
        erlebnis.menge,
        _leerAlsNull(erlebnis.gebinde),
        _leerAlsNull(erlebnis.notiz),
        erlebnis.istEntwurf ? 1 : 0,
      ],
    );
  }

  @override
  Future<List<Erlebnis>> ladeEntwuerfe() async => datenbank.verbindung
      .select(
        'SELECT * FROM erlebnisse WHERE ist_entwurf = 1 '
        'ORDER BY geaendert_am DESC',
      )
      .map(_erlebnisAusZeile)
      .toList();

  @override
  Future<void> loescheErlebnis(String id) async {
    datenbank.verbindung.execute('DELETE FROM erlebnisse WHERE id = ?', [id]);
  }

  Erlebnis _erlebnisAusZeile(Map<String, Object?> row) => Erlebnis(
        id: row['id'] as String,
        produktId: row['produkt_id'] as String,
        kaufortId: row['kaufort_id'] as String?,
        konsumortId: row['konsumort_id'] as String?,
        herkunftProfilId: row['herkunft_profil_id'] as String,
        erlebtAm: DateTime.parse(row['erlebt_am'] as String),
        erstelltAm: DateTime.parse(row['erstellt_am'] as String),
        geaendertAm: DateTime.parse(row['geaendert_am'] as String),
        preis: (row['preis'] as num?)?.toDouble(),
        menge: (row['menge'] as num?)?.toDouble(),
        gebinde: row['gebinde'] as String?,
        notiz: row['notiz'] as String?,
        istEntwurf: (row['ist_entwurf'] as int) == 1,
      );

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
