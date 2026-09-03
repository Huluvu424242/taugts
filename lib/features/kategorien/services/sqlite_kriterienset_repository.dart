import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/kategorien/models/kriterienset.dart';
import 'package:taugts/features/kategorien/services/kriterienset_repository.dart';

class SqliteKriteriensetRepository implements KriteriensetRepository {
  SqliteKriteriensetRepository(this._db) {
    _schemaBereitstellen();
  }

  final LokaleDatenbank _db;

  void _schemaBereitstellen() {
    _db.verbindung.execute('''
      CREATE TABLE IF NOT EXISTS kategorie_kriterienset_regeln (
        kategorie_id TEXT PRIMARY KEY REFERENCES kategorien(id) ON DELETE CASCADE,
        fallback_objektart TEXT NOT NULL,
        modus TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1
      )
    ''');
    _db.verbindung.execute('''
      CREATE TABLE IF NOT EXISTS kategorie_kriterien (
        kategorie_id TEXT NOT NULL REFERENCES kategorien(id) ON DELETE CASCADE,
        kriterium_id TEXT NOT NULL REFERENCES kriterien(id),
        reihenfolge INTEGER NOT NULL,
        PRIMARY KEY (kategorie_id, kriterium_id)
      )
    ''');
  }

  @override
  KategorieKriteriensetRegel? regelFuer(String kategorieId) {
    final rows = _db.verbindung.select(
      'SELECT * FROM kategorie_kriterienset_regeln WHERE kategorie_id = ?',
      [kategorieId],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return KategorieKriteriensetRegel(
      kategorieId: kategorieId,
      fallbackObjektart: KriteriumObjektart.values.byName(
        row['fallback_objektart']! as String,
      ),
      modus: KriteriensetModus.values.byName(row['modus']! as String),
      version: row['version']! as int,
    );
  }

  @override
  List<KategorieKriteriumZuordnung> zuordnungenFuer(String kategorieId) =>
      _db.verbindung
          .select(
            'SELECT * FROM kategorie_kriterien WHERE kategorie_id = ? '
            'ORDER BY reihenfolge, kriterium_id',
            [kategorieId],
          )
          .map(
            (row) => KategorieKriteriumZuordnung(
              kategorieId: kategorieId,
              kriteriumId: row['kriterium_id']! as String,
              reihenfolge: row['reihenfolge']! as int,
            ),
          )
          .toList(growable: false);

  @override
  void speichereRegel(KategorieKriteriensetRegel regel) {
    final bisher = regelFuer(regel.kategorieId);
    final version = bisher == null
        ? 1
        : bisher.modus == regel.modus &&
                bisher.fallbackObjektart == regel.fallbackObjektart
            ? bisher.version
            : bisher.version + 1;
    _db.verbindung.execute('''
      INSERT INTO kategorie_kriterienset_regeln
        (kategorie_id, fallback_objektart, modus, version)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(kategorie_id) DO UPDATE SET
        fallback_objektart = excluded.fallback_objektart,
        modus = excluded.modus,
        version = excluded.version
      ''', [
      regel.kategorieId,
      regel.fallbackObjektart.name,
      regel.modus.name,
      version,
    ]);
  }

  @override
  void setzeZuordnungen(
    String kategorieId,
    Iterable<String> kriteriumIds,
  ) {
    final ids = kriteriumIds.toList(growable: false);
    if (ids.toSet().length != ids.length) {
      throw ArgumentError.value(ids, 'kriteriumIds', 'Doppelte Kriterien.');
    }
    _db.transaktion(() {
      _db.verbindung.execute(
        'DELETE FROM kategorie_kriterien WHERE kategorie_id = ?',
        [kategorieId],
      );
      for (var index = 0; index < ids.length; index++) {
        _db.verbindung.execute(
          'INSERT INTO kategorie_kriterien '
          '(kategorie_id, kriterium_id, reihenfolge) VALUES (?, ?, ?)',
          [kategorieId, ids[index], index * 10],
        );
      }
      final regel = regelFuer(kategorieId);
      if (regel != null) {
        _db.verbindung.execute(
          'UPDATE kategorie_kriterienset_regeln SET version = ? '
          'WHERE kategorie_id = ?',
          [regel.version + 1, kategorieId],
        );
      }
    });
  }
}
