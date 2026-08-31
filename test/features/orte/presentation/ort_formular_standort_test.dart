import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/orte/presentation/ort_formular.dart';
import 'package:taugts/features/orte/services/standort_service.dart';

class _FesterIdGenerator implements IdGenerator {
  @override
  String neueId() => 'a1000000-0000-4000-8000-000000000001';
}

class _StandortService implements StandortService {
  _StandortService({this.ergebnis, this.fehler});

  final StandortErgebnis? ergebnis;
  final Object? fehler;
  var aufrufe = 0;

  @override
  Future<StandortErgebnis> aktuellenStandortErmitteln() async {
    aufrufe++;
    if (fehler != null) throw fehler!;
    return ergebnis!;
  }
}

void main() {
  late LokaleDatenbank datenbank;
  late SqliteBewertungsRepository repository;

  setUp(() {
    datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    repository = SqliteBewertungsRepository(datenbank);
  });

  tearDown(() => datenbank.schliessen());

  Future<void> formularAnzeigen(
    WidgetTester tester,
    StandortService standortService,
  ) =>
      tester.pumpWidget(
        MaterialApp(
          home: OrtFormular(
            repository: repository,
            idGenerator: _FesterIdGenerator(),
            standortService: standortService,
          ),
        ),
      );

  testWidgets('ermittelt den Standort nur nach bewusster Nutzeraktion',
      (tester) async {
    final service = _StandortService(
      ergebnis: const StandortErgebnis(
        breitengrad: 50.8323,
        laengengrad: 12.9253,
        genauigkeitMeter: 7.6,
      ),
    );
    await formularAnzeigen(tester, service);

    expect(service.aufrufe, 0);
    await tester.tap(find.text('Aktuellen Standort verwenden'));
    await tester.pumpAndSettle();

    expect(service.aufrufe, 1);
    expect(find.textContaining('Breitengrad: 50.832300'), findsOneWidget);
    expect(find.textContaining('Längengrad: 12.925300'), findsOneWidget);
    expect(find.textContaining('Genauigkeit: 8 m'), findsOneWidget);
  });

  testWidgets(
      'übernimmt Koordinaten erst nach Bestätigung und lässt Änderungen zu',
      (tester) async {
    final service = _StandortService(
      ergebnis: const StandortErgebnis(
        breitengrad: 50.8323,
        laengengrad: 12.9253,
      ),
    );
    await formularAnzeigen(tester, service);

    await tester.tap(find.text('Aktuellen Standort verwenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Koordinaten übernehmen'));
    await tester.pumpAndSettle();

    final breite = find.widgetWithText(TextFormField, 'Breitengrad (optional)');
    final laenge = find.widgetWithText(TextFormField, 'Längengrad (optional)');
    expect(find.text('Standort übernommen. Koordinaten sind bearbeitbar.'),
        findsOneWidget);
    expect(tester.widget<TextFormField>(breite).controller!.text, '50.832300');
    expect(tester.widget<TextFormField>(laenge).controller!.text, '12.925300');

    await tester.enterText(breite, '50,9');
    await tester.enterText(laenge, '');
    expect(tester.widget<TextFormField>(breite).controller!.text, '50,9');
    expect(tester.widget<TextFormField>(laenge).controller!.text, isEmpty);
  });

  testWidgets('zeigt Berechtigungsfehler und lässt manuelle Eingabe nutzbar',
      (tester) async {
    final service = _StandortService(
      fehler: const StandortAusnahme(
        'Die Standortberechtigung wurde nicht erteilt.',
      ),
    );
    await formularAnzeigen(tester, service);

    await tester.tap(find.text('Aktuellen Standort verwenden'));
    await tester.pumpAndSettle();

    expect(find.text('Die Standortberechtigung wurde nicht erteilt.'),
        findsOneWidget);
    final breite = find.widgetWithText(TextFormField, 'Breitengrad (optional)');
    await tester.enterText(breite, '50.8');
    expect(tester.widget<TextFormField>(breite).controller!.text, '50.8');
  });
}
