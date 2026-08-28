import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';

void main() {
  late LokaleDatenbank datenbank;
  late SqliteBewertungsRepository repository;
  final zeit = DateTime.utc(2026, 8, 28, 20);

  setUp(() {
    datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    repository = SqliteBewertungsRepository(datenbank);
  });

  tearDown(() => datenbank.schliessen());

  test('speichert und lädt ein Produkt', () async {
    final produkt = Produkt(
      id: '2d30ae97-1a64-4bb5-a8fd-1df46be78d67',
      name: 'Testbier',
      marke: 'Testbrauerei',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );

    await repository.speichereProdukt(produkt);

    final geladen = await repository.ladeProdukt(produkt.id);
    expect(geladen?.name, 'Testbier');
    expect(geladen?.marke, 'Testbrauerei');
    expect(geladen?.erstelltAm, zeit);
  });

  test('bewahrt mehrere Bewertungen desselben Produkts', () async {
    const produktId = '2d30ae97-1a64-4bb5-a8fd-1df46be78d67';
    const kriteriumId = '5ef4ace9-f038-40d4-a042-042eac68ca3f';
    await repository.speichereProdukt(Produkt(
      id: produktId,
      name: 'Testbier',
      erstelltAm: zeit,
      geaendertAm: zeit,
    ));
    await repository.speichereKriterium(Bewertungskriterium(
      id: kriteriumId,
      name: 'Geschmack',
      erstelltAm: zeit,
      geaendertAm: zeit,
    ));

    for (var index = 0; index < 2; index++) {
      final erlebnisId = '00000000-0000-4000-8000-00000000000$index';
      await repository.speichereErlebnis(Erlebnis(
        id: erlebnisId,
        produktId: produktId,
        erlebtAm: zeit.add(Duration(days: index)),
        erstelltAm: zeit.add(Duration(days: index)),
        geaendertAm: zeit.add(Duration(days: index)),
      ));
      await repository.speichereBewertung(Bewertung(
        id: '10000000-0000-4000-8000-00000000000$index',
        erlebnisId: erlebnisId,
        kriteriumId: kriteriumId,
        wert: 3.0 + index,
        erstelltAm: zeit.add(Duration(days: index)),
        geaendertAm: zeit.add(Duration(days: index)),
      ));
    }

    final bewertungen = await repository.ladeBewertungenFuerProdukt(produktId);
    expect(bewertungen.map((bewertung) => bewertung.wert), [3.0, 4.0]);
  });

  test('erzwingt Beziehungen zwischen Produkt, Ort und Erlebnis', () async {
    await expectLater(
      repository.speichereErlebnis(Erlebnis(
        id: '00000000-0000-4000-8000-000000000000',
        produktId: 'nicht-vorhanden',
        erlebtAm: zeit,
        erstelltAm: zeit,
        geaendertAm: zeit,
      )),
      throwsA(isA<SqliteException>()),
    );
  });

  test('rollt einen fehlgeschlagenen atomaren Schreibvorgang zurück', () {
    expect(
      () => datenbank.transaktion(() {
        datenbank.verbindung.execute(
          "INSERT INTO objekte VALUES ('o1', 'Test', 'allgemein', 'x', 'x')",
        );
        throw StateError('simulierter Fehler');
      }),
      throwsStateError,
    );

    expect(
      datenbank.verbindung.select('SELECT * FROM objekte WHERE id = ?', ['o1']),
      isEmpty,
    );
  });
}
