import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/presentation/gaststaettenbewertung_abschnitt.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';

void main() {
  late LokaleDatenbank datenbank;
  late SqliteBewertungsRepository repository;
  late Ort ort;
  late Erlebnis erlebnis;

  setUp(() async {
    datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    repository = SqliteBewertungsRepository(datenbank);
    final zeit = DateTime.utc(2026, 8, 31, 18);
    const profilId = '81000000-0000-4000-8000-000000000000';
    datenbank.verbindung.execute(
      'INSERT INTO profile VALUES (?, ?, ?, ?)',
      [profilId, 'Testprofil', zeit.toIso8601String(), zeit.toIso8601String()],
    );
    ort = Ort(
      id: '81000000-0000-4000-8000-000000000001',
      name: 'Testgaststätte',
      typ: Ortstyp.gastronomie,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    erlebnis = Erlebnis(
      id: '81000000-0000-4000-8000-000000000002',
      ortId: ort.id,
      herkunftProfilId: profilId,
      tatsaechlicherBeginn: zeit,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereOrt(ort);
    await repository.speichereErlebnis(erlebnis);
  });

  tearDown(() => datenbank.schliessen());

  testWidgets('zeigt eingeklappt den leeren Status und große Schrift',
      (tester) async {
    final leer = _LeereKriterienRepository(datenbank);
    await _pumpAbschnitt(
      tester,
      leer,
      ort,
      erlebnis,
      textScaler: const TextScaler.linear(2),
    );

    expect(
      find.text('Noch keine Bewertung für diesen Besuch.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Gaststätte bewerten'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Keine aktiven Gaststättenkriterien. Eine Notiz kann dennoch gespeichert werden.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('zeigt Ladefehler verständlich und wiederholbar', (tester) async {
    await _pumpAbschnitt(
      tester,
      _LadefehlerRepository(datenbank),
      ort,
      erlebnis,
    );
    await tester.tap(find.text('Gaststätte bewerten'));
    await tester.pumpAndSettle();

    expect(
      find.text('Die Gaststättenbewertung konnte nicht geladen werden.'),
      findsOneWidget,
    );
    expect(find.text('Bewertung erneut laden'), findsOneWidget);
  });

  testWidgets('speichert eine Bewertung und zeigt den bewerteten Status',
      (tester) async {
    await _pumpAbschnitt(tester, repository, ort, erlebnis);
    await tester.tap(find.text('Gaststätte bewerten'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Gesamturteil'));
    await tester.tap(find.text('Gesamturteil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 – taugt sehr').last);
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Bewertung speichern'));
    await tester.tap(find.text('Bewertung speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Gaststättenbewertung gespeichert.'), findsOneWidget);
    expect(
      find.text('Für diesen Besuch liegt eine Bewertung vor.'),
      findsOneWidget,
    );
    final gespeichert =
        await repository.ladeOrtsbewertungFuerErlebnis(erlebnis.id);
    expect(gespeichert?.werte.single.wert, 5);
    expect(gespeichert?.ortsbewertung.bewertetAm, erlebnis.erlebtAm);

    await _pumpAbschnitt(tester, repository, ort, erlebnis);
    expect(
      find.text('Für diesen Besuch liegt eine Bewertung vor.'),
      findsOneWidget,
    );
  });

  testWidgets('validiert und behält Eingaben bei einem Persistenzfehler',
      (tester) async {
    final fehlerhaft = _SpeicherfehlerRepository(datenbank);
    await _pumpAbschnitt(tester, fehlerhaft, ort, erlebnis);
    await tester.tap(find.text('Gaststätte bewerten'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Bewertung speichern'));
    await tester.tap(find.text('Bewertung speichern'));
    await tester.pumpAndSettle();

    expect(
      find.text('Mindestens eine Wertung oder Notiz ist erforderlich.'),
      findsOneWidget,
    );
    expect(find.text('Bitte Gaststättenbewertung prüfen.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Gesamturteil'));
    await tester.tap(find.text('Gesamturteil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4 – taugt eher').last);
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Bewertung speichern'));
    await tester.tap(find.text('Bewertung speichern'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Die Gaststättenbewertung konnte nicht gespeichert werden.',
      ),
      findsOneWidget,
    );
    expect(find.text('4 – taugt eher'), findsOneWidget);
  });
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );

Future<void> _pumpAbschnitt(
  WidgetTester tester,
  SqliteBewertungsRepository repository,
  Ort ort,
  Erlebnis erlebnis, {
  TextScaler textScaler = const TextScaler.linear(1),
}) async {
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: textScaler),
      child: Scaffold(
        body: ListView(
          children: [
            GaststaettenbewertungAbschnitt(
              repository: repository,
              idGenerator: _TestIdGenerator(),
              erlebnis: erlebnis,
              ort: ort,
            ),
          ],
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

class _TestIdGenerator implements IdGenerator {
  var _wert = 10;

  @override
  String neueId() {
    _wert++;
    return '81000000-0000-4000-8000-${_wert.toString().padLeft(12, '0')}';
  }
}

class _LeereKriterienRepository extends SqliteBewertungsRepository {
  _LeereKriterienRepository(super.datenbank);

  @override
  Future<List<Bewertungskriterium>> ladeAktiveKriterienFuerObjektart(
    KriteriumObjektart objektart,
  ) async =>
      [];
}

class _LadefehlerRepository extends SqliteBewertungsRepository {
  _LadefehlerRepository(super.datenbank);

  @override
  Future<List<Bewertungskriterium>> ladeAktiveKriterienFuerObjektart(
    KriteriumObjektart objektart,
  ) =>
      Future.error(StateError('Testfehler'));
}

class _SpeicherfehlerRepository extends SqliteBewertungsRepository {
  _SpeicherfehlerRepository(super.datenbank);

  @override
  Future<void> speichereOrtsbewertung({
    required Erlebnis erlebnis,
    required Ort ort,
    required Ortsbewertung ortsbewertung,
    required List<Bewertung> bewertungen,
  }) =>
      Future.error(StateError('Testfehler'));
}
