import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('Hauptmenü zeigt gut erkennbares KI-Logo ohne höhere App-Bar',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    final logoFinder = find.byKey(const Key('hauptmenue-logo'));
    expect(logoFinder, findsOneWidget);
    expect(tester.widget<AppLogo>(logoFinder).size, 32);
    expect(tester.getSize(logoFinder), const Size.square(32));
    expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);

    final titel = tester.getRect(find.text('Taugt’s?'));
    final logo = tester.getRect(logoFinder);
    expect(logo.left, greaterThan(titel.right));
    expect(find.byTooltip('App-Menü öffnen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
