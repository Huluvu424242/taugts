import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/auswertungen/models/produktvergleich_modelle.dart';
import 'package:taugts/features/auswertungen/services/sqlite_produktbewertungsvergleich_service.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';

void main() {
  test('bewertet Produkte pro Erlebnis und nicht Orte oder Intensitäten', () async {
    final db = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(db.schliessen);
    const basis = '2026-09-01T10:00:00.000Z';
    db.verbindung.execute(
      'INSERT INTO profile (id, erstellt_am, geaendert_am) VALUES (?, ?, ?)',
      ['profil', basis, basis],
    );
    db.verbindung.execute(
      'INSERT INTO objekte (id, name, art, erstellt_am, geaendert_am) VALUES (?, ?, ?, ?, ?)',
      ['bier', 'Bier', 'produkt', basis, basis],
    );
    db.verbindung.execute(
      'INSERT INTO produkte (objekt_id) VALUES (?)',
      ['bier'],
    );
    for (final ort in [
      ('a', 'Brauhaus', 'gaststaette'),
      ('b', 'Markt', 'geschaeft'),
    ]) {
      db.verbindung.execute(
        'INSERT INTO orte (id, name, typ, erstellt_am, geaendert_am) VALUES (?, ?, ?, ?, ?)',
        [ort.$1, ort.$2, ort.$3, basis, basis],
      );
    }
    for (final e in [
      ('e1', 'a', '2026-09-01T10:00:00.000Z'),
      ('e2', 'a', '2026-09-02T10:00:00.000Z'),
      ('e3', 'b', '2026-09-03T10:00:00.000Z'),
    ]) {
      db.verbindung.execute(
        '''INSERT INTO erlebnisse (
          id, typ, ort_id, beginn, erstellt_am,
          geaendert_am, herkunft_profil_id
        ) VALUES (?, 'einkauf', ?, ?, ?, ?, 'profil')''',
        [e.$1, e.$2, e.$3, basis, basis],
      );
      db.verbindung.execute(
        '''INSERT INTO erlebnispositionen (
          id, erlebnis_id, produkt_id, anzahl, erstellt_am, geaendert_am
        ) VALUES (?, ?, 'bier', 1, ?, ?)''',
        ['pos-${e.$1}', e.$1, basis, basis],
      );
    }
    for (final kriterium in [
      ('gesamt', 'Gesamturteil', 'wertung'),
      ('geschmack', 'Geschmack', 'wertung'),
      ('intensitaet', 'Bitterkeit', 'intensitaet'),
    ]) {
      db.verbindung.execute(
        '''INSERT INTO kriterien (
          id, name, eingabetyp, reihenfolge, aktiv,
          erstellt_am, geaendert_am, produktart, objektart, version,
          auswahlwerte
        ) VALUES (?, ?, ?, 0, 1, ?, ?, 'bier', 'getraenk', 1, '')''',
        [kriterium.$1, kriterium.$2, kriterium.$3, basis, basis],
      );
    }
    var index = 0;
    void bewerten(String erlebnis, String kriterium, String name,
        String typ, double wert) {
      db.verbindung.execute(
        '''INSERT INTO bewertungen (
          id, erlebnis_id, erlebnis_position_id, kriterium_id,
          wert, erstellt_am, geaendert_am, herkunft_profil_id,
          kriterium_name, kriterium_eingabetyp, kriterium_version
        ) VALUES (?, ?, ?, ?, ?, ?, ?, 'profil', ?, ?, 1)''',
        ['b${index++}', erlebnis, 'pos-$erlebnis', kriterium,
         wert, basis, basis, name, typ],
      );
    }
    bewerten('e1', 'gesamt', 'Gesamturteil', 'wertung', 4);
    bewerten('e1', 'geschmack', 'Geschmack', 'wertung', 1);
    bewerten('e1', 'intensitaet', 'Bitterkeit', 'intensitaet', 5);
    bewerten('e2', 'gesamt', 'Gesamturteil', 'wertung', 2);
    bewerten('e3', 'gesamt', 'Gesamturteil', 'wertung', 5);

    final service = SqliteProduktbewertungsvergleichService(db);
    final nurGast = await service.ladeBewertungen(
      const ProduktvergleichFilter(produktId: 'bier'),
    );
    expect(nurGast, hasLength(1));
    expect(nurGast.single.durchschnitt, 3);
    expect(nurGast.single.anzahlErlebnisse, 2);

    final beide = await service.ladeBewertungen(
      const ProduktvergleichFilter(
        produktId: 'bier',
        ortstyp: VergleichOrtstyp.beide,
      ),
    );
    expect(beide.map((wert) => wert.ortId), ['b', 'a']);
    expect(beide.first.durchschnitt, 5);
    final gefiltert = await service.ladeBewertungen(
      ProduktvergleichFilter(
        produktId: 'bier',
        ortstyp: VergleichOrtstyp.beide,
        von: DateTime.utc(2026, 9, 2),
        bis: DateTime.utc(2026, 9, 2, 23, 59, 59),
      ),
    );
    expect(gefiltert, hasLength(1));
    expect(gefiltert.single.durchschnitt, 2);
  });
}
