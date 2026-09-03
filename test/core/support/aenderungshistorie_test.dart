import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/core/support/app_info.dart';
import 'package:taugts/core/support/app_info_service.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/changelog_service.dart';
import 'package:taugts/core/support/support_kontexte.dart';

void main() {
  testWidgets('Änderungshistorie steht zwischen Hilfe und Projektseite', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: const [
              AppSupportMenu(
                contextName: SupportKontexte.startseite,
                appInfoGateway: _FakeAppInfoGateway(),
                changelogGateway: _FakeChangelogGateway(),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('App-Menü öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Über'));
    await tester.pumpAndSettle();

    final hilfe = tester.getTopLeft(find.text('Hilfe')).dy;
    final historie = tester.getTopLeft(find.text('Änderungshistorie')).dy;
    final projektseite = tester.getTopLeft(find.text('Projektseite')).dy;
    expect(hilfe, lessThan(historie));
    expect(historie, lessThan(projektseite));

    await tester.tap(find.text('Änderungshistorie'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Teständerung'), findsOneWidget);
    expect(find.byKey(const Key('aenderungshistorie-inhalt')), findsOneWidget);
  });

  testWidgets('Lesefehler der Änderungshistorie wird verständlich angezeigt', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _HistorieOeffnenButton(),
        ),
      ),
    );

    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Änderungshistorie konnte nicht geladen werden'),
      findsOneWidget,
    );
  });
}

class _HistorieOeffnenButton extends StatelessWidget {
  const _HistorieOeffnenButton();

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => zeigeAenderungshistorie(
          context,
          changelogGateway: const _FehlerChangelogGateway(),
        ),
        child: const Text('Öffnen'),
      );
}

class _FakeAppInfoGateway implements AppInfoGateway {
  const _FakeAppInfoGateway();

  @override
  Future<AppInfo> laden() async =>
      const AppInfo(version: '1.2.3', buildNumber: '45');
}

class _FakeChangelogGateway implements ChangelogGateway {
  const _FakeChangelogGateway();

  @override
  Future<String> laden() async => '# Änderungshistorie\n\n- Teständerung';
}

class _FehlerChangelogGateway implements ChangelogGateway {
  const _FehlerChangelogGateway();

  @override
  Future<String> laden() async => throw StateError('Testfehler');
}
