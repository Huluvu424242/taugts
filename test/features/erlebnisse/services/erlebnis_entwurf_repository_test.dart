import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/erlebnisse/services/erlebnis_entwurf_repository.dart';

void main() {
  late LokaleDatenbank datenbank;
  late SqliteBewertungsRepository repository;
  final zeit = DateTime.utc(2026, 10, 9, 18);
  const profilId = '22130000-0000-4000-8000-000000000001';
  const erlebnisId = '22130000-0000-4000-8000-000000000002';

  setUp(() {
    datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    datenbank.verbindung.execute(
      'INSERT INTO profile VALUES (?, NULL, ?, ?)',
      [profilId, zeit.toIso8601String(), zeit.toIso8601String()],
    );
    repository = SqliteBewertungsRepository(datenbank);
  });
  tearDown(() => datenbank.schliessen());

  test('alle Teilbereiche bleiben bis zum gemeinsamen Speichern Entwurf',
      () async {
    final erlebnis = Erlebnis(
      id: erlebnisId,
      herkunftProfilId: profilId,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    final produkt = Produkt(
      id: '22130000-0000-4000-8000-000000000003',
      name: 'Pils',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereProdukt(produkt);
    final position = ErlebnisPosition(
      id: '22130000-0000-4000-8000-000000000004',
      erlebnisId: erlebnisId,
      produktId: produkt.id,
      anzahl: 2,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    final entwurf = ErlebnisEntwurfRepository(repository, erlebnisId);
    await entwurf.speichereErlebnisposition(position: position);
    await entwurf.speichereProduktbewertung(
      erlebnis: erlebnis,
      position: position,
      bewertungen: [
        Bewertung(
          id: '22130000-0000-4000-8000-000000000005',
          erlebnisId: erlebnisId,
          erlebnisPositionId: position.id,
          kriteriumId: StandardGetraenkekriterien.gesamturteilId,
          herkunftProfilId: profilId,
          wert: 4,
          erstelltAm: zeit,
          geaendertAm: zeit,
        ),
      ],
    );
    expect(await entwurf.ladeErlebnispositionen(erlebnisId), hasLength(1));
    expect(await repository.ladeErlebnis(erlebnisId), isNull);
    expect(await repository.ladeErlebnispositionen(erlebnisId), isEmpty);
    expect(await repository.ladeBewertungenFuerErlebnisposition(position.id), isEmpty);

    await entwurf.uebernehmen(erlebnis);
    expect(await repository.ladeErlebnis(erlebnisId), isNotNull);
    expect(await repository.ladeErlebnispositionen(erlebnisId), hasLength(1));
    expect(await repository.ladeBewertungenFuerErlebnisposition(position.id), hasLength(1));
  });

  test('gescheiterter Gesamtstand bewahrt den Entwurf für Korrekturen',
      () async {
    final erlebnis = Erlebnis(
      id: erlebnisId,
      herkunftProfilId: profilId,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    final produkt = Produkt(
      id: '22130000-0000-4000-8000-000000000006',
      name: 'Korrekturprodukt',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereProdukt(produkt);
    final position = ErlebnisPosition(
      id: '22130000-0000-4000-8000-000000000007',
      erlebnisId: erlebnisId,
      produktId: produkt.id,
      anzahl: 1,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    final entwurf = ErlebnisEntwurfRepository(repository, erlebnisId);
    await entwurf.speichereErlebnisposition(position: position);
    await entwurf.speichereProduktbewertung(
      erlebnis: erlebnis,
      position: position,
      bewertungen: [
        Bewertung(
          id: '22130000-0000-4000-8000-000000000008',
          erlebnisId: erlebnisId,
          erlebnisPositionId: position.id,
          kriteriumId: '22130000-0000-4000-8000-000000000099',
          herkunftProfilId: profilId,
          wert: 5,
          erstelltAm: zeit,
          geaendertAm: zeit,
        ),
      ],
    );
    await expectLater(entwurf.uebernehmen(erlebnis), throwsA(anything));
    expect(await repository.ladeErlebnis(erlebnisId), isNull);
    expect(await repository.ladeErlebnispositionen(erlebnisId), isEmpty);
    expect(await entwurf.ladeErlebnispositionen(erlebnisId), hasLength(1));
    expect(await entwurf.ladeBewertungenFuerErlebnisposition(position.id), hasLength(1));
  });
}
