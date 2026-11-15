import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/auswertungen/models/produktvergleich_modelle.dart';
import 'package:taugts/features/auswertungen/services/sqlite_produktpreisvergleich_service.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';

void main() {
  test('letzter Kauf je Ort zählt, nicht historischer Mindestpreis', () async {
    final db = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(db.schliessen);
    const zeit = '2026-09-01T00:00:00.000Z';
    db.verbindung.execute(
      'INSERT INTO profile (id, erstellt_am, geaendert_am) VALUES (?, ?, ?)',
      ['profil', zeit, zeit],
    );
    db.verbindung.execute(
      'INSERT INTO objekte (id, name, art, erstellt_am, geaendert_am) VALUES (?, ?, ?, ?, ?)',
      ['bier', 'Bier', 'produkt', zeit, zeit],
    );
    db.verbindung.execute(
      'INSERT INTO produkte (objekt_id, fuellmenge_ml) VALUES (?, ?)',
      ['bier', 500],
    );
    for (final ort in [
      ('gast', 'Brauhaus', 'gaststaette'),
      ('laden', 'Getränkemarkt', 'geschaeft'),
    ]) {
      db.verbindung.execute(
        'INSERT INTO orte (id, name, typ, erstellt_am, geaendert_am) VALUES (?, ?, ?, ?, ?)',
        [ort.$1, ort.$2, ort.$3, zeit, zeit],
      );
    }
    for (final kauf in [
      ('eins', 'gast', '2026-09-01T10:00:00.000Z', 100),
      ('zwei', 'gast', '2026-09-02T10:00:00.000Z', 400),
      ('drei', 'laden', '2026-09-03T10:00:00.000Z', 300),
    ]) {
      db.verbindung.execute(
        'INSERT INTO erlebnisse (id, typ, beginn, erstellt_am, geaendert_am, herkunft_profil_id) VALUES (?, ?, ?, ?, ?, ?)',
        [kauf.$1, 'einkauf', kauf.$3, zeit, zeit, 'profil'],
      );
      db.verbindung.execute(
        'INSERT INTO erlebnispositionen (id, erlebnis_id, produkt_id, anzahl, erstellt_am, geaendert_am) VALUES (?, ?, ?, ?, ?, ?)',
        ['pos-${kauf.$1}', kauf.$1, 'bier', 1, zeit, zeit],
      );
      db.verbindung.execute(
        '''INSERT INTO preisbeobachtungen (
          id, erlebnis_id, erlebnis_position_id, produkt_id, ort_id,
          beobachtet_am, betrag_minor, waehrung, erstellt_am, geaendert_am
        ) VALUES (?, ?, ?, ?, ?, ?, ?, 'EUR', ?, ?)''',
        ['preis-${kauf.$1}', kauf.$1, 'pos-${kauf.$1}',
          'bier', kauf.$2, kauf.$3, kauf.$4, zeit, zeit],
      );
    }

    final service = SqliteProduktpreisvergleichService(db);
    final nurGast = await service.ladeLetztePreise(
      const ProduktvergleichFilter(produktId: 'bier'),
    );
    expect(nurGast, hasLength(1));
    expect(nurGast.single.preis, 4);
    expect(nurGast.single.euroProLiter, 8);

    final beide = await service.ladeLetztePreise(
      const ProduktvergleichFilter(
        produktId: 'bier',
        ortstyp: VergleichOrtstyp.beide,
      ),
    );
    expect(beide.map((eintrag) => eintrag.ortId), ['laden', 'gast']);
    expect(beide.first.euroProLiter, 6);

    final vorZweitemKauf = await service.ladeLetztePreise(
      ProduktvergleichFilter(
        produktId: 'bier',
        von: DateTime.utc(2026, 9, 1),
        bis: DateTime.utc(2026, 9, 1, 23, 59, 59),
      ),
    );
    expect(vorZweitemKauf.single.preis, 1);
    expect(vorZweitemKauf.single.euroProLiter, 2);
  });

  test('unbekannte Füllmenge ergibt keinen erfundenen Einheitspreis', () async {
    final db = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(db.schliessen);
    const zeit = '2026-09-01T00:00:00.000Z';
    db.verbindung.execute(
      'INSERT INTO profile (id, erstellt_am, geaendert_am) VALUES (?, ?, ?)',
      ['profil', zeit, zeit],
    );
    db.verbindung.execute(
      'INSERT INTO objekte (id, name, art, erstellt_am, geaendert_am) VALUES (?, ?, ?, ?, ?)',
      ['p', 'Produkt', 'produkt', zeit, zeit],
    );
    db.verbindung.execute('INSERT INTO produkte (objekt_id) VALUES (?)', ['p']);
    db.verbindung.execute(
      'INSERT INTO orte (id, name, typ, erstellt_am, geaendert_am) VALUES (?, ?, ?, ?, ?)',
      ['o', 'Laden', 'geschaeft', zeit, zeit],
    );
    db.verbindung.execute(
      'INSERT INTO erlebnisse (id, typ, beginn, erstellt_am, geaendert_am, herkunft_profil_id) VALUES (?, ?, ?, ?, ?, ?)',
      ['e', 'einkauf', zeit, zeit, zeit, 'profil'],
    );
    db.verbindung.execute(
      'INSERT INTO erlebnispositionen (id, erlebnis_id, produkt_id, anzahl, erstellt_am, geaendert_am) VALUES (?, ?, ?, ?, ?, ?)',
      ['ep', 'e', 'p', 1, zeit, zeit],
    );
    db.verbindung.execute(
      '''INSERT INTO preisbeobachtungen (
        id, erlebnis_id, erlebnis_position_id, produkt_id, ort_id,
        beobachtet_am, betrag_minor, waehrung, erstellt_am, geaendert_am
      ) VALUES ('pb', 'e', 'ep', 'p', 'o', ?, 123, 'EUR', ?, ?)''',
      [zeit, zeit, zeit],
    );
    final vergleich = await SqliteProduktpreisvergleichService(db).ladeLetztePreise(
      const ProduktvergleichFilter(
        produktId: 'p',
        ortstyp: VergleichOrtstyp.geschaefte,
      ),
    );
    expect(vergleich, hasLength(1));
    expect(vergleich.single.euroProLiter, isNull);
    expect(vergleich.single.nichtVergleichbar, isNotNull);
  });
}
