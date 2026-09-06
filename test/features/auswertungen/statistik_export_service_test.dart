import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/auswertungen/services/statistik_export_service.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';

void main() {
  test('aggregiert Produkt- und Ortswertungen und ignoriert Nicht-Wertungen',
      () async {
    final db = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(db.schliessen);
    final jetzt = DateTime.utc(2026, 9, 6, 12).toIso8601String();
    const profil = 'profil-1';

    db.verbindung.execute(
      'INSERT INTO profile VALUES (?, ?, ?, ?)',
      [profil, null, jetzt, jetzt],
    );
    for (final ort in [('o1', 'Ort A'), ('o2', 'Ort B')]) {
      db.verbindung.execute(
        '''
          INSERT INTO orte (id, name, typ, erstellt_am, geaendert_am)
          VALUES (?, ?, 'gastronomie', ?, ?)
        ''',
        [ort.$1, ort.$2, jetzt, jetzt],
      );
    }
    for (final produkt in [('p1', 'Produkt 1'), ('p2', 'Produkt 2')]) {
      db.verbindung.execute(
        '''
          INSERT INTO objekte (id, name, art, erstellt_am, geaendert_am)
          VALUES (?, ?, 'produkt', ?, ?)
        ''',
        [produkt.$1, produkt.$2, jetzt, jetzt],
      );
      db.verbindung.execute(
        "INSERT INTO produkte (objekt_id, produktart) VALUES (?, 'bier')",
        [produkt.$1],
      );
    }

    final erlebnisse = [
      ('e1', 'o1', 'p1', 'pos1'),
      ('e2', 'o1', 'p1', 'pos2'),
      ('e3', 'o2', 'p1', 'pos3'),
      ('e4', 'o2', 'p2', 'pos4'),
    ];
    for (final eintrag in erlebnisse) {
      db.verbindung.execute(
        '''
          INSERT INTO erlebnisse (
            id, typ, status, ort_id, erstellt_am, geaendert_am,
            herkunft_profil_id, ist_entwurf
          ) VALUES (?, 'restaurantbesuch', 'beendet', ?, ?, ?, ?, 0)
        ''',
        [eintrag.$1, eintrag.$2, jetzt, jetzt, profil],
      );
      db.verbindung.execute(
        '''
          INSERT INTO erlebnispositionen (
            id, erlebnis_id, produkt_id, anzahl, erstellt_am, geaendert_am
          ) VALUES (?, ?, ?, 1, ?, ?)
        ''',
        [eintrag.$4, eintrag.$1, eintrag.$3, jetzt, jetzt],
      );
    }

    final produktWerte = [
      ('b1', 'e1', 'pos1', 5.0),
      ('b2', 'e2', 'pos2', 3.0),
      ('b3', 'e3', 'pos3', 4.0),
      ('b4', 'e4', 'pos4', 2.0),
    ];
    for (final eintrag in produktWerte) {
      db.verbindung.execute(
        '''
          INSERT INTO bewertungen (
            id, erlebnis_id, kriterium_id, wert, erstellt_am, geaendert_am,
            herkunft_profil_id, erlebnis_position_id, kriterium_name,
            kriterium_eingabetyp, kriterium_version, kriterium_auswahlwerte
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Gesamturteil', 'wertung', 1, '')
        ''',
        [
          eintrag.$1,
          eintrag.$2,
          StandardGetraenkekriterien.gesamturteilId,
          eintrag.$4,
          jetzt,
          jetzt,
          profil,
          eintrag.$3,
        ],
      );
    }
    db.verbindung.execute(
      '''
        INSERT INTO bewertungen (
          id, erlebnis_id, kriterium_id, wert, erstellt_am, geaendert_am,
          herkunft_profil_id, erlebnis_position_id, kriterium_name,
          kriterium_eingabetyp, kriterium_version, kriterium_auswahlwerte
        ) VALUES ('intensitaet', 'e1', ?, 1, ?, ?, ?, 'pos1',
          'Bitterkeit', 'intensitaet', 1, '')
      ''',
      [StandardGetraenkekriterien.bitterkeitId, jetzt, jetzt, profil],
    );

    final ortGesamturteilId = db.verbindung
        .select(
          "SELECT id FROM kriterien WHERE objektart = 'gastronomie' AND name = 'Gesamturteil' LIMIT 1",
        )
        .single['id']! as String;
    final serviceId = db.verbindung
        .select(
          "SELECT id FROM kriterien WHERE objektart = 'gastronomie' AND name = 'Service' LIMIT 1",
        )
        .single['id']! as String;

    for (final ortsbewertung in [
      ('ob1', 'e1', 'o1', DateTime.utc(2026, 9, 5, 18).toIso8601String()),
      ('ob2', 'e3', 'o2', DateTime.utc(2026, 9, 6, 18).toIso8601String()),
    ]) {
      db.verbindung.execute(
        '''
          INSERT INTO ortsbewertungen (
            id, erlebnis_id, ort_id, herkunft_profil_id, bewertet_am,
            erstellt_am, geaendert_am
          ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          ortsbewertung.$1,
          ortsbewertung.$2,
          ortsbewertung.$3,
          profil,
          ortsbewertung.$4,
          jetzt,
          jetzt,
        ],
      );
    }
    for (final wertung in [
      ('ob1-gesamt', 'e1', 'ob1', ortGesamturteilId, 'Gesamturteil', 4.0),
      ('ob1-service', 'e1', 'ob1', serviceId, 'Service', 2.0),
      ('ob2-gesamt', 'e3', 'ob2', ortGesamturteilId, 'Gesamturteil', 5.0),
    ]) {
      db.verbindung.execute(
        '''
          INSERT INTO bewertungen (
            id, erlebnis_id, kriterium_id, wert, erstellt_am, geaendert_am,
            herkunft_profil_id, kriterium_name, kriterium_eingabetyp,
            kriterium_version, kriterium_auswahlwerte, ortsbewertung_id
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'wertung', 1, '', ?)
        ''',
        [
          wertung.$1,
          wertung.$2,
          wertung.$4,
          wertung.$6,
          jetzt,
          jetzt,
          profil,
          wertung.$5,
          wertung.$3,
        ],
      );
    }

    final daten = await SqliteStatistikExportService(db).ladeDaten();

    final produkt1OrtA = daten.produktbewertungen.firstWhere(
      (eintrag) => eintrag.produktId == 'p1' && eintrag.ortId == 'o1',
    );
    expect(produkt1OrtA.kennzahlen.beste, 5);
    expect(produkt1OrtA.kennzahlen.schlechteste, 3);
    expect(produkt1OrtA.kennzahlen.durchschnitt, 4);
    expect(produkt1OrtA.kennzahlen.anzahl, 2);
    expect(
      daten.produktbewertungen.any(
        (eintrag) => eintrag.produktId == 'p2' && eintrag.ortId == 'o1',
      ),
      isFalse,
    );

    final ortA = daten.ortsbewertungen.firstWhere(
      (eintrag) => eintrag.ortId == 'o1',
    );
    expect(ortA.kennzahlen.beste, 4);
    expect(ortA.kennzahlen.schlechteste, 2);
    expect(ortA.kennzahlen.durchschnitt, 3);
    expect(daten.ortsverlauf, hasLength(2));
    expect(daten.ortsverlauf.first.durchschnitt, 3);
  });
}
