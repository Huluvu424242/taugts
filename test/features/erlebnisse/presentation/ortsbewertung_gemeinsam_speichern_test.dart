import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/erlebnisse/presentation/erlebnis_screen.dart';
import 'package:taugts/features/profil/models/profil.dart';

void main() {
  late LokaleDatenbank datenbank;
  late SqliteBewertungsRepository repository;
  late Profil profil;
  final zeit = DateTime.utc(2026, 9, 3, 18);

  setUp(() {
    profil = Profil(
      id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    datenbank.verbindung.execute(
      'INSERT INTO profile VALUES (?, NULL, ?, ?)',
      [profil.id, zeit.toIso8601String(), zeit.toIso8601String()],
    );
    repository = SqliteBewertungsRepository(datenbank);
  });

  tearDown(() => datenbank.schliessen());

  for (final fall in [
    (
      typ: Erlebnistyp.restaurantbesuch,
      ortstyp: Ortstyp.gastronomie,
      abschnitt: 'Gaststätte bewerten',
      notiz: 'Restaurant gemeinsam gespeichert',
    ),
    (
      typ: Erlebnistyp.einkauf,
      ortstyp: Ortstyp.geschaeft,
      abschnitt: 'Geschäft bewerten',
      notiz: 'Geschäft gemeinsam gespeichert',
    ),
  ]) {
    testWidgets(
      'Speichern persistiert ${fall.abschnitt} zusammen mit dem Erlebnis',
      (tester) async {
        final erlebnis = await _vorbereiten(
          repository: repository,
          profil: profil,
          zeit: zeit,
          typ: fall.typ,
          ortstyp: fall.ortstyp,
        );

        await _screenOeffnen(
          tester: tester,
          repository: repository,
          profil: profil,
          erlebnis: erlebnis,
        );
        await tester.scrollUntilVisible(
          find.text(fall.abschnitt),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text(fall.abschnitt));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.widgetWithText(TextField, 'Notiz (optional)').last,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Notiz (optional)').last,
          fall.notiz,
        );

        await tester.tap(find.text('Speichern'));
        await tester.pumpAndSettle();

        final gespeichert =
            await repository.ladeOrtsbewertungFuerErlebnis(erlebnis.id);
        expect(gespeichert, isNotNull);
        expect(gespeichert!.ortsbewertung.notiz, fall.notiz);
        expect(find.text('Zur Bewertung'), findsOneWidget);
      },
    );
  }

  testWidgets('Speichern legt keine leere Ortsbewertung an', (tester) async {
    final erlebnis = await _vorbereiten(
      repository: repository,
      profil: profil,
      zeit: zeit,
      typ: Erlebnistyp.restaurantbesuch,
      ortstyp: Ortstyp.gastronomie,
    );

    await _screenOeffnen(
      tester: tester,
      repository: repository,
      profil: profil,
      erlebnis: erlebnis,
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(
      await repository.ladeOrtsbewertungFuerErlebnis(erlebnis.id),
      isNull,
    );
    expect(find.text('Zur Bewertung'), findsOneWidget);
  });
}

Future<Erlebnis> _vorbereiten({
  required SqliteBewertungsRepository repository,
  required Profil profil,
  required DateTime zeit,
  required Erlebnistyp typ,
  required Ortstyp ortstyp,
}) async {
  final suffix = typ == Erlebnistyp.einkauf ? '2' : '1';
  final ort = Ort(
    id: '75000000-0000-4000-8000-00000000000$suffix',
    name: ortstyp == Ortstyp.geschaeft ? 'Testgeschäft' : 'Testgaststätte',
    typ: ortstyp,
    erstelltAm: zeit,
    geaendertAm: zeit,
  );
  final erlebnis = Erlebnis(
    id: '76000000-0000-4000-8000-00000000000$suffix',
    typ: typ,
    ortId: ort.id,
    herkunftProfilId: profil.id,
    istEntwurf: false,
    erstelltAm: zeit,
    geaendertAm: zeit,
  );
  await repository.speichereOrt(ort);
  await repository.speichereErlebnis(erlebnis);
  return erlebnis;
}

Future<void> _screenOeffnen({
  required WidgetTester tester,
  required SqliteBewertungsRepository repository,
  required Profil profil,
  required Erlebnis erlebnis,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => ErlebnisScreen(
                    repository: repository,
                    idGenerator: _TestIdGenerator(),
                    profil: profil,
                    erlebnis: erlebnis,
                  ),
                ),
              ),
              child: const Text('Zur Bewertung'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Zur Bewertung'));
  await tester.pumpAndSettle();
}

class _TestIdGenerator implements IdGenerator {
  var _wert = 0;

  @override
  String neueId() {
    _wert++;
    return '70000000-0000-4000-8000-${_wert.toString().padLeft(12, '0')}';
  }
}
