import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/presentation/getraenkebewertung_screen.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/profil/models/profil.dart';

void main() {
  late LokaleDatenbank datenbank;
  late SqliteBewertungsRepository repository;
  final zeit = DateTime.utc(2026, 8, 30, 18);
  late Profil profil;

  setUp(() async {
    profil = Profil(
      id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      anzeigename: 'Test',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    datenbank.verbindung.execute(
      'INSERT INTO profile VALUES (?, ?, ?, ?)',
      [
        profil.id,
        profil.anzeigename,
        zeit.toIso8601String(),
        zeit.toIso8601String(),
      ],
    );
    repository = SqliteBewertungsRepository(datenbank);
  });

  tearDown(() => datenbank.schliessen());

  testWidgets('bewertet nur das Gesamturteil unabhängig von Einzelwerten', (
    tester,
  ) async {
    final erlebnis = await _speichereAusgangsdaten(repository, zeit);
    await _oeffneBewertung(
      tester,
      repository: repository,
      erlebnis: erlebnis,
      profil: profil,
    );

    expect(find.text('Gesamturteil'), findsWidgets);
    expect(
      find.textContaining('nicht aus den Einzelwerten berechnet'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey(
          'kriterium-c0000000-0000-4000-8000-000000000001',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('4 – taugt eher').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bewertung speichern'));
    await tester.pumpAndSettle();

    final bewertungen =
        await repository.ladeBewertungenFuerErlebnis(erlebnis.id);
    expect(bewertungen, hasLength(1));
    expect(
      bewertungen.single.kriteriumId,
      StandardGetraenkekriterien.gesamturteilId,
    );
    expect(bewertungen.single.wert, 4);
    expect(await repository.ladeEntwuerfe(), isEmpty);
  });

  testWidgets('zeigt optionale Intensitäten und erhält eine Notiz', (
    tester,
  ) async {
    final erlebnis = await _speichereAusgangsdaten(repository, zeit);
    await _oeffneBewertung(
      tester,
      repository: repository,
      erlebnis: erlebnis,
      profil: profil,
    );

    await tester.scrollUntilVisible(
      find.text('Farbintensität'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bitterkeit'), findsWidgets);
    expect(find.text('Farbintensität'), findsWidgets);

    final notiz = find.widgetWithText(
      TextField,
      'Bewertungsnotiz (optional)',
    );
    await tester.ensureVisible(notiz);
    await tester.enterText(notiz, 'Heute deutlich herber als früher.');
    await tester.tap(find.text('Bewertung speichern'));
    await tester.pumpAndSettle();

    final zeile = datenbank.verbindung.select(
      'SELECT * FROM erlebnisse WHERE id = ?',
      [erlebnis.id],
    ).single;
    expect(zeile['notiz'], 'Heute deutlich herber als früher.');
    expect(
      await repository.ladeBewertungenFuerErlebnis(erlebnis.id),
      isEmpty,
    );
  });

  testWidgets('validiert leere Bewertung am Feld und im Fehlersammler', (
    tester,
  ) async {
    final erlebnis = await _speichereAusgangsdaten(repository, zeit);
    await _oeffneBewertung(
      tester,
      repository: repository,
      erlebnis: erlebnis,
      profil: profil,
    );

    await tester.tap(find.text('Bewertung speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Bitte Eingaben prüfen'), findsOneWidget);
    expect(
      find.text('Mindestens eine Bewertung oder Notiz ist erforderlich.'),
      findsOneWidget,
    );
    expect(
      find.text('Bitte eine Bewertung wählen oder eine Notiz eingeben.'),
      findsOneWidget,
    );
    expect(await repository.ladeEntwuerfe(), hasLength(1));
  });
}


Future<Erlebnis> _speichereAusgangsdaten(
  SqliteBewertungsRepository repository,
  DateTime zeit,
) async {
  const produktId = '10000000-0000-4000-8000-000000000001';
  await repository.speichereProdukt(Produkt(
    id: produktId,
    name: 'Testpils',
    erstelltAm: zeit,
    geaendertAm: zeit,
  ));
  final erlebnis = Erlebnis(
    id: '10000000-0000-4000-8000-000000000002',
    produktId: produktId,
    herkunftProfilId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    erlebtAm: zeit,
    erstelltAm: zeit,
    geaendertAm: zeit,
  );
  await repository.speichereErlebnis(erlebnis);
  return erlebnis;
}

Future<void> _oeffneBewertung(
  WidgetTester tester, {
  required SqliteBewertungsRepository repository,
  required Erlebnis erlebnis,
  required Profil profil,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => GetraenkebewertungScreen(
                    repository: repository,
                    idGenerator: _TestIdGenerator(),
                    profil: profil,
                    erlebnis: erlebnis,
                  ),
                ),
              ),
              child: const Text('Bewertung öffnen'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Bewertung öffnen'));
  await tester.pumpAndSettle();
}

class _TestIdGenerator implements IdGenerator {
  var _wert = 0;

  @override
  String neueId() {
    _wert++;
    return '20000000-0000-4000-8000-00000000000$_wert';
  }
}
