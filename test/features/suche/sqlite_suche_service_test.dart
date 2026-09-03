import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/kategorien/models/kategorie.dart';
import 'package:taugts/features/kategorien/services/sqlite_kategorie_repository.dart';
import 'package:taugts/features/kategorien/services/sqlite_klassifikations_repository.dart';
import 'package:taugts/features/suche/models/suchmodelle.dart';
import 'package:taugts/features/suche/services/sqlite_suche_service.dart';

void main() {
  test('Produktsuche kombiniert Name, Kategorie, Barcode und Tag', () async {
    final db = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(db.schliessen);
    final bewertungen = SqliteBewertungsRepository(db);
    final kategorien = SqliteKategorieRepository(db);
    final klassifikation = SqliteKlassifikationsRepository(db);
    final jetzt = DateTime.utc(2026, 9, 3);
    await bewertungen.speichereProdukt(Produkt(
      id: 'p1',
      name: 'Hopfenstern',
      marke: 'Beispiel',
      barcode: '4012345678901',
      erstelltAm: jetzt,
      geaendertAm: jetzt,
    ));
    const ipa = Kategorie(
      id: 'ipa',
      name: 'IPA',
      bereich: KategorieBereich.produkt,
      elternId: '10000000-0000-4000-8000-000000000003',
    );
    kategorien.speichern(ipa);
    kategorien.ordneProduktZu('p1', 'ipa');
    klassifikation.setzeTags('p1', ['fruchtig']);
    final service = SqliteSucheService(db);

    expect(
      await service.suche(
        const Suchfilter(ziel: Suchziel.produkte, text: 'IPA'),
      ),
      hasLength(1),
    );
    expect(
      await service.suche(
        const Suchfilter(ziel: Suchziel.produkte, text: 'fruchtig'),
      ),
      hasLength(1),
    );
    expect(
      await service.suche(
        const Suchfilter(ziel: Suchziel.produkte, text: '4012345678901'),
      ),
      hasLength(1),
    );
  });

  test('Globale Suche findet Treffer außerhalb des Produktbereichs', () async {
    final db = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(db.schliessen);
    SqliteKategorieRepository(db);
    SqliteKlassifikationsRepository(db);
    final bewertungen = SqliteBewertungsRepository(db);
    final jetzt = DateTime.utc(2026, 9, 3);
    await bewertungen.speichereOrt(Ort(
      id: 'o1',
      name: 'Zum Goldenen Hopfen',
      typ: Ortstyp.gastronomie,
      adresse: 'Markt 1',
      erstelltAm: jetzt,
      geaendertAm: jetzt,
    ));
    final service = SqliteSucheService(db);

    final treffer = await service.suche(
      const Suchfilter(text: 'Goldenen Hopfen'),
    );

    expect(treffer.map((wert) => wert.id), contains('o1'));
    expect(
      treffer.firstWhere((wert) => wert.id == 'o1').art,
      Suchziel.orte,
    );
  });

  test('Historische Suche berücksichtigt den Suchbegriff', () async {
    final db = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(db.schliessen);
    SqliteKategorieRepository(db);
    SqliteKlassifikationsRepository(db);
    final bewertungen = SqliteBewertungsRepository(db);
    final jetzt = DateTime.utc(2026, 9, 3, 18);
    const profilId = 'profil-historie';
    db.verbindung.execute(
      'INSERT INTO profile VALUES (?, ?, ?, ?)',
      [profilId, null, jetzt.toIso8601String(), jetzt.toIso8601String()],
    );
    await bewertungen.speichereProdukt(Produkt(
      id: 'p-historie',
      name: 'Abendstern',
      erstelltAm: jetzt,
      geaendertAm: jetzt,
    ));
    await bewertungen.speichereOrt(Ort(
      id: 'o-historie',
      name: 'Zum Goldenen Hopfen',
      typ: Ortstyp.gastronomie,
      erstelltAm: jetzt,
      geaendertAm: jetzt,
    ));
    await bewertungen.speichereErlebnis(Erlebnis(
      id: 'e-historie',
      herkunftProfilId: profilId,
      typ: Erlebnistyp.restaurantbesuch,
      status: Erlebnisstatus.aktiv,
      ortId: 'o-historie',
      tatsaechlicherBeginn: jetzt,
      erstelltAm: jetzt,
      geaendertAm: jetzt,
    ));
    db.verbindung.execute(
      '''
      INSERT INTO erlebnispositionen (
        id, erlebnis_id, produkt_id, anzahl, erstellt_am, geaendert_am
      ) VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [
        'pos-historie',
        'e-historie',
        'p-historie',
        1,
        jetzt.toIso8601String(),
        jetzt.toIso8601String(),
      ],
    );
    db.verbindung.execute(
      '''
      INSERT INTO preisbeobachtungen (
        id, erlebnis_id, erlebnis_position_id, produkt_id, ort_id,
        beobachtet_am, betrag_minor, waehrung, erstellt_am, geaendert_am
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        'preis-historie',
        'e-historie',
        'pos-historie',
        'p-historie',
        'o-historie',
        jetzt.toIso8601String(),
        490,
        'EUR',
        jetzt.toIso8601String(),
        jetzt.toIso8601String(),
      ],
    );
    final service = SqliteSucheService(db);

    final passend = await service.suche(
      const Suchfilter(ziel: Suchziel.historie, text: 'Goldenen Hopfen'),
    );
    final unpassend = await service.suche(
      const Suchfilter(ziel: Suchziel.historie, text: 'nicht vorhanden'),
    );

    expect(passend.map((wert) => wert.id), contains('preis-historie'));
    expect(unpassend, isEmpty);
  });

  test('Erlebnisse lassen sich nach Typ und Status kombinieren', () async {
    final db = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(db.schliessen);
    SqliteKategorieRepository(db);
    SqliteKlassifikationsRepository(db);
    final bewertungen = SqliteBewertungsRepository(db);
    final jetzt = DateTime.utc(2026, 9, 3, 12);
    const profilId = 'profil-1';
    db.verbindung.execute(
      'INSERT INTO profile VALUES (?, ?, ?, ?)',
      [profilId, null, jetzt.toIso8601String(), jetzt.toIso8601String()],
    );
    await bewertungen.speichereErlebnis(Erlebnis(
      id: 'e1',
      herkunftProfilId: profilId,
      typ: Erlebnistyp.einkauf,
      status: Erlebnisstatus.aktiv,
      tatsaechlicherBeginn: jetzt,
      erstelltAm: jetzt,
      geaendertAm: jetzt,
    ));
    final service = SqliteSucheService(db);

    final treffer = await service.suche(const Suchfilter(
      ziel: Suchziel.erlebnisse,
      erlebnistyp: Erlebnistyp.einkauf,
      erlebnisstatus: Erlebnisstatus.aktiv,
    ));
    expect(treffer.map((wert) => wert.id), contains('e1'));
  });
}
