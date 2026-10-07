import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/suche/models/suchmodelle.dart';
import 'package:taugts/features/suche/presentation/suche_screen.dart';

void main() {
  Future<void> anzeigen(WidgetTester tester, Suchtreffer treffer) async {
    await tester.pumpWidget(
      MaterialApp(home: SuchtrefferDetailScreen(treffer: treffer)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'zeigt Produkt, Ort und Restaurantbesuch mit fachlichen Namen',
    (tester) async {
      await anzeigen(
        tester,
        Suchtreffer(
          id: 'bewertung-1',
          art: Suchziel.historie,
          titel: 'Produktbewertung · Pils Spezial',
          untertitel: 'Gesamturteil: 5',
          erlebnisId: 'erlebnis-technisch',
          produktId: 'produkt-technisch',
          ortId: 'ort-technisch',
          produktName: 'Pils Spezial',
          ortName: 'Zum Goldenen Fass',
          erlebnistyp: Erlebnistyp.restaurantbesuch,
          zeitpunkt: DateTime(2026, 9, 13, 19, 30),
        ),
      );

      expect(find.text('Produkt: Pils Spezial'), findsOneWidget);
      expect(find.text('Ort: Zum Goldenen Fass'), findsOneWidget);
      expect(
        find.textContaining(
          'Erlebnis: Restaurantbesuch – Zum Goldenen Fass –',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('produkt-technisch'), findsNothing);
      expect(find.textContaining('ort-technisch'), findsNothing);
      expect(find.textContaining('erlebnis-technisch'), findsNothing);
    },
  );

  testWidgets(
    'zeigt Einkauf und fehlende Zuordnungen verständlich',
    (tester) async {
      await anzeigen(
        tester,
        Suchtreffer(
          id: 'bewertung-2',
          art: Suchziel.historie,
          titel: 'Produktbewertung · Nicht zugeordnet',
          untertitel: 'Gesamturteil: 3',
          erlebnisId: 'erlebnis-technisch',
          produktId: 'produkt-technisch',
          ortId: 'ort-technisch',
          erlebnistyp: Erlebnistyp.einkauf,
          zeitpunkt: DateTime(2026, 9, 14, 10, 15),
        ),
      );

      expect(find.text('Produkt: Nicht zugeordnet'), findsOneWidget);
      expect(find.text('Ort: Nicht zugeordnet'), findsOneWidget);
      expect(
        find.textContaining('Erlebnis: Einkauf – Nicht zugeordnet –'),
        findsOneWidget,
      );
      expect(find.textContaining('produkt-technisch'), findsNothing);
      expect(find.textContaining('ort-technisch'), findsNothing);
      expect(find.textContaining('erlebnis-technisch'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
