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
