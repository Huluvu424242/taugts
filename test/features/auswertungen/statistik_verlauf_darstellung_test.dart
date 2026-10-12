import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';
import 'package:taugts/features/auswertungen/presentation/statistik_verlauf_darstellung.dart';

void main() {
  testWidgets(
    'Verlauf zeigt Diagramm und zugängliche Datentabelle',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatistikVerlaufDarstellung(
              daten: [
                Zeitwert(
                  zeitpunkt: DateTime.utc(2024, 1, 1),
                  wert: 2,
                  beschreibung: 'Biergarten · EUR',
                  serie: 'EUR',
                ),
                Zeitwert(
                  zeitpunkt: DateTime.utc(2026, 1, 1),
                  wert: 4,
                  beschreibung: 'Biergarten · EUR',
                  serie: 'EUR',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Zeitpunkt'), findsOneWidget);
      expect(find.text('Wert'), findsOneWidget);
      expect(find.text('Einheit: EUR'), findsOneWidget);
      expect(find.text('2,00'), findsOneWidget);
      expect(find.text('4,00'), findsOneWidget);
    },
  );
  testWidgets('Aggregierte Verläufe zeigen Anzahl, Minimum und Maximum',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatistikVerlaufDarstellung(
            daten: [
              Zeitwert(
                zeitpunkt: DateTime(2026, 5),
                wert: 3,
                beschreibung: 'Geschmack · Version 2',
                kennzahlen: const StatistikKennzahlen(
                  anzahl: 3,
                  minimum: 1,
                  maximum: 5,
                  durchschnitt: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Mittelwert'), findsOneWidget);
    expect(find.text('Anzahl'), findsOneWidget);
    expect(find.text('Minimum'), findsOneWidget);
    expect(find.text('Maximum'), findsOneWidget);
    expect(find.textContaining('Version 2'), findsOneWidget);
  });

  testWidgets('Auffälligkeit öffnet zugehöriges Erlebnis über Callback',
      (tester) async {
    String? geoeffnet;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatistikVerlaufDarstellung(
            daten: [
              Zeitwert(
                zeitpunkt: DateTime(2000, 1, 5, 18),
                zeitpunktBeschriftung: 'Wochentag 3 · 18:00 Uhr',
                wert: 2,
                beschreibung: 'Geschmack · Version 1 · 2 von 3',
                erlebnisIds: const ['erlebnis-1'],
              ),
            ],
            onErlebnisOeffnen: (id) => geoeffnet = id,
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Erlebnis öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erlebnis öffnen'));
    expect(geoeffnet, 'erlebnis-1');
  });
}
