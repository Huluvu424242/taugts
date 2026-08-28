import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/app/taugts_app.dart';

void main() {
  testWidgets('zeigt den Startbildschirm', (WidgetTester tester) async {
    await tester.pumpWidget(const TaugtsApp());

    expect(find.text('Taugt’s?'), findsOneWidget);
    expect(find.text('Was taugt’s?'), findsOneWidget);
  });
}
