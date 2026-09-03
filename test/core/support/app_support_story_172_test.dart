import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/core/support/app_info.dart';
import 'package:taugts/core/support/app_info_service.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/external_url_service.dart';
import 'package:taugts/core/support/support_kontexte.dart';

void main() {
  testWidgets('Über zeigt Story-172-Inhalte in der geforderten Reihenfolge', (
    tester,
  ) async {
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

    await tester.tap(find.byTooltip('App-Menü öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Über'));
    await tester.pumpAndSettle();

    final titel = find.text('Über Taugt’s?');
    final version = find.text('Releaseversion 1.2.3+45');
    final hilfe = find.text('Hilfe');
    final projektseite = find.text('Projektseite');
    final projektdokumentation = find.text('Projektdokumentation');
    final urheber = find.text('🄯  created by Huluvu424242');

    expect(titel, findsOneWidget);
    expect(find.text('Taugt’s?'), findsNothing);
    expect(version, findsOneWidget);
    expect(hilfe, findsOneWidget);
    expect(projektseite, findsOneWidget);
    expect(projektdokumentation, findsOneWidget);
    expect(urheber, findsOneWidget);

    expect(
        tester.getTopLeft(version).dy, lessThan(tester.getTopLeft(hilfe).dy));
    expect(
      tester.getTopLeft(hilfe).dy,
      lessThan(tester.getTopLeft(projektseite).dy),
    );
    expect(
      tester.getTopLeft(projektdokumentation).dy,
      lessThan(tester.getTopLeft(urheber).dy),
    );

    await tester.tap(hilfe);
    await tester.pumpAndSettle();

    expect(
      urlGateway.geoeffneteUrl,
      'https://huluvu424242.github.io/taugts/benutzer/',
    );
  });

  testWidgets('Über bleibt auf kleinem Display ohne Layoutfehler nutzbar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _testApp(
        AppSupportMenu(
          contextName: SupportKontexte.startseite,
          appInfoGateway: const _FakeAppInfoGateway(),
          externalUrlGateway: _FakeExternalUrlGateway(),
        ),
      ),
    );

    await tester.tap(find.byTooltip('App-Menü öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Über'));
    await tester.pumpAndSettle();

    expect(find.text('🄯  created by Huluvu424242'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
  String? geoeffneteUrl;

  @override
  Future<void> oeffnen(String url) async {
    geoeffneteUrl = url;
  }
}
