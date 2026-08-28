import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/profil/services/sqlite_profil_repository.dart';

class _FesterIdGenerator implements IdGenerator {
  var aufrufe = 0;

  @override
  String neueId() {
    aufrufe++;
    return '12345678-1234-4123-8123-123456789abc';
  }
}

void main() {
  late LokaleDatenbank datenbank;
  late _FesterIdGenerator idGenerator;
  late SqliteProfilRepository repository;
  final zeit = DateTime.utc(2026, 8, 28, 20);

  setUp(() {
    datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    idGenerator = _FesterIdGenerator();
    repository = SqliteProfilRepository(
      datenbank,
      idGenerator: idGenerator,
      jetzt: () => zeit,
    );
  });

  tearDown(() => datenbank.schliessen());

  test('erzeugt beim ersten Laden genau eine stabile Profil-ID', () async {
    final erstesProfil = await repository.ladeOderErstelleProfil();
    final zweitesProfil = await repository.ladeOderErstelleProfil();

    expect(erstesProfil.id, '12345678-1234-4123-8123-123456789abc');
    expect(zweitesProfil.id, erstesProfil.id);
    expect(idGenerator.aufrufe, 1);
    expect(datenbank.verbindung.select('SELECT * FROM profile'), hasLength(1));
  });

  test('speichert und ändert den optionalen Anzeigenamen', () async {
    final profil = await repository.ladeOderErstelleProfil();

    await repository.speichereProfil(
      profil.mitAnzeigename('Huluvu', zeit.add(const Duration(minutes: 1))),
    );

    final geladen = await repository.ladeOderErstelleProfil();
    expect(geladen.id, profil.id);
    expect(geladen.anzeigename, 'Huluvu');
  });

  test('leerer Anzeigename wird als nicht gesetzt gespeichert', () async {
    final profil = await repository.ladeOderErstelleProfil();

    await repository.speichereProfil(
      profil.mitAnzeigename('   ', zeit.add(const Duration(minutes: 1))),
    );

    final geladen = await repository.ladeOderErstelleProfil();
    expect(geladen.anzeigename, isNull);
  });
}
