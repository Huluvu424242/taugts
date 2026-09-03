import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/kategorien/models/klassifikation.dart';
import 'package:taugts/features/kategorien/services/klassifikations_repository.dart';

class SqliteKlassifikationsRepository implements KlassifikationsRepository {
  SqliteKlassifikationsRepository(this._db) {
    _schemaBereitstellen();
  }

  final LokaleDatenbank _db;

  void _schemaBereitstellen() {
    _db.verbindung.execute('''
      CREATE TABLE IF NOT EXISTS objekt_tags (
        objekt_id TEXT NOT NULL,
        normalisiert TEXT NOT NULL,
        text TEXT NOT NULL,
        PRIMARY KEY (objekt_id, normalisiert)
      )
    ''');
    _db.verbindung.execute('''
      CREATE TABLE IF NOT EXISTS objekt_klassifikationsmerkmale (
        objekt_id TEXT NOT NULL,
        dimension TEXT NOT NULL,
        schluessel TEXT NOT NULL,
        wert TEXT NOT NULL,
        PRIMARY KEY (objekt_id, dimension, schluessel)
      )
    ''');
  }

  static String normalisiereTag(String tag) =>
      tag.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  @override
  ObjektKlassifikation lade(String objektId) {
    final tags = _db.verbindung
        .select(
          'SELECT text FROM objekt_tags WHERE objekt_id = ? ORDER BY text COLLATE NOCASE',
          [objektId],
        )
        .map((zeile) => zeile['text']! as String)
        .toSet();
    final merkmale = _db.verbindung.select(
      'SELECT dimension, schluessel, wert FROM objekt_klassifikationsmerkmale '
      'WHERE objekt_id = ?',
      [objektId],
    );
    String? herkunft;
    String? hersteller;
    final eigenschaften = <String, String>{};
    for (final merkmal in merkmale) {
      switch (KlassifikationsDimension.values.byName(
        merkmal['dimension']! as String,
      )) {
        case KlassifikationsDimension.herkunft:
          herkunft = merkmal['wert']! as String;
        case KlassifikationsDimension.hersteller:
          hersteller = merkmal['wert']! as String;
        case KlassifikationsDimension.eigenschaft:
          eigenschaften[merkmal['schluessel']! as String] =
              merkmal['wert']! as String;
      }
    }
    return ObjektKlassifikation(
      objektId: objektId,
      tags: tags,
      herkunft: herkunft,
      hersteller: hersteller,
      eigenschaften: eigenschaften,
    );
  }

  @override
  void setzeTags(String objektId, Iterable<String> tags) {
    final eindeutig = <String, String>{};
    for (final tag in tags) {
      final text = tag.trim().replaceAll(RegExp(r'\s+'), ' ');
      final normalisiert = normalisiereTag(text);
      if (normalisiert.isNotEmpty) {
        eindeutig.putIfAbsent(normalisiert, () => text);
      }
    }
    _db.transaktion(() {
      _db.verbindung.execute(
        'DELETE FROM objekt_tags WHERE objekt_id = ?',
        [objektId],
      );
      for (final eintrag in eindeutig.entries) {
        _db.verbindung.execute(
          'INSERT INTO objekt_tags (objekt_id, normalisiert, text) VALUES (?, ?, ?)',
          [objektId, eintrag.key, eintrag.value],
        );
      }
    });
  }

  @override
  void entferneTag(String objektId, String tag) {
    final normalisiert = normalisiereTag(tag);
    if (normalisiert.isEmpty) return;
    _db.verbindung.execute(
      'DELETE FROM objekt_tags WHERE objekt_id = ? AND normalisiert = ?',
      [objektId, normalisiert],
    );
  }

  @override
  void setzeHerkunft(String objektId, String? wert) => _setzeMerkmal(
        objektId,
        KlassifikationsDimension.herkunft,
        '',
        wert,
      );

  @override
  void setzeHersteller(String objektId, String? wert) => _setzeMerkmal(
        objektId,
        KlassifikationsDimension.hersteller,
        '',
        wert,
      );

  @override
  void setzeEigenschaft(
    String objektId,
    String schluessel,
    String? wert,
  ) {
    final key = schluessel.trim();
    if (key.isEmpty) {
      throw ArgumentError.value(schluessel, 'schluessel');
    }
    _setzeMerkmal(
      objektId,
      KlassifikationsDimension.eigenschaft,
      key,
      wert,
    );
  }

  @override
  void entferneEigenschaft(String objektId, String schluessel) => _setzeMerkmal(
        objektId,
        KlassifikationsDimension.eigenschaft,
        schluessel.trim(),
        null,
      );

  void _setzeMerkmal(
    String objektId,
    KlassifikationsDimension dimension,
    String schluessel,
    String? wert,
  ) {
    final bereinigt = wert?.trim();
    if (bereinigt == null || bereinigt.isEmpty) {
      _db.verbindung.execute(
        'DELETE FROM objekt_klassifikationsmerkmale '
        'WHERE objekt_id = ? AND dimension = ? AND schluessel = ?',
        [objektId, dimension.name, schluessel],
      );
      return;
    }
    _db.verbindung.execute('''
      INSERT INTO objekt_klassifikationsmerkmale
        (objekt_id, dimension, schluessel, wert)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(objekt_id, dimension, schluessel) DO UPDATE SET
        wert = excluded.wert
      ''', [objektId, dimension.name, schluessel, bereinigt]);
  }
}
