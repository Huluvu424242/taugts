import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';

void main() {
  late LokaleDatenbank datenbank;
  late SqliteBewertungsRepository repository;
  final zeit = DateTime.utc(2026, 9, 5, 18);
  const profilId = '10000000-0000-4000-8000-000000000001';
  const erlebnisId = '10000000-0000-4000-8000-000000000002';

  setUp(() async {
    datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    repository = SqliteBewertungsRepository(datenbank);
    datenbank.verbindung.execute(
      'INSERT INTO profile VALUES (?, ?, ?, ?)',
      [profilId, 'Test', zeit.toIso8601String(), zeit.toIso8601String()],
    );
    await repository.speichereErlebnis(
      Erlebnis(
        id: erlebnisId,
        herkunftProfilId: profilId,
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
    );
  });

  tearDown(() => datenbank.schliessen());

  test('Auswahlwert bleibt beim Speichern und Laden erhalten', () async {
    const kriteriumId = '10000000-0000-4000-8000-000000000003';
    await repository.speichereKriterium(
      Bewertungskriterium(
        id: kriteriumId,
        name: 'Farbe',
        eingabetyp: KriteriumEingabetyp.auswahl,
        auswahlwerte: const ['Hell', 'Dunkel'],
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
    );

    await repository.speichereBewertung(
      Bewertung(
        id: '10000000-0000-4000-8000-000000000004',
        erlebnisId: erlebnisId,
        kriteriumId: kriteriumId,
        herkunftProfilId: profilId,
        textWert: 'Dunkel',
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
    );

    final geladen = await repository.ladeBewertungenFuerErlebnis(erlebnisId);
    expect(geladen.single.wert, isNull);
    expect(geladen.single.textWert, 'Dunkel');
    expect(geladen.single.kriteriumEingabetyp, KriteriumEingabetyp.auswahl);
    expect(geladen.single.kriteriumAuswahlwerte, ['Hell', 'Dunkel']);
  });

  test('Freitext bleibt beim Speichern und Laden erhalten', () async {
    const kriteriumId = '10000000-0000-4000-8000-000000000005';
    await repository.speichereKriterium(
      Bewertungskriterium(
        id: kriteriumId,
        name: 'Besonderheiten',
        eingabetyp: KriteriumEingabetyp.freitext,
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
    );

    await repository.speichereBewertung(
      Bewertung(
        id: '10000000-0000-4000-8000-000000000006',
        erlebnisId: erlebnisId,
        kriteriumId: kriteriumId,
        herkunftProfilId: profilId,
        textWert: 'Röstmalzig und rauchig',
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
    );

    final geladen = await repository.ladeBewertungenFuerErlebnis(erlebnisId);
    expect(geladen.single.textWert, 'Röstmalzig und rauchig');
  });

  test('Repository weist ungültige typisierte Werte zurück', () async {
    const kriteriumId = '10000000-0000-4000-8000-000000000007';
    await repository.speichereKriterium(
      Bewertungskriterium(
        id: kriteriumId,
        name: 'Ja oder nein',
        eingabetyp: KriteriumEingabetyp.jaNein,
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
    );

    expect(
      () => repository.speichereBewertung(
        Bewertung(
          id: '10000000-0000-4000-8000-000000000008',
          erlebnisId: erlebnisId,
          kriteriumId: kriteriumId,
          herkunftProfilId: profilId,
          wert: 2,
          erstelltAm: zeit,
          geaendertAm: zeit,
        ),
      ),
      throwsArgumentError,
    );
  });
}
