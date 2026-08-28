import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/app/taugts_app.dart';

void main() {
  testWidgets('zeigt die Taugt’s?-Startseite', (tester) async {
    await tester.pumpWidget(const TaugtsApp());

    expect(find.text('Taugt’s?'), findsOneWidget);
    expect(find.text('Was taugt’s?'), findsOneWidget);
  });
}
