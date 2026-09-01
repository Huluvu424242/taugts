import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/core/support/app_info.dart';
import 'package:taugts/core/support/app_info_service.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/external_url_service.dart';
import 'package:taugts/core/support/support_kontexte.dart';

void main() {
  testWidgets('Über öffnet Projektseite und Projektdokumentation',
      (tester) async {
    final urlGateway = _FakeExternalUrlGateway();
    await tester.pumpWidget(
      _testApp(
        AppSupportMenu(
          contextName: SupportKontexte.startseite,
          appInfoGateway: const _FakeAppInfoGateway(),
          externalUrlGateway: urlGateway,
        ),
      ),
    );

    await _oeffneUeberDialog(tester);

    expect(find.text('Projektseite'), findsOneWidget);
    expect(find.text('Projektdokumentation'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Projektseite extern öffnen'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Projektdokumentation extern öffnen'),
      findsOneWidget,
    );

    await tester.tap(find.text('Projektseite'));
    await tester.pumpAndSettle();
    expect(urlGateway.geoeffneteUrls, [
      'https://github.com/Huluvu424242/taugts',
    ]);
    expect(find.text('Über Taugt’s?'), findsOneWidget);

    await tester.tap(find.text('Projektdokumentation'));
    await tester.pumpAndSettle();
    expect(urlGateway.geoeffneteUrls, [
      'https://github.com/Huluvu424242/taugts',
      'https://huluvu424242.github.io/taugts/',
    ]);
    expect(find.text('Über Taugt’s?'), findsOneWidget);
  });

  testWidgets('Fehler beim Öffnen eines Über-Links bleibt im Dialog sichtbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        AppSupportMenu(
          contextName: SupportKontexte.startseite,
          appInfoGateway: const _FakeAppInfoGateway(),
          externalUrlGateway: _FehlenderExternalUrlGateway(),
        ),
      ),
    );

    await _oeffneUeberDialog(tester);
    await tester.tap(find.text('Projektdokumentation'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Projektdokumentation konnte nicht geöffnet werden'),
      findsOneWidget,
    );
    expect(find.text('Über Taugt’s?'), findsOneWidget);
    expect(find.text('Schließen'), findsOneWidget);
  });
}

Future<void> _oeffneUeberDialog(WidgetTester tester) async {
  await tester.tap(find.byTooltip('App-Menü öffnen'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Über'));
  await tester.pumpAndSettle();
}

Widget _testApp(Widget menu) => MaterialApp(
      home: Scaffold(
        appBar: AppBar(actions: [menu]),
      ),
    );

class _FakeAppInfoGateway implements AppInfoGateway {
  const _FakeAppInfoGateway();

  @override
  Future<AppInfo> laden() async =>
      const AppInfo(version: '1.2.3', buildNumber: '45');
}

class _FakeExternalUrlGateway implements ExternalUrlGateway {
  final List<String> geoeffneteUrls = [];

  @override
  Future<void> oeffnen(String url) async {
    geoeffneteUrls.add(url);
  }
}

class _FehlenderExternalUrlGateway implements ExternalUrlGateway {
  @override
  Future<void> oeffnen(String url) async => throw StateError('Testfehler');
}
