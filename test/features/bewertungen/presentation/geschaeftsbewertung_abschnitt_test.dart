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
    final zeit = DateTime.utc(2026, 9, 1, 10);
    const profilId = '82000000-0000-4000-8000-000000000000';
    datenbank.verbindung.execute(
      'INSERT INTO profile VALUES (?, ?, ?, ?)',
      [profilId, 'Testprofil', zeit.toIso8601String(), zeit.toIso8601String()],
    );
    ort = Ort(
      id: '82000000-0000-4000-8000-000000000001',
      name: 'Testmarkt',
      typ: Ortstyp.geschaeft,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    erlebnis = Erlebnis(
      id: '82000000-0000-4000-8000-000000000002',
      typ: Erlebnistyp.einkauf,
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

  testWidgets('Einkauf zeigt Geschäftskriterien getrennt an', (tester) async {
    await _pumpAbschnitt(tester, repository, ort, erlebnis);

    expect(find.text('Geschäft bewerten'), findsOneWidget);
    expect(
        find.text('Noch keine Bewertung für diesen Einkauf.'), findsOneWidget);

    await tester.tap(find.text('Geschäft bewerten'));
    await tester.pumpAndSettle();

    expect(find.text('Gesamturteil'), findsOneWidget);
    expect(find.text('Andrang / Auslastung'), findsOneWidget);
    expect(find.text('Wartezeit'), findsOneWidget);
  });

  testWidgets('Geschäftsbewertung bleibt vom Einkauf getrennt gespeichert',
      (tester) async {
    await _pumpAbschnitt(tester, repository, ort, erlebnis);
    await tester.tap(find.text('Geschäft bewerten'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<double?>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 – taugt sehr').last);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -650));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Bewertung speichern'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Geschäftsbewertung gespeichert.'), findsOneWidget);
    final gespeichert =
        await repository.ladeOrtsbewertungFuerErlebnis(erlebnis.id);
    expect(gespeichert, isNotNull);
    expect(gespeichert!.ortsbewertung.erlebnisId, erlebnis.id);
    expect(gespeichert.ortsbewertung.ortId, ort.id);
    expect(gespeichert.werte.single.wert, 5);
    expect(await repository.ladeErlebnispositionen(erlebnis.id), isEmpty);
  });
}

Future<void> _pumpAbschnitt(
  WidgetTester tester,
  SqliteBewertungsRepository repository,
  Ort ort,
  Erlebnis erlebnis,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
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
  );
  await tester.pumpAndSettle();
}

class _TestIdGenerator implements IdGenerator {
  var _wert = 10;

  @override
  String neueId() {
    _wert++;
    return '82000000-0000-4000-8000-${_wert.toString().padLeft(12, '0')}';
  }
}
