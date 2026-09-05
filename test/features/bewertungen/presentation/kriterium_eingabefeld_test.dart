import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/presentation/kriterium_eingabefeld.dart';

void main() {
  final zeit = DateTime.utc(2026, 9, 5);

  Bewertungskriterium kriterium(
    KriteriumEingabetyp typ, {
    List<String> auswahlwerte = const [],
  }) =>
      Bewertungskriterium(
        id: '10000000-0000-4000-8000-000000000001',
        name: 'Testkriterium',
        eingabetyp: typ,
        auswahlwerte: auswahlwerte,
        erstelltAm: zeit,
        geaendertAm: zeit,
      );

  Future<KriteriumEingabewert?> anzeigen(
    WidgetTester tester,
    Bewertungskriterium kriterium,
  ) async {
    KriteriumEingabewert? letzterWert;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KriteriumEingabefeld(
            kriterium: kriterium,
            wert: const KriteriumEingabewert(),
            onChanged: (wert) => letzterWert = wert,
          ),
        ),
      ),
    );
    return letzterWert;
  }

  testWidgets('Wertung bietet die Qualitätsskala 1 bis 5 an', (tester) async {
    await anzeigen(tester, kriterium(KriteriumEingabetyp.wertung));

    await tester.tap(find.byType(DropdownButtonFormField<double?>));
    await tester.pumpAndSettle();

    expect(find.text('1 – taugt gar nicht'), findsOneWidget);
    expect(find.text('5 – taugt sehr'), findsOneWidget);
  });

  testWidgets('Intensität bietet die Intensitätsskala 1 bis 5 an',
      (tester) async {
    await anzeigen(tester, kriterium(KriteriumEingabetyp.intensitaet));

    await tester.tap(find.byType(DropdownButtonFormField<double?>));
    await tester.pumpAndSettle();

    expect(find.text('1 – sehr gering'), findsOneWidget);
    expect(find.text('5 – sehr stark'), findsOneWidget);
  });

  testWidgets('Ja/Nein liefert 1 für Ja und 0 für Nein', (tester) async {
    KriteriumEingabewert? wert;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KriteriumEingabefeld(
            kriterium: kriterium(KriteriumEingabetyp.jaNein),
            wert: const KriteriumEingabewert(),
            onChanged: (neu) => wert = neu,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<double?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ja').last);
    await tester.pumpAndSettle();

    expect(wert?.zahl, 1);
  });

  testWidgets('Zahl akzeptiert Dezimalwerte außerhalb 1 bis 5', (tester) async {
    KriteriumEingabewert? wert;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KriteriumEingabefeld(
            kriterium: kriterium(KriteriumEingabetyp.zahl),
            wert: const KriteriumEingabewert(),
            onChanged: (neu) => wert = neu,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '12,5');
    await tester.pump();

    expect(wert?.zahl, 12.5);
    expect(wert?.fehler, isNull);

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();
    expect(wert?.fehler, 'Bitte eine gültige Zahl eingeben.');
  });

  testWidgets('Auswahl bietet ausschließlich konfigurierte Werte an',
      (tester) async {
    KriteriumEingabewert? wert;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KriteriumEingabefeld(
            kriterium: kriterium(
              KriteriumEingabetyp.auswahl,
              auswahlwerte: const ['Hell', 'Dunkel'],
            ),
            wert: const KriteriumEingabewert(),
            onChanged: (neu) => wert = neu,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    expect(find.text('Hell'), findsOneWidget);
    expect(find.text('Dunkel'), findsOneWidget);
    await tester.tap(find.text('Dunkel').last);
    await tester.pumpAndSettle();

    expect(wert?.text, 'Dunkel');
  });

  testWidgets('Freitext übernimmt freien Text und begrenzt ihn auf 500 Zeichen',
      (tester) async {
    KriteriumEingabewert? wert;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KriteriumEingabefeld(
            kriterium: kriterium(KriteriumEingabetyp.freitext),
            wert: const KriteriumEingabewert(),
            onChanged: (neu) => wert = neu,
          ),
        ),
      ),
    );

    final feld = tester.widget<TextField>(find.byType(TextField));
    expect(feld.maxLength, 500);

    await tester.enterText(find.byType(TextField), 'Röstmalzig und rauchig');
    await tester.pump();
    expect(wert?.text, 'Röstmalzig und rauchig');
  });
}
