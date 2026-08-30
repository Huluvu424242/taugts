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
  Future<List<Produkt>> ladeProdukte({String suchtext = ''}) async {
    final suche = '%${suchtext.trim().toLowerCase()}%';
    final rows = datenbank.verbindung.select('''
      SELECT o.*, p.* FROM objekte o
      JOIN produkte p ON p.objekt_id = o.id
      WHERE ? = '%%'
         OR LOWER(o.name) LIKE ?
         OR LOWER(COALESCE(p.marke, '')) LIKE ?
         OR LOWER(COALESCE(p.brauerei, '')) LIKE ?
         OR LOWER(COALESCE(p.sorte, '')) LIKE ?
         OR LOWER(COALESCE(p.barcode, '')) LIKE ?
      ORDER BY o.geaendert_am DESC, o.name COLLATE NOCASE
    ''', [suche, suche, suche, suche, suche, suche]);
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
    final zeitfehler = erlebnis.zeitfehler;
    if (zeitfehler.isNotEmpty) {
      throw ArgumentError.value(erlebnis, 'erlebnis', zeitfehler.join(' '));
    }
    _speichereErlebnisZeile(erlebnis);
  }

  void _speichereErlebnisZeile(Erlebnis erlebnis) {
    datenbank.verbindung.execute(
      '''
        INSERT INTO erlebnisse (
          id, typ, status, ort_id, geplanter_tag, geplante_minute,
          geplante_dauer_minuten, tatsaechlicher_beginn, tatsaechliches_ende,
          erstellt_am, geaendert_am, herkunft_profil_id, notiz, ist_entwurf,
          produkt_id, kaufort_id, konsumort_id, erlebt_am, preis, menge, gebinde
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          typ = excluded.typ,
          status = excluded.status,
          ort_id = excluded.ort_id,
          geplanter_tag = excluded.geplanter_tag,
          geplante_minute = excluded.geplante_minute,
          geplante_dauer_minuten = excluded.geplante_dauer_minuten,
          tatsaechlicher_beginn = excluded.tatsaechlicher_beginn,
          tatsaechliches_ende = excluded.tatsaechliches_ende,
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
        erlebnis.typ.name,
        erlebnis.status.name,
        erlebnis.ortId,
        erlebnis.geplanterTag == null
            ? null
            : _datum(erlebnis.geplanterTag!),
        erlebnis.geplanteMinute,
        erlebnis.geplanteDauerMinuten,
        _optionaleZeit(erlebnis.tatsaechlicherBeginn),
        _optionaleZeit(erlebnis.tatsaechlichesEnde),
        _zeit(erlebnis.erstelltAm),
        _zeit(erlebnis.geaendertAm),
        erlebnis.herkunftProfilId,
        _leerAlsNull(erlebnis.notiz),
        erlebnis.istEntwurf ? 1 : 0,
        erlebnis.produktId,
        erlebnis.kaufortId,
        erlebnis.konsumortId,
        _zeit(erlebnis.erlebtAm),
        erlebnis.preis,
        erlebnis.menge,
        _leerAlsNull(erlebnis.gebinde),
      ],
    );
  }

  @override
  Future<Erlebnis?> ladeErlebnis(String id) async {
    final rows = datenbank.verbindung.select(
      'SELECT * FROM erlebnisse WHERE id = ?',
      [id],
    );
    return rows.isEmpty ? null : _erlebnisAusZeile(rows.single);
  }

  @override
  Future<List<Erlebnis>> ladeErlebnisse() async => datenbank.verbindung
      .select(
        'SELECT * FROM erlebnisse '
        'ORDER BY COALESCE(tatsaechlicher_beginn, geplanter_tag, erstellt_am) '
        'DESC, geaendert_am DESC',
      )
      .map(_erlebnisAusZeile)
      .toList();

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
        typ: Erlebnistyp.values.byName(row['typ'] as String),
        status: Erlebnisstatus.values.byName(row['status'] as String),
        ortId: row['ort_id'] as String?,
        geplanterTag: _optionalesDatum(row['geplanter_tag'] as String?),
        geplanteMinute: row['geplante_minute'] as int?,
        geplanteDauerMinuten: row['geplante_dauer_minuten'] as int?,
        tatsaechlicherBeginn:
            _optionalesDatum(row['tatsaechlicher_beginn'] as String?),
        tatsaechlichesEnde:
            _optionalesDatum(row['tatsaechliches_ende'] as String?),
        produktId: row['produkt_id'] as String?,
        kaufortId: row['kaufort_id'] as String?,
        konsumortId: row['konsumort_id'] as String?,
        herkunftProfilId: row['herkunft_profil_id'] as String,
        erlebtAm: _optionalesDatum(row['erlebt_am'] as String?),
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
        INSERT INTO kriterien (
          id, name, beschreibung, eingabetyp, reihenfolge, aktiv,
          erstellt_am, geaendert_am
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          name = excluded.name,
          beschreibung = excluded.beschreibung,
          eingabetyp = excluded.eingabetyp,
          reihenfolge = excluded.reihenfolge,
          aktiv = excluded.aktiv,
          geaendert_am = excluded.geaendert_am
      ''',
      [
        kriterium.id,
        kriterium.name,
        _leerAlsNull(kriterium.beschreibung),
        kriterium.eingabetyp.name,
        kriterium.reihenfolge,
        kriterium.aktiv ? 1 : 0,
        _zeit(kriterium.erstelltAm),
        _zeit(kriterium.geaendertAm),
      ],
    );
  }

  @override
  Future<List<Bewertungskriterium>> ladeAktiveGetraenkekriterien() async {
    final rows = datenbank.verbindung.select(
      'SELECT * FROM kriterien WHERE aktiv = 1 '
      'ORDER BY reihenfolge, name COLLATE NOCASE',
    );
    return rows
        .map(
          (row) => Bewertungskriterium(
            id: row['id'] as String,
            name: row['name'] as String,
            beschreibung: row['beschreibung'] as String?,
            eingabetyp: KriteriumEingabetyp.values.byName(
              row['eingabetyp'] as String,
            ),
            reihenfolge: row['reihenfolge'] as int,
            aktiv: (row['aktiv'] as int) == 1,
            erstelltAm: DateTime.parse(row['erstellt_am'] as String),
            geaendertAm: DateTime.parse(row['geaendert_am'] as String),
          ),
        )
        .toList();
  }

  @override
  Future<void> speichereBewertung(Bewertung bewertung) async =>
      _speichereBewertungZeile(bewertung);

  void _speichereBewertungZeile(Bewertung bewertung) {
    datenbank.verbindung.execute(
      '''
        INSERT INTO bewertungen (
          id, erlebnis_id, kriterium_id, wert, erstellt_am, geaendert_am,
          herkunft_profil_id
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
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
  Future<void> speichereGetraenkebewertung({
    required Erlebnis erlebnis,
    required List<Bewertung> bewertungen,
  }) async {
    if (bewertungen.any(
      (bewertung) =>
          bewertung.erlebnisId != erlebnis.id ||
          bewertung.herkunftProfilId != erlebnis.herkunftProfilId,
    )) {
      throw ArgumentError(
        'Alle Bewertungen müssen zum Erlebnis und dessen Profil gehören.',
      );
    }
    datenbank.transaktion(() {
      _speichereErlebnisZeile(erlebnis);
      datenbank.verbindung.execute(
        'DELETE FROM bewertungen '
        'WHERE erlebnis_id = ? AND herkunft_profil_id = ?',
        [erlebnis.id, erlebnis.herkunftProfilId],
      );
      for (final bewertung in bewertungen) {
        _speichereBewertungZeile(bewertung);
      }
    });
  }

  @override
  Future<List<Bewertung>> ladeBewertungenFuerErlebnis(
    String erlebnisId,
  ) async {
    final rows = datenbank.verbindung.select(
      'SELECT * FROM bewertungen WHERE erlebnis_id = ? '
      'ORDER BY erstellt_am, kriterium_id',
      [erlebnisId],
    );
    return rows.map(_bewertungAusZeile).toList();
  }

  Bewertung _bewertungAusZeile(Map<String, Object?> row) => Bewertung(
        id: row['id'] as String,
        erlebnisId: row['erlebnis_id'] as String,
        kriteriumId: row['kriterium_id'] as String,
        herkunftProfilId: row['herkunft_profil_id'] as String,
        wert: (row['wert'] as num).toDouble(),
        erstelltAm: DateTime.parse(row['erstellt_am'] as String),
        geaendertAm: DateTime.parse(row['geaendert_am'] as String),
      );

  @override
  Future<List<Bewertung>> ladeBewertungenFuerProdukt(String produktId) async {
    final rows = datenbank.verbindung.select('''
      SELECT b.* FROM bewertungen b JOIN erlebnisse e ON e.id = b.erlebnis_id
      WHERE e.produkt_id = ? ORDER BY b.erstellt_am
    ''', [produktId]);
    return rows.map(_bewertungAusZeile).toList();
  }

  String _zeit(DateTime wert) => wert.toUtc().toIso8601String();

  String _datum(DateTime wert) =>
      '${wert.year.toString().padLeft(4, '0')}-'
      '${wert.month.toString().padLeft(2, '0')}-'
      '${wert.day.toString().padLeft(2, '0')}';

  String? _optionaleZeit(DateTime? wert) =>
      wert == null ? null : _zeit(wert);

  DateTime? _optionalesDatum(String? wert) =>
      wert == null ? null : DateTime.parse(wert);

  String? _leerAlsNull(String? wert) {
    final getrimmt = wert?.trim();
    return getrimmt == null || getrimmt.isEmpty ? null : getrimmt;
  }
}
