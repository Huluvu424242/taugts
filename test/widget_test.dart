import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/app/taugts_app.dart';

void main() {
  testWidgets('zeigt die mobile Taugt’s?-Startnavigation', (tester) async {
    await tester.pumpWidget(const TaugtsApp());

    expect(find.text('Taugt’s?'), findsOneWidget);
    expect(find.text('Was taugt’s?'), findsOneWidget);
    expect(find.text('Jetzt bewerten'), findsOneWidget);
    expect(find.text('Dinge'), findsOneWidget);
    expect(find.text('Orte'), findsOneWidget);
    expect(find.text('Bewertungen'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Alle Erlebnisse'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Suche'), findsOneWidget);
    expect(find.text('Import/Export'), findsOneWidget);
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Erlebnis registrieren'), findsOneWidget);
    expect(find.text('Alle Erlebnisse'), findsOneWidget);
  });
}
