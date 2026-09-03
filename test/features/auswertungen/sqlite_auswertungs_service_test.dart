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
        "INSERT INTO erlebnisse (id, typ, status, erstellt_am, geaendert_am, herkunft_profil_id, ist_entwurf) VALUES ('e', 'einkauf', 'geplant', ?, ?, ?, 0)",
        [jetzt, jetzt, profil],
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
      final daten = await SqliteAuswertungsService(db).berechne(
        const AuswertungsFilter(),
      );
      expect(daten.bewertungsanzahl, 3);
      expect(daten.durchschnitte, hasLength(2));
      final version1 = daten.durchschnitte.firstWhere(
        (wert) => wert.kriteriumVersion == 1,
      );
      expect(version1.durchschnitt, 3.0);
      expect(version1.anzahl, 2);
    },
  );
}
