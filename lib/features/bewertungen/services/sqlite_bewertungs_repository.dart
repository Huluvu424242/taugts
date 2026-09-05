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

  @override
  Future<Produkt?> ladeProduktMitBarcode(String barcode) async {
    final wert = barcode.trim();
    if (wert.isEmpty) return null;
    final rows = datenbank.verbindung.select('''
      SELECT o.*, p.* FROM objekte o
      JOIN produkte p ON p.objekt_id = o.id
      WHERE p.barcode = ? LIMIT 1
    ''', [wert]);
    return rows.isEmpty ? null : _produktAusZeile(rows.single);
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
        erlebnis.geplanterTag == null ? null : _datum(erlebnis.geplanterTag!),
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

  @override
  Future<List<ErlebnispositionMitProdukt>> ladeErlebnispositionen(
    String erlebnisId,
  ) async {
    final rows = datenbank.verbindung.select('''
      SELECT p.id AS position_id, p.erlebnis_id, p.produkt_id, p.anzahl,
        p.erstellt_am AS position_erstellt_am,
        p.geaendert_am AS position_geaendert_am,
        o.*, pr.*, pb.id AS preis_id, pb.ort_id AS preis_ort_id,
        pb.beobachtet_am, pb.betrag_minor, pb.waehrung,
        pb.erstellt_am AS preis_erstellt_am,
        pb.geaendert_am AS preis_geaendert_am
      FROM erlebnispositionen p
      JOIN objekte o ON o.id = p.produkt_id
      JOIN produkte pr ON pr.objekt_id = o.id
      LEFT JOIN preisbeobachtungen pb ON pb.erlebnis_position_id = p.id
      WHERE p.erlebnis_id = ?
      ORDER BY p.erstellt_am, p.id
    ''', [erlebnisId]);
    return rows.map((row) {
      final position = ErlebnisPosition(
        id: row['position_id'] as String,
        erlebnisId: row['erlebnis_id'] as String,
        produktId: row['produkt_id'] as String,
        anzahl: row['anzahl'] as int,
        erstelltAm: DateTime.parse(row['position_erstellt_am'] as String),
        geaendertAm: DateTime.parse(row['position_geaendert_am'] as String),
      );
      final preisId = row['preis_id'] as String?;
      return ErlebnispositionMitProdukt(
        position: position,
        produkt: _produktAusZeile(row),
        preis: preisId == null
            ? null
            : Preisbeobachtung(
                id: preisId,
                erlebnisId: position.erlebnisId,
                erlebnisPositionId: position.id,
                produktId: position.produktId,
                ortId: row['preis_ort_id'] as String?,
                beobachtetAm: DateTime.parse(row['beobachtet_am'] as String),
                betrag: Geldbetrag(
                  minorEinheiten: row['betrag_minor'] as int,
                  waehrung: row['waehrung'] as String,
                ),
                erstelltAm: DateTime.parse(row['preis_erstellt_am'] as String),
                geaendertAm:
                    DateTime.parse(row['preis_geaendert_am'] as String),
              ),
      );
    }).toList();
  }

  @override
  Future<void> speichereErlebnisposition({
    required ErlebnisPosition position,
    Preisbeobachtung? preis,
  }) async {
    if (position.anzahl < 1) {
      throw ArgumentError.value(position.anzahl, 'anzahl');
    }
    if (preis != null &&
        (preis.erlebnisId != position.erlebnisId ||
            preis.erlebnisPositionId != position.id ||
            preis.produktId != position.produktId ||
            preis.betrag.minorEinheiten < 0)) {
      throw ArgumentError('Preis und Erlebnisposition passen nicht zusammen.');
    }
    datenbank.transaktion(() {
      datenbank.verbindung.execute(
        '''
          INSERT INTO erlebnispositionen (
            id, erlebnis_id, produkt_id, anzahl, erstellt_am, geaendert_am
          ) VALUES (?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            produkt_id = excluded.produkt_id,
            anzahl = excluded.anzahl,
            geaendert_am = excluded.geaendert_am
        ''',
        [
          position.id,
          position.erlebnisId,
          position.produktId,
          position.anzahl,
          _zeit(position.erstelltAm),
          _zeit(position.geaendertAm),
        ],
      );
      if (preis == null) {
        datenbank.verbindung.execute(
          'DELETE FROM preisbeobachtungen WHERE erlebnis_position_id = ?',
          [position.id],
        );
      } else {
        datenbank.verbindung.execute(
          '''
            INSERT INTO preisbeobachtungen (
              id, erlebnis_id, erlebnis_position_id, produkt_id, ort_id,
              beobachtet_am, betrag_minor, waehrung, erstellt_am, geaendert_am
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(erlebnis_position_id) DO UPDATE SET
              produkt_id = excluded.produkt_id,
              ort_id = excluded.ort_id,
              beobachtet_am = excluded.beobachtet_am,
              betrag_minor = excluded.betrag_minor,
              waehrung = excluded.waehrung,
              geaendert_am = excluded.geaendert_am
          ''',
          [
            preis.id,
            preis.erlebnisId,
            preis.erlebnisPositionId,
            preis.produktId,
            preis.ortId,
            _zeit(preis.beobachtetAm),
            preis.betrag.minorEinheiten,
            preis.betrag.waehrung,
            _zeit(preis.erstelltAm),
            _zeit(preis.geaendertAm),
          ],
        );
      }
    });
  }

  @override
  Future<void> loescheErlebnisposition(String id) async {
    datenbank.verbindung.execute(
      'DELETE FROM erlebnispositionen WHERE id = ?',
      [id],
    );
  }

  @override
  Future<Preisbeobachtung?> ladeLetztenPreis({
    required String produktId,
    required String waehrung,
  }) async {
    final rows = datenbank.verbindung.select(
      '''
        SELECT * FROM preisbeobachtungen
        WHERE produkt_id = ? AND waehrung = ?
        ORDER BY beobachtet_am DESC, geaendert_am DESC LIMIT 1
      ''',
      [produktId, waehrung],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return Preisbeobachtung(
      id: row['id'] as String,
      erlebnisId: row['erlebnis_id'] as String,
      erlebnisPositionId: row['erlebnis_position_id'] as String,
      produktId: row['produkt_id'] as String,
      ortId: row['ort_id'] as String?,
      beobachtetAm: DateTime.parse(row['beobachtet_am'] as String),
      betrag: Geldbetrag(
        minorEinheiten: row['betrag_minor'] as int,
        waehrung: row['waehrung'] as String,
      ),
      erstelltAm: DateTime.parse(row['erstellt_am'] as String),
      geaendertAm: DateTime.parse(row['geaendert_am'] as String),
    );
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
    if (kriterium.name.trim().isEmpty) {
      throw ArgumentError.value(kriterium.name, 'name');
    }
    final vorhanden = datenbank.verbindung.select(
      'SELECT * FROM kriterien WHERE id = ?',
      [kriterium.id],
    );
    final bisherigeVersion =
        vorhanden.isEmpty ? 0 : (vorhanden.single['version'] as int? ?? 1);
    final bedeutungGeaendert = vorhanden.isNotEmpty &&
        (vorhanden.single['name'] != kriterium.name.trim() ||
            vorhanden.single['beschreibung'] !=
                _leerAlsNull(kriterium.beschreibung) ||
            vorhanden.single['eingabetyp'] != kriterium.eingabetyp.name ||
            vorhanden.single['objektart'] != kriterium.wirksameObjektart.name ||
            vorhanden.single['auswahlwerte'] !=
                kriterium.auswahlwerte.join('\n'));
    final version = bedeutungGeaendert
        ? bisherigeVersion + 1
        : (bisherigeVersion == 0 ? kriterium.version : bisherigeVersion);
    datenbank.verbindung.execute(
      '''
        INSERT INTO kriterien (
          id, name, beschreibung, eingabetyp, reihenfolge, aktiv,
          erstellt_am, geaendert_am, produktart, objektart, version,
          auswahlwerte
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          name = excluded.name,
          beschreibung = excluded.beschreibung,
          eingabetyp = excluded.eingabetyp,
          reihenfolge = excluded.reihenfolge,
          aktiv = excluded.aktiv,
          produktart = excluded.produktart,
          objektart = excluded.objektart,
          version = excluded.version,
          auswahlwerte = excluded.auswahlwerte,
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
        kriterium.produktart.name,
        kriterium.wirksameObjektart.name,
        version,
        kriterium.auswahlwerte.join('\n'),
      ],
    );
  }

  @override
  Future<void> sortiereKriterien(List<String> kriteriumIds) async {
    if (kriteriumIds.isEmpty) {
      return;
    }
    if (kriteriumIds.toSet().length != kriteriumIds.length) {
      throw ArgumentError.value(kriteriumIds, 'kriteriumIds');
    }
    datenbank.transaktion(() {
      final jetzt = _zeit(DateTime.now().toUtc());
      for (var index = 0; index < kriteriumIds.length; index++) {
        datenbank.verbindung.execute(
          'UPDATE kriterien SET reihenfolge = ?, geaendert_am = ? WHERE id = ?',
          [index * 10, jetzt, kriteriumIds[index]],
        );
      }
      final vorhanden = datenbank.verbindung.select(
        'SELECT id FROM kriterien WHERE id IN '
        '(${List.filled(kriteriumIds.length, '?').join(', ')})',
        kriteriumIds,
      );
      if (vorhanden.length != kriteriumIds.length) {
        throw ArgumentError('Mindestens ein Kriterium ist unbekannt.');
      }
    });
  }

  @override
  Future<bool> entferneKriterium(String kriteriumId) async {
    var wurdeDeaktiviert = false;
    datenbank.transaktion(() {
      final vorhanden = datenbank.verbindung.select(
        'SELECT id FROM kriterien WHERE id = ?',
        [kriteriumId],
      );
      if (vorhanden.isEmpty) {
        throw ArgumentError.value(kriteriumId, 'kriteriumId');
      }
      final verwendungen = datenbank.verbindung.select(
        'SELECT COUNT(*) AS anzahl FROM bewertungen WHERE kriterium_id = ?',
        [kriteriumId],
      ).single['anzahl'] as int;
      wurdeDeaktiviert =
          verwendungen > 0 || _standardkriteriumIds.contains(kriteriumId);
      if (wurdeDeaktiviert) {
        datenbank.verbindung.execute(
          'UPDATE kriterien SET aktiv = 0, geaendert_am = ? WHERE id = ?',
          [_zeit(DateTime.now().toUtc()), kriteriumId],
        );
      } else {
        datenbank.verbindung.execute(
          'DELETE FROM kriterien WHERE id = ?',
          [kriteriumId],
        );
      }
    });
    return wurdeDeaktiviert;
  }

  Set<String> get _standardkriteriumIds {
    final zeit = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return {
      ...StandardGetraenkekriterien.alle(zeit).map((wert) => wert.id),
      ...StandardSpeisekriterien.alle(zeit).map((wert) => wert.id),
      StandardFallbackKriterien.gesamturteil(zeit).id,
      ...StandardOrtskriterien.gastronomie(zeit).map((wert) => wert.id),
      ...StandardOrtskriterien.geschaeft(zeit).map((wert) => wert.id),
    };
  }

  @override
  Future<List<Bewertungskriterium>> ladeKriterien({
    bool nurAktive = false,
  }) async {
    final rows = datenbank.verbindung.select(
      'SELECT * FROM kriterien ${nurAktive ? 'WHERE aktiv = 1' : ''} '
      'ORDER BY objektart, reihenfolge, name COLLATE NOCASE',
    );
    return rows.map(_kriteriumAusZeile).toList();
  }

  @override
  Future<List<Bewertungskriterium>> ladeAktiveKriterienFuerObjektart(
    KriteriumObjektart objektart,
  ) async {
    final rows = datenbank.verbindung.select(
      'SELECT * FROM kriterien WHERE aktiv = 1 AND objektart = ? '
      'ORDER BY reihenfolge, name COLLATE NOCASE',
      [objektart.name],
    );
    return rows.map(_kriteriumAusZeile).toList();
  }

  Bewertungskriterium _kriteriumAusZeile(Map<String, Object?> row) =>
      Bewertungskriterium(
        id: row['id'] as String,
        name: row['name'] as String,
        beschreibung: row['beschreibung'] as String?,
        eingabetyp: KriteriumEingabetyp.values.byName(
          row['eingabetyp'] as String,
        ),
        reihenfolge: row['reihenfolge'] as int,
        aktiv: (row['aktiv'] as int) == 1,
        produktart: Produktart.values.byName(row['produktart'] as String),
        objektart: KriteriumObjektart.values.byName(row['objektart'] as String),
        version: row['version'] as int,
        auswahlwerte: (row['auswahlwerte'] as String)
            .split('\n')
            .where((wert) => wert.isNotEmpty)
            .toList(),
        erstelltAm: DateTime.parse(row['erstellt_am'] as String),
        geaendertAm: DateTime.parse(row['geaendert_am'] as String),
      );

  @override
  Future<List<Bewertungskriterium>> ladeAktiveGetraenkekriterien() async {
    return ladeAktiveKriterienFuerProduktart(Produktart.bier);
  }

  @override
  Future<List<Bewertungskriterium>> ladeAktiveKriterienFuerProduktart(
    Produktart produktart,
  ) async {
    final wirksameArt = switch (produktart) {
      Produktart.bier || Produktart.getraenk => KriteriumObjektart.getraenk,
      Produktart.speise => KriteriumObjektart.speise,
      Produktart.sonstiges => KriteriumObjektart.sonstigesProdukt,
    };
    final rows = datenbank.verbindung.select(
      'SELECT * FROM kriterien WHERE aktiv = 1 AND objektart = ? '
      'ORDER BY reihenfolge, name COLLATE NOCASE',
      [wirksameArt.name],
    );
    return rows.map(_kriteriumAusZeile).toList();
  }

  @override
  Future<void> speichereBewertung(Bewertung bewertung) async =>
      _speichereBewertungZeile(bewertung);

  void _speichereBewertungZeile(Bewertung bewertung) {
    final kriterien = datenbank.verbindung.select(
      'SELECT * FROM kriterien WHERE id = ?',
      [bewertung.kriteriumId],
    );
    final kriterium = kriterien.isEmpty ? null : kriterien.single;
    if (kriterium == null) {
      throw ArgumentError.value(
        bewertung.kriteriumId,
        'kriteriumId',
        'Das Bewertungskriterium ist unbekannt.',
      );
    }
    _pruefeBewertungswert(bewertung, kriterium);
    datenbank.verbindung.execute(
      '''
        INSERT INTO bewertungen (
          id, erlebnis_id, kriterium_id, wert, text_wert, erstellt_am,
          geaendert_am, herkunft_profil_id, erlebnis_position_id, ort_id,
          kriterium_name, kriterium_eingabetyp, kriterium_reihenfolge,
          kriterium_version, kriterium_beschreibung, kriterium_auswahlwerte,
          ortsbewertung_id
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        bewertung.id,
        bewertung.erlebnisId,
        bewertung.kriteriumId,
        bewertung.wert,
        _leerAlsNull(bewertung.textWert),
        _zeit(bewertung.erstelltAm),
        _zeit(bewertung.geaendertAm),
        bewertung.herkunftProfilId,
        bewertung.erlebnisPositionId,
        bewertung.ortId,
        kriterium['name'],
        kriterium['eingabetyp'],
        kriterium['reihenfolge'],
        kriterium['version'],
        kriterium['beschreibung'],
        kriterium['auswahlwerte'] ?? '',
        bewertung.ortsbewertungId,
      ],
    );
  }

  void _pruefeBewertungswert(
    Bewertung bewertung,
    Map<String, Object?> kriterium,
  ) {
    final typ =
        KriteriumEingabetyp.values.byName(kriterium['eingabetyp'] as String);
    final zahl = bewertung.wert;
    final text = _leerAlsNull(bewertung.textWert);
    final hatGenauEinenWert = (zahl == null) != (text == null);
    if (!hatGenauEinenWert) {
      throw ArgumentError('Eine Bewertung benötigt genau einen Wert.');
    }
    switch (typ) {
      case KriteriumEingabetyp.wertung:
      case KriteriumEingabetyp.intensitaet:
        if (zahl == null ||
            zahl < 1 ||
            zahl > 5 ||
            zahl != zahl.roundToDouble()) {
          throw ArgumentError('Wertung und Intensität müssen 1 bis 5 sein.');
        }
      case KriteriumEingabetyp.jaNein:
        if (zahl != 0 && zahl != 1) {
          throw ArgumentError('Ja/Nein muss als 0 oder 1 gespeichert werden.');
        }
      case KriteriumEingabetyp.zahl:
        if (zahl == null || !zahl.isFinite) {
          throw ArgumentError('Zahl-Kriterien benötigen eine endliche Zahl.');
        }
      case KriteriumEingabetyp.auswahl:
        final auswahlwerte = (kriterium['auswahlwerte'] as String? ?? '')
            .split('\n')
            .where((wert) => wert.isNotEmpty)
            .toSet();
        if (text == null || !auswahlwerte.contains(text)) {
          throw ArgumentError(
              'Der Auswahlwert ist für das Kriterium ungültig.');
        }
      case KriteriumEingabetyp.freitext:
        if (text == null || text.length > 500) {
          throw ArgumentError(
            'Freitext muss zwischen 1 und 500 Zeichen enthalten.',
          );
        }
    }
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
        'WHERE erlebnis_id = ? AND herkunft_profil_id = ? '
        'AND erlebnis_position_id IS NULL AND ortsbewertung_id IS NULL',
        [erlebnis.id, erlebnis.herkunftProfilId],
      );
      for (final bewertung in bewertungen) {
        _speichereBewertungZeile(bewertung);
      }
    });
  }

  @override
  Future<void> speichereProduktbewertung({
    required Erlebnis erlebnis,
    required ErlebnisPosition position,
    required List<Bewertung> bewertungen,
  }) async {
    if (position.erlebnisId != erlebnis.id ||
        bewertungen.any((bewertung) =>
            bewertung.erlebnisId != erlebnis.id ||
            bewertung.erlebnisPositionId != position.id ||
            bewertung.herkunftProfilId != erlebnis.herkunftProfilId)) {
      throw ArgumentError('Bewertungen müssen zur Erlebnisposition gehören.');
    }
    datenbank.transaktion(() {
      _speichereErlebnisZeile(erlebnis);
      datenbank.verbindung.execute(
        'DELETE FROM bewertungen WHERE erlebnis_position_id = ?',
        [position.id],
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

  @override
  Future<List<Bewertung>> ladeBewertungenFuerErlebnisposition(
    String positionId,
  ) async {
    final rows = datenbank.verbindung.select(
      'SELECT * FROM bewertungen WHERE erlebnis_position_id = ? '
      'ORDER BY erstellt_am, kriterium_id',
      [positionId],
    );
    return rows.map(_bewertungAusZeile).toList();
  }

  Bewertung _bewertungAusZeile(Map<String, Object?> row) => Bewertung(
        id: row['id'] as String,
        erlebnisId: row['erlebnis_id'] as String,
        kriteriumId: row['kriterium_id'] as String,
        herkunftProfilId: row['herkunft_profil_id'] as String,
        erlebnisPositionId: row['erlebnis_position_id'] as String?,
        ortId: row['ort_id'] as String?,
        ortsbewertungId: row['ortsbewertung_id'] as String?,
        wert: (row['wert'] as num?)?.toDouble(),
        textWert: row['text_wert'] as String?,
        erstelltAm: DateTime.parse(row['erstellt_am'] as String),
        geaendertAm: DateTime.parse(row['geaendert_am'] as String),
        kriteriumName: row['kriterium_name'] as String?,
        kriteriumBeschreibung: row['kriterium_beschreibung'] as String?,
        kriteriumEingabetyp: row['kriterium_eingabetyp'] == null
            ? null
            : KriteriumEingabetyp.values.byName(
                row['kriterium_eingabetyp'] as String,
              ),
        kriteriumReihenfolge: row['kriterium_reihenfolge'] as int?,
        kriteriumVersion: row['kriterium_version'] as int?,
        kriteriumAuswahlwerte: (row['kriterium_auswahlwerte'] as String? ?? '')
            .split('\n')
            .where((wert) => wert.isNotEmpty)
            .toList(),
      );

  @override
  Future<List<Bewertung>> ladeBewertungenFuerProdukt(String produktId) async {
    final rows = datenbank.verbindung.select('''
      SELECT b.* FROM bewertungen b
      LEFT JOIN erlebnispositionen p ON p.id = b.erlebnis_position_id
      LEFT JOIN erlebnisse e ON e.id = b.erlebnis_id
      WHERE p.produkt_id = ? OR (p.id IS NULL AND e.produkt_id = ?)
      ORDER BY b.erstellt_am
    ''', [produktId, produktId]);
    return rows.map(_bewertungAusZeile).toList();
  }

  @override
  Future<OrtsbewertungMitWerten?> ladeOrtsbewertungFuerErlebnis(
    String erlebnisId,
  ) async {
    final rows = datenbank.verbindung.select(
      'SELECT * FROM ortsbewertungen WHERE erlebnis_id = ?',
      [erlebnisId],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    final ortsbewertung = Ortsbewertung(
      id: row['id'] as String,
      erlebnisId: row['erlebnis_id'] as String,
      ortId: row['ort_id'] as String,
      herkunftProfilId: row['herkunft_profil_id'] as String,
      bewertetAm: DateTime.parse(row['bewertet_am'] as String),
      notiz: row['notiz'] as String?,
      erstelltAm: DateTime.parse(row['erstellt_am'] as String),
      geaendertAm: DateTime.parse(row['geaendert_am'] as String),
    );
    final werte = datenbank.verbindung
        .select(
          'SELECT * FROM bewertungen WHERE ortsbewertung_id = ? '
          'ORDER BY kriterium_reihenfolge, erstellt_am',
          [ortsbewertung.id],
        )
        .map(_bewertungAusZeile)
        .toList();
    return OrtsbewertungMitWerten(ortsbewertung: ortsbewertung, werte: werte);
  }

  @override
  Future<void> speichereOrtsbewertung({
    required Erlebnis erlebnis,
    required Ort ort,
    required Ortsbewertung ortsbewertung,
    required List<Bewertung> bewertungen,
  }) async {
    final erwarteteObjektart = switch (erlebnis.typ) {
      Erlebnistyp.restaurantbesuch => KriteriumObjektart.gastronomie,
      Erlebnistyp.einkauf => KriteriumObjektart.geschaeft,
    };
    final erwarteterOrtstyp = switch (erlebnis.typ) {
      Erlebnistyp.restaurantbesuch => Ortstyp.gastronomie,
      Erlebnistyp.einkauf => Ortstyp.geschaeft,
    };
    final vorhandeneOrtsbewertung = datenbank.verbindung.select(
      'SELECT id FROM ortsbewertungen WHERE erlebnis_id = ?',
      [erlebnis.id],
    );
    final kriteriumIds = bewertungen.map((wert) => wert.kriteriumId).toSet();
    final unpassendeKriterien = kriteriumIds.where((id) {
      final rows = datenbank.verbindung.select(
        'SELECT objektart FROM kriterien WHERE id = ?',
        [id],
      );
      return rows.isEmpty ||
          rows.single['objektart'] != erwarteteObjektart.name;
    });
    if (erlebnis.wirksamerOrtId != ort.id ||
        ort.typ != erwarteterOrtstyp ||
        ortsbewertung.erlebnisId != erlebnis.id ||
        ortsbewertung.ortId != ort.id ||
        ortsbewertung.herkunftProfilId != erlebnis.herkunftProfilId ||
        !ortsbewertung.bewertetAm.isAtSameMomentAs(erlebnis.erlebtAm) ||
        (bewertungen.isEmpty && _leerAlsNull(ortsbewertung.notiz) == null) ||
        (vorhandeneOrtsbewertung.isNotEmpty &&
            vorhandeneOrtsbewertung.single['id'] != ortsbewertung.id) ||
        unpassendeKriterien.isNotEmpty ||
        bewertungen.any((bewertung) =>
            bewertung.erlebnisId != erlebnis.id ||
            bewertung.ortId != ort.id ||
            bewertung.ortsbewertungId != ortsbewertung.id ||
            bewertung.herkunftProfilId != erlebnis.herkunftProfilId ||
            bewertung.erlebnisPositionId != null)) {
      throw ArgumentError(
        'Ortsbewertung, Ort, Kriterien und Erlebnis passen nicht zusammen.',
      );
    }
    datenbank.transaktion(() {
      _speichereErlebnisZeile(erlebnis);
      datenbank.verbindung.execute(
        '''
          INSERT INTO ortsbewertungen (
            id, erlebnis_id, ort_id, herkunft_profil_id, bewertet_am, notiz,
            erstellt_am, geaendert_am
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(erlebnis_id) DO UPDATE SET
            ort_id = excluded.ort_id,
            bewertet_am = excluded.bewertet_am,
            notiz = excluded.notiz,
            geaendert_am = excluded.geaendert_am
        ''',
        [
          ortsbewertung.id,
          ortsbewertung.erlebnisId,
          ortsbewertung.ortId,
          ortsbewertung.herkunftProfilId,
          _zeit(ortsbewertung.bewertetAm),
          _leerAlsNull(ortsbewertung.notiz),
          _zeit(ortsbewertung.erstelltAm),
          _zeit(ortsbewertung.geaendertAm),
        ],
      );
      datenbank.verbindung.execute(
        'DELETE FROM bewertungen WHERE ortsbewertung_id = ?',
        [ortsbewertung.id],
      );
      for (final bewertung in bewertungen) {
        _speichereBewertungZeile(bewertung);
      }
    });
  }

  @override
  Future<List<BewertungsverlaufEintrag>> ladeProduktverlauf(
    String produktId,
  ) async {
    final positionen = datenbank.verbindung.select(
      '''
        SELECT p.id AS position_id, p.erlebnis_id, p.produkt_id, p.anzahl,
          p.erstellt_am AS position_erstellt_am,
          p.geaendert_am AS position_geaendert_am
        FROM erlebnispositionen p
        WHERE p.produkt_id = ?
      ''',
      [produktId],
    );
    final ergebnis = <BewertungsverlaufEintrag>[];
    final erlebnisseMitPosition = <String>{};
    for (final row in positionen) {
      final erlebnis = await ladeErlebnis(row['erlebnis_id'] as String);
      if (erlebnis == null) continue;
      erlebnisseMitPosition.add(erlebnis.id);
      final position = ErlebnisPosition(
        id: row['position_id'] as String,
        erlebnisId: row['erlebnis_id'] as String,
        produktId: row['produkt_id'] as String,
        anzahl: row['anzahl'] as int,
        erstelltAm: DateTime.parse(row['position_erstellt_am'] as String),
        geaendertAm: DateTime.parse(row['position_geaendert_am'] as String),
      );
      ErlebnispositionMitProdukt? geladenePosition;
      for (final wert in await ladeErlebnispositionen(erlebnis.id)) {
        if (wert.position.id == position.id) {
          geladenePosition = wert;
          break;
        }
      }
      final ortId = erlebnis.wirksamerOrtId;
      ergebnis.add(BewertungsverlaufEintrag(
        erlebnis: erlebnis,
        ort: ortId == null ? null : await ladeOrt(ortId),
        position: position,
        preis: geladenePosition?.preis,
        bewertungen: await ladeBewertungenFuerErlebnisposition(position.id),
        herkunftProfilId: erlebnis.herkunftProfilId,
        notiz: erlebnis.notiz,
      ));
    }
    final direkteErlebnisse = datenbank.verbindung.select(
      'SELECT id FROM erlebnisse WHERE produkt_id = ?',
      [produktId],
    );
    for (final row in direkteErlebnisse) {
      final erlebnisId = row['id'] as String;
      if (erlebnisseMitPosition.contains(erlebnisId)) continue;
      final erlebnis = await ladeErlebnis(erlebnisId);
      if (erlebnis == null) continue;
      final bewertungen = (await ladeBewertungenFuerErlebnis(erlebnis.id))
          .where((bewertung) =>
              bewertung.erlebnisPositionId == null &&
              bewertung.ortsbewertungId == null)
          .toList();
      if (bewertungen.isEmpty && erlebnis.preis == null) continue;
      final ortId = erlebnis.wirksamerOrtId;
      ergebnis.add(BewertungsverlaufEintrag(
        erlebnis: erlebnis,
        ort: ortId == null ? null : await ladeOrt(ortId),
        bewertungen: bewertungen,
        herkunftProfilId: erlebnis.herkunftProfilId,
        historischerPreis: erlebnis.preis,
        historischeMenge: erlebnis.menge,
        historischesGebinde: erlebnis.gebinde,
        notiz: erlebnis.notiz,
      ));
    }
    ergebnis.sort((a, b) => b.erlebnis.erlebtAm.compareTo(a.erlebnis.erlebtAm));
    return ergebnis;
  }

  @override
  Future<List<BewertungsverlaufEintrag>> ladeOrtsverlauf(String ortId) async {
    final rows = datenbank.verbindung.select(
      'SELECT * FROM ortsbewertungen WHERE ort_id = ? ORDER BY bewertet_am DESC',
      [ortId],
    );
    final ort = await ladeOrt(ortId);
    final ergebnis = <BewertungsverlaufEintrag>[];
    for (final row in rows) {
      final erlebnis = await ladeErlebnis(row['erlebnis_id'] as String);
      if (erlebnis == null) continue;
      final geladen = await ladeOrtsbewertungFuerErlebnis(erlebnis.id);
      if (geladen == null) continue;
      ergebnis.add(BewertungsverlaufEintrag(
        erlebnis: erlebnis,
        ort: ort,
        bewertungen: geladen.werte,
        herkunftProfilId: geladen.ortsbewertung.herkunftProfilId,
        notiz: geladen.ortsbewertung.notiz,
      ));
    }
    return ergebnis;
  }

  String _zeit(DateTime wert) => wert.toUtc().toIso8601String();

  String _datum(DateTime wert) => '${wert.year.toString().padLeft(4, '0')}-'
      '${wert.month.toString().padLeft(2, '0')}-'
      '${wert.day.toString().padLeft(2, '0')}';

  String? _optionaleZeit(DateTime? wert) => wert == null ? null : _zeit(wert);

  DateTime? _optionalesDatum(String? wert) {
    if (wert == null) return null;
    return DateTime.parse(wert.length == 10 ? '${wert}T00:00:00.000Z' : wert);
  }

  String? _leerAlsNull(String? wert) {
    final getrimmt = wert?.trim();
    return getrimmt == null || getrimmt.isEmpty ? null : getrimmt;
  }
}
