import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';
import 'package:taugts/features/auswertungen/services/sqlite_auswertungs_service.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/kategorien/services/sqlite_kategorie_repository.dart';

void main() {
  test(
    'Mittelwerte trennen Kriterienversionen und ignorieren Nicht-Wertungen',
    () async {
      final db = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
      addTearDown(db.schliessen);
      SqliteKategorieRepository(db);
      final jetzt = DateTime.utc(2026, 9, 3).toIso8601String();
      const profil = 'profil-1';
      db.verbindung.execute(
        'INSERT INTO profile VALUES (?, ?, ?, ?)',
        [profil, null, jetzt, jetzt],
      );
      db.verbindung.execute(
        "INSERT INTO erlebnisse (id, typ, beginn, erstellt_am, geaendert_am, herkunft_profil_id) VALUES ('e', 'einkauf', ?, ?, ?, ?)",
        [
          DateTime.utc(2026, 9, 1).toIso8601String(),
          jetzt,
          jetzt,
          profil,
        ],
      );
      for (final produkt in [
        ('p1', 'Pils 0,5 l'),
        ('p2', 'Helles 0,5 l'),
      ]) {
        db.verbindung.execute(
          'INSERT INTO objekte (id, name, art, erstellt_am, geaendert_am) VALUES (?, ?, ?, ?, ?)',
          [produkt.$1, produkt.$2, 'produkt', jetzt, jetzt],
        );
        db.verbindung.execute(
          'INSERT INTO produkte (objekt_id) VALUES (?)',
          [produkt.$1],
        );
      }
      db.verbindung.execute(
        'INSERT INTO orte (id, name, typ, erstellt_am, geaendert_am) VALUES (?, ?, ?, ?, ?)',
        ['ort', 'Brauhaus', 'gaststaette', jetzt, jetzt],
      );
      for (final preis in [
        ('pos1', 'p1', 'preis1', 500, '2026-09-01T12:00:00.000Z'),
        ('pos2', 'p1', 'preis2', 700, '2026-09-01T18:00:00.000Z'),
        ('pos3', 'p2', 'preis3', 300, '2026-09-01T19:00:00.000Z'),
      ]) {
        db.verbindung.execute(
          '''
            INSERT INTO erlebnispositionen (
              id, erlebnis_id, produkt_id, anzahl, erstellt_am, geaendert_am
            ) VALUES (?, 'e', ?, 1, ?, ?)
          ''',
          [preis.$1, preis.$2, jetzt, jetzt],
        );
        db.verbindung.execute(
          '''
            INSERT INTO preisbeobachtungen (
              id, erlebnis_id, erlebnis_position_id, produkt_id, ort_id,
              beobachtet_am, betrag_minor, waehrung, erstellt_am, geaendert_am
            ) VALUES (?, 'e', ?, ?, 'ort', ?, ?, 'EUR', ?, ?)
          ''',
          [preis.$3, preis.$1, preis.$2, preis.$5, preis.$4, jetzt, jetzt],
        );
      }

      db.verbindung.execute(
        'INSERT INTO orte (id, name, typ, erstellt_am, geaendert_am) VALUES (?, ?, ?, ?, ?)',
        ['ort2', 'Markt', 'geschaeft', jetzt, jetzt],
      );
      db.verbindung.execute(
        '''
          INSERT INTO erlebnispositionen (
            id, erlebnis_id, produkt_id, anzahl, erstellt_am, geaendert_am
          ) VALUES ('pos4', 'e', 'p1', 1, ?, ?)
        ''',
        [jetzt, jetzt],
      );
      db.verbindung.execute(
        '''
          INSERT INTO preisbeobachtungen (
            id, erlebnis_id, erlebnis_position_id, produkt_id, ort_id,
            beobachtet_am, betrag_minor, waehrung, erstellt_am, geaendert_am
          ) VALUES ('preis4', 'e', 'pos4', 'p1', 'ort2', ?, 650, 'EUR', ?, ?)
        ''',
        ['2026-09-02T13:30:00.000Z', jetzt, jetzt],
      );

      final produktspreise = await SqliteAuswertungsService(db).berechne(
        const AuswertungsFilter(
          objektId: 'p1',
          objektArt: StatistikObjektart.produkt,
        ),
      );
      expect(produktspreise.preisverlauf, hasLength(3));
      expect(
        produktspreise.preisverlauf.map((wert) => wert.serie).toSet(),
        {'Brauhaus · EUR', 'Markt · EUR'},
      );
      expect(
        produktspreise.preisverlauf.map((wert) => wert.wert).toSet(),
        {5.0, 7.0, 6.5},
      );

      final besuche = await SqliteAuswertungsService(db).berechne(
        const AuswertungsFilter(
          objektId: 'p1',
          objektArt: StatistikObjektart.produkt,
        ),
      );
      expect(besuche.besuchverlauf, hasLength(1));
      expect(besuche.besuchverlauf.single.wert, 1);

      final ausgaben = await SqliteAuswertungsService(db).berechne(
        const AuswertungsFilter(),
      );
      expect(ausgaben.ausgabenverlauf, hasLength(1));
      expect(ausgaben.ausgabenverlauf.single.wert, 21.5);
      expect(ausgaben.ausgabenverlauf.single.serie, 'EUR');

      final ortspreise = await SqliteAuswertungsService(db).berechne(
        const AuswertungsFilter(
          objektId: 'ort',
          objektArt: StatistikObjektart.ort,
        ),
      );
      expect(ortspreise.preisverlauf, hasLength(3));
      expect(
        ortspreise.preisverlauf.map((wert) => wert.serie).toSet(),
        {'Pils 0,5 l · EUR', 'Helles 0,5 l · EUR'},
      );
      expect(
        ortspreise.preisverlauf.map((wert) => wert.beschreibung).toSet(),
        {'Pils 0,5 l · Brauhaus', 'Helles 0,5 l · Brauhaus'},
      );

      db.verbindung.execute(
        '''
          INSERT INTO kriterien (
            id, name, beschreibung, eingabetyp, reihenfolge, aktiv,
            erstellt_am, geaendert_am, produktart, objektart, version,
            auswahlwerte
          ) VALUES ('k', 'Geschmack', NULL, 'wertung', 0, 1, ?, ?, 'bier', 'getraenk', 1, '')
        ''',
        [jetzt, jetzt],
      );
      for (final eintrag in [
        ('b1', 4.0, 1),
        ('b2', 2.0, 1),
        ('b3', 5.0, 2),
      ]) {
        db.verbindung.execute(
          '''
            INSERT INTO bewertungen (
              id, erlebnis_id, kriterium_id, wert, erstellt_am, geaendert_am,
              herkunft_profil_id, kriterium_name, kriterium_eingabetyp,
              kriterium_reihenfolge, kriterium_version, kriterium_auswahlwerte
            ) VALUES (?, 'e', 'k', ?, ?, ?, ?, 'Geschmack', 'wertung', 0, ?, '')
          ''',
          [eintrag.$1, eintrag.$2, jetzt, jetzt, profil, eintrag.$3],
        );
      }
      for (final besuch in [
        ('e2', '2026-09-08T18:00:00.000Z', 'b4', 2.0),
        ('e3', '2026-09-15T18:00:00.000Z', 'b5', 1.0),
        ('e4', '2026-09-22T18:00:00.000Z', 'b6', 4.0),
      ]) {
        db.verbindung.execute(
          '''
            INSERT INTO erlebnisse (
              id, typ, beginn, erstellt_am, geaendert_am, herkunft_profil_id
            ) VALUES (?, 'besuch', ?, ?, ?, ?)
          ''',
          [besuch.$1, besuch.$2, jetzt, jetzt, profil],
        );
        db.verbindung.execute(
          '''
            INSERT INTO bewertungen (
              id, erlebnis_id, kriterium_id, wert, erstellt_am, geaendert_am,
              herkunft_profil_id, kriterium_name, kriterium_eingabetyp,
              kriterium_reihenfolge, kriterium_version, kriterium_auswahlwerte
            ) VALUES (?, ?, 'k', ?, ?, ?, ?, 'Geschmack', 'wertung', 0, 1, '')
          ''',
          [besuch.$3, besuch.$1, besuch.$4, jetzt, jetzt, profil],
        );
      }

      final daten = await SqliteAuswertungsService(db).berechne(
        const AuswertungsFilter(),
      );
      expect(daten.auffaelligkeiten, hasLength(1));
      expect(daten.auffaelligkeiten.single.wert, 2);
      expect(
        daten.auffaelligkeiten.single.zeitpunktBeschriftung,
        'Wochentag 2 · 18:00 Uhr',
      );
      expect(daten.auffaelligkeiten.single.beschreibung, contains('2 von 3'));
      expect(daten.bewertungsanzahl, 6);
      expect(daten.durchschnitte, hasLength(2));
      final version1 = daten.durchschnitte.firstWhere(
        (wert) => wert.kriteriumVersion == 1,
      );
      expect(version1.durchschnitt, 2.6);
      expect(version1.anzahl, 5);

      final service = SqliteAuswertungsService(db);
      final optionen = await service.ladeFilterOptionen();
      expect(
        optionen.kriterien.any((option) => option.bezeichnung == 'Geschmack'),
        isTrue,
      );

      final kriteriumsGefiltert = await service.berechne(
        const AuswertungsFilter(kriteriumId: 'unbekannt'),
      );
      expect(kriteriumsGefiltert.bewertungsanzahl, 0);

      final zeitlichGefiltert = await SqliteAuswertungsService(db).berechne(
        AuswertungsFilter(von: DateTime.utc(2026, 9, 2)),
      );
      expect(zeitlichGefiltert.bewertungsanzahl, 3);
    },
  );
}
