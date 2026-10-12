import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';
import 'package:taugts/features/auswertungen/presentation/statistik_verlauf_darstellung.dart';

void main() {
  testWidgets('Verlauf zeigt Diagramm und zugängliche Datentabelle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
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
    expect(find.text('2.00'), findsOneWidget);
    expect(find.text('4.00'), findsOneWidget);
  });
}
