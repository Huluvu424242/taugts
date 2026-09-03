import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/kategorien/models/kategorie.dart';
import 'package:taugts/features/kategorien/services/kategorie_repository.dart';

class SqliteKategorieRepository implements KategorieRepository {
  SqliteKategorieRepository(this._db) {
    _schemaBereitstellen();
  }

  final LokaleDatenbank _db;

  void _schemaBereitstellen() {
    _db.verbindung.execute('''
      CREATE TABLE IF NOT EXISTS kategorien (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        bereich TEXT NOT NULL,
        eltern_id TEXT REFERENCES kategorien(id),
        ist_standard INTEGER NOT NULL DEFAULT 0
      )
    ''');
    _db.verbindung.execute('''
      CREATE TABLE IF NOT EXISTS produkt_kategorien (
        produkt_id TEXT NOT NULL REFERENCES produkte(id) ON DELETE CASCADE,
        kategorie_id TEXT NOT NULL REFERENCES kategorien(id),
        PRIMARY KEY (produkt_id, kategorie_id)
      )
    ''');
    _db.verbindung.execute('''
      CREATE TABLE IF NOT EXISTS ort_kategorien (
        ort_id TEXT NOT NULL REFERENCES orte(id) ON DELETE CASCADE,
        kategorie_id TEXT NOT NULL REFERENCES kategorien(id),
        PRIMARY KEY (ort_id, kategorie_id)
      )
    ''');
    for (final kategorie in StandardKategorien.alle) {
      _db.verbindung.execute(
        'INSERT OR IGNORE INTO kategorien '
        '(id, name, bereich, eltern_id, ist_standard) VALUES (?, ?, ?, ?, 1)',
        [kategorie.id, kategorie.name, kategorie.bereich.name, kategorie.elternId],
      );
    }
  }

  @override
  List<Kategorie> alle() => _db.verbindung
      .select('SELECT * FROM kategorien ORDER BY bereich, name')
      .map(_ausZeile)
      .toList(growable: false);

  @override
  Kategorie? finde(String id) {
    final result = _db.verbindung.select('SELECT * FROM kategorien WHERE id = ?', [id]);
    return result.isEmpty ? null : _ausZeile(result.first);
  }

  Kategorie _ausZeile(dynamic zeile) => Kategorie(
        id: zeile['id'] as String,
        name: zeile['name'] as String,
        bereich: KategorieBereich.values.byName(zeile['bereich'] as String),
        elternId: zeile['eltern_id'] as String?,
        istStandard: (zeile['ist_standard'] as int) == 1,
      );

  @override
  void speichern(Kategorie kategorie) {
    _pruefeEltern(kategorie.id, kategorie.bereich, kategorie.elternId);
    _db.verbindung.execute(
      'INSERT INTO kategorien (id, name, bereich, eltern_id, ist_standard) VALUES (?, ?, ?, ?, ?)',
      [kategorie.id, kategorie.name.trim(), kategorie.bereich.name, kategorie.elternId, kategorie.istStandard ? 1 : 0],
    );
  }

  @override
  void umbenennen(String id, String name) {
    if (name.trim().isEmpty) throw ArgumentError.value(name, 'name');
    _db.verbindung.execute('UPDATE kategorien SET name = ? WHERE id = ?', [name.trim(), id]);
  }

  @override
  void verschieben(String id, String? elternId) {
    final kategorie = finde(id);
    if (kategorie == null) throw ArgumentError.value(id, 'id');
    _pruefeEltern(id, kategorie.bereich, elternId);
    _db.verbindung.execute('UPDATE kategorien SET eltern_id = ? WHERE id = ?', [elternId, id]);
  }

  void _pruefeEltern(String id, KategorieBereich bereich, String? elternId) {
    if (elternId == null) return;
    if (elternId == id) {
      throw const UngueltigeKategorieHierarchieException('Eine Kategorie kann nicht ihr eigener Elternknoten sein.');
    }
    final eltern = finde(elternId);
    if (eltern == null || eltern.bereich != bereich) {
      throw const UngueltigeKategorieHierarchieException('Elternkategorie fehlt oder gehört zu einem anderen Bereich.');
    }
    var aktuell = eltern.elternId;
    while (aktuell != null) {
      if (aktuell == id) {
        throw const UngueltigeKategorieHierarchieException('Die Zuordnung würde einen Zyklus erzeugen.');
      }
      aktuell = finde(aktuell)?.elternId;
    }
  }

  void _ordneZu(String tabelle, String objektSpalte, String objektId, String kategorieId, KategorieBereich bereich) {
    final kategorie = finde(kategorieId);
    if (kategorie == null || kategorie.bereich != bereich) {
      throw ArgumentError.value(kategorieId, 'kategorieId');
    }
    _db.verbindung.execute(
      'INSERT OR IGNORE INTO $tabelle ($objektSpalte, kategorie_id) VALUES (?, ?)',
      [objektId, kategorieId],
    );
  }

  @override
  void ordneProduktZu(String produktId, String kategorieId) =>
      _ordneZu('produkt_kategorien', 'produkt_id', produktId, kategorieId, KategorieBereich.produkt);

  @override
  void ordneOrtZu(String ortId, String kategorieId) =>
      _ordneZu('ort_kategorien', 'ort_id', ortId, kategorieId, KategorieBereich.ort);

  Set<String> _zuordnungen(String tabelle, String spalte, String id) => _db.verbindung
      .select('SELECT kategorie_id FROM $tabelle WHERE $spalte = ?', [id])
      .map((zeile) => zeile['kategorie_id'] as String)
      .toSet();

  @override
  Set<String> kategorienFuerProdukt(String produktId) => _zuordnungen('produkt_kategorien', 'produkt_id', produktId);

  @override
  Set<String> kategorienFuerOrt(String ortId) => _zuordnungen('ort_kategorien', 'ort_id', ortId);

  @override
  void entfernen(String id) {
    final benutzt = _db.verbindung.select(
      'SELECT 1 FROM produkt_kategorien WHERE kategorie_id = ? UNION ALL '
      'SELECT 1 FROM ort_kategorien WHERE kategorie_id = ? UNION ALL '
      'SELECT 1 FROM kategorien WHERE eltern_id = ? LIMIT 1',
      [id, id, id],
    ).isNotEmpty;
    if (benutzt) throw KategorieInBenutzungException(id);
    _db.verbindung.execute('DELETE FROM kategorien WHERE id = ?', [id]);
  }
}
