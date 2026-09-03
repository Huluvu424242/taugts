import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/kategorien/models/kategorie.dart';
import 'package:taugts/features/kategorien/services/kategorie_repository.dart';
import 'package:taugts/features/kategorien/services/sqlite_kategorie_repository.dart';

void main() {
  late LokaleDatenbank db;
  late SqliteKategorieRepository repository;

  setUp(() {
    db = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    repository = SqliteKategorieRepository(db);
  });
  tearDown(() => db.schliessen());

  test('liefert die reproduzierbare Standardhierarchie', () {
    expect(repository.finde(StandardKategorien.bier.id)?.elternId, StandardKategorien.getraenk.id);
    expect(repository.finde(StandardKategorien.speise.id)?.elternId, StandardKategorien.produkt.id);
    expect(repository.finde(StandardKategorien.gastronomie.id)?.elternId, StandardKategorien.ort.id);
    expect(repository.finde(StandardKategorien.geschaeft.id)?.elternId, StandardKategorien.ort.id);
  });

  test('kann Kategorien ergänzen und umbenennen ohne stabile ID zu ändern', () {
    const id = '30000000-0000-4000-8000-000000000001';
    repository.speichern(const Kategorie(
      id: id,
      name: 'Craft Beer',
      bereich: KategorieBereich.produkt,
      elternId: '10000000-0000-4000-8000-000000000003',
    ));
    repository.umbenennen(id, 'Craft-Bier');
    expect(repository.finde(id)?.name, 'Craft-Bier');
    expect(repository.finde(id)?.id, id);
  });

  test('verhindert Zyklen', () {
    expect(
      () => repository.verschieben(StandardKategorien.produkt.id, StandardKategorien.bier.id),
      throwsA(isA<UngueltigeKategorieHierarchieException>()),
    );
  });

  test('verhindert stilles Löschen verwendeter Kategorien', () {
    db.verbindung.execute(
      "INSERT INTO produkte (id, name, erstellt_am, geaendert_am) VALUES ('p1', 'Test', '2026-09-03', '2026-09-03')",
    );
    repository.ordneProduktZu('p1', StandardKategorien.bier.id);
    expect(repository.kategorienFuerProdukt('p1'), contains(StandardKategorien.bier.id));
    expect(
      () => repository.entfernen(StandardKategorien.bier.id),
      throwsA(isA<KategorieInBenutzungException>()),
    );
  });
}
