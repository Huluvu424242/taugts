import 'package:sqlite3/sqlite3.dart';

/// Ergänzt das von [LokaleDatenbank] erzeugte Kernschema um alle Tabellen,
/// die zu fachlichen Features des aktuellen Datenbankstands gehören.
///
/// Historisch wurden diese Tabellen erst beim Erzeugen einzelner Repositories
/// angelegt. Die Produktions-Datenbank stellt sie nun direkt beim Öffnen bereit,
/// damit ein frisch angelegter Datenbestand einen deterministischen physischen
/// Schema-Stand besitzt.
abstract final class AktuellesDatenbankschema {
  static const erwarteteTabellen = <String>{
    'profile',
    'objekte',
    'produkte',
    'orte',
    'erlebnisse',
    'erlebnispositionen',
    'preisbeobachtungen',
    'kriterien',
    'ortsbewertungen',
    'bewertungen',
    'kategorien',
    'produkt_kategorien',
    'ort_kategorien',
    'objekt_tags',
    'objekt_klassifikationsmerkmale',
    'kategorie_kriterienset_regeln',
    'kategorie_kriterien',
    'import_aliases',
    'import_protokoll',
  };

  static void stelleFeatureTabellenBereit(Database verbindung) {
    verbindung.execute('''
      CREATE TABLE IF NOT EXISTS kategorien (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        bereich TEXT NOT NULL,
        eltern_id TEXT REFERENCES kategorien(id),
        ist_standard INTEGER NOT NULL DEFAULT 0
      )
    ''');
    verbindung.execute('''
      CREATE TABLE IF NOT EXISTS produkt_kategorien (
        produkt_id TEXT NOT NULL
          REFERENCES produkte(objekt_id) ON DELETE CASCADE,
        kategorie_id TEXT NOT NULL REFERENCES kategorien(id),
        PRIMARY KEY (produkt_id, kategorie_id)
      )
    ''');
    verbindung.execute('''
      CREATE TABLE IF NOT EXISTS ort_kategorien (
        ort_id TEXT NOT NULL REFERENCES orte(id) ON DELETE CASCADE,
        kategorie_id TEXT NOT NULL REFERENCES kategorien(id),
        PRIMARY KEY (ort_id, kategorie_id)
      )
    ''');
    verbindung.execute('''
      CREATE TABLE IF NOT EXISTS objekt_tags (
        objekt_id TEXT NOT NULL,
        normalisiert TEXT NOT NULL,
        text TEXT NOT NULL,
        PRIMARY KEY (objekt_id, normalisiert)
      )
    ''');
    verbindung.execute('''
      CREATE TABLE IF NOT EXISTS objekt_klassifikationsmerkmale (
        objekt_id TEXT NOT NULL,
        dimension TEXT NOT NULL,
        schluessel TEXT NOT NULL,
        wert TEXT NOT NULL,
        PRIMARY KEY (objekt_id, dimension, schluessel)
      )
    ''');
    verbindung.execute('''
      CREATE TABLE IF NOT EXISTS kategorie_kriterienset_regeln (
        kategorie_id TEXT PRIMARY KEY
          REFERENCES kategorien(id) ON DELETE CASCADE,
        fallback_objektart TEXT NOT NULL,
        modus TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1
      )
    ''');
    verbindung.execute('''
      CREATE TABLE IF NOT EXISTS kategorie_kriterien (
        kategorie_id TEXT NOT NULL
          REFERENCES kategorien(id) ON DELETE CASCADE,
        kriterium_id TEXT NOT NULL REFERENCES kriterien(id),
        reihenfolge INTEGER NOT NULL,
        PRIMARY KEY (kategorie_id, kriterium_id)
      )
    ''');
    verbindung.execute('''
      CREATE TABLE IF NOT EXISTS import_aliases (
        sammlung TEXT NOT NULL,
        alias_id TEXT NOT NULL,
        kanonische_id TEXT NOT NULL,
        erstellt_am TEXT NOT NULL,
        PRIMARY KEY (sammlung, alias_id),
        CHECK (sammlung IN ('objekte', 'orte')),
        CHECK (alias_id <> kanonische_id)
      )
    ''');
    verbindung.execute('''
      CREATE TABLE IF NOT EXISTS import_protokoll (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ausgefuehrt_am TEXT NOT NULL,
        erfolgreich INTEGER NOT NULL,
        strategie TEXT NOT NULL,
        hinzugefuegt INTEGER NOT NULL,
        aktualisiert INTEGER NOT NULL,
        uebersprungen INTEGER NOT NULL,
        zusammengefuehrt INTEGER NOT NULL,
        fehlerhaft INTEGER NOT NULL
      )
    ''');
  }
}
