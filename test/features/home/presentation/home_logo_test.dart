import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('Hauptmenü zeigt kleines Logo ohne höhere App-Bar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    final logoFinder = find.byKey(const Key('hauptmenue-logo'));
    expect(logoFinder, findsOneWidget);
    expect(tester.widget<AppLogo>(logoFinder).size, 20);
    expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);

    final titel = tester.getRect(find.text('Taugt’s?'));
    final logo = tester.getRect(logoFinder);
    expect(logo.left, greaterThan(titel.right));
  });
}
