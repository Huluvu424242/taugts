import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/core/support/app_info.dart';
import 'package:taugts/core/support/app_info_service.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/external_url_service.dart';
import 'package:taugts/core/support/support_kontexte.dart';

void main() {
  testWidgets('Über zeigt Version und offline Barrierefreiheitserklärung', (
    tester,
  ) async {
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

    expect(find.text('Über Taugt’s?'), findsOneWidget);
    expect(find.text('Releaseversion 1.2.3+45'), findsOneWidget);
    expect(
      tester
          .widgetList<BugMeldenButton>(find.byType(BugMeldenButton))
          .map((button) => button.contextName),
      contains(SupportKontexte.ueberDialog),
    );

    await tester.tap(find.text('Barrierefreiheitserklärung'));
    await tester.pumpAndSettle();

    expect(find.text('Bekannte Barrieren'), findsOneWidget);
    expect(find.text('Barrieren melden'), findsOneWidget);
    expect(
      tester
          .widgetList<BugMeldenButton>(find.byType(BugMeldenButton))
          .map((button) => button.contextName),
      contains(SupportKontexte.barrierefreiheitserklaerung),
    );
  });

  testWidgets('Bugreport validiert und öffnet vorausgefülltes GitHub-Issue', (
    tester,
  ) async {
    final urlGateway = _FakeExternalUrlGateway();
    await tester.pumpWidget(
      _testApp(
        AppSupportMenu(
          contextName: SupportKontexte.produktErfassen,
          appInfoGateway: const _FakeAppInfoGateway(),
          externalUrlGateway: urlGateway,
        ),
      ),
    );

    await tester.tap(find.byTooltip('App-Menü öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bug melden'));
    await tester.pumpAndSettle();

    expect(
      find.text('Kontext: ${SupportKontexte.produktErfassen}'),
      findsOneWidget,
    );
    expect(find.text('Releaseversion: 1.2.3+45'), findsOneWidget);
    expect(
      find.textContaining('Anmeldung bei GitHub erforderlich'),
      findsOneWidget,
    );

    await tester.tap(find.text('Auf GitHub prüfen'));
    await tester.pumpAndSettle();
    expect(find.text('Bitte Eingaben prüfen'), findsOneWidget);

    final auswahl = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(auswahl);
    await tester.tap(auswahl);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barrierefreiheitsfehler').last);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Beschreibung'),
      'Der Fokus ist nicht sichtbar.',
    );
    await tester.tap(find.text('Auf GitHub prüfen'));
    await tester.pumpAndSettle();

    final uri = Uri.parse(urlGateway.geoeffneteUrl!);
    expect(uri.host, 'github.com');
    expect(uri.path, '/Huluvu424242/taugts/issues/new');
    expect(uri.queryParameters['template'], 'app_bug_report.md');
    expect(uri.queryParameters['labels'], 'bug');
    expect(uri.queryParameters['title'], contains('Barrierefreiheitsfehler'));
    expect(uri.queryParameters['body'], contains('Produkt erfassen'));
    expect(uri.queryParameters['body'], contains('1.2.3+45'));
    expect(
        uri.queryParameters['body'], contains('Der Fokus ist nicht sichtbar.'));
    expect(uri.queryParameters['body'], isNot(contains('token')));
  });

  testWidgets('Fehler beim externen Öffnen erhält Eingaben und Dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        AppSupportMenu(
          contextName: SupportKontexte.ortBearbeiten,
          appInfoGateway: const _FakeAppInfoGateway(),
          externalUrlGateway: _FehlenderExternalUrlGateway(),
        ),
      ),
    );

    await tester.tap(find.byTooltip('App-Menü öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bug melden'));
    await tester.pumpAndSettle();

    final auswahl = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(auswahl);
    await tester.tap(auswahl);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sonstiges').last);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Beschreibung'),
      'Meine Eingabe bleibt erhalten.',
    );
    await tester.tap(find.text('Auf GitHub prüfen'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('konnte nicht auf GitHub geöffnet werden'),
      findsOneWidget,
    );
    expect(find.text('Meine Eingabe bleibt erhalten.'), findsOneWidget);
    expect(find.text('Bug melden'), findsWidgets);
  });

  testWidgets('Fehlende App-Version wird verständlich gemeldet',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        AppSupportMenu(
          contextName: SupportKontexte.appStart,
          appInfoGateway: const _FehlenderAppInfoGateway(),
          externalUrlGateway: _FakeExternalUrlGateway(),
        ),
      ),
    );

    await tester.tap(find.byTooltip('App-Menü öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bug melden'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Releaseversion konnte nicht geladen werden'),
      findsOneWidget,
    );
  });

  test('alle fachlichen Aufrufkontexte sind eindeutig', () {
    const kontexte = [
      SupportKontexte.appStart,
      SupportKontexte.startseite,
      SupportKontexte.profil,
      SupportKontexte.produkteVerwalten,
      SupportKontexte.produktAuswaehlen,
      SupportKontexte.produktErfassen,
      SupportKontexte.produktBearbeiten,
      SupportKontexte.orteVerwalten,
      SupportKontexte.ortAuswaehlen,
      SupportKontexte.ortErfassen,
      SupportKontexte.ortBearbeiten,
      SupportKontexte.bewertungsentwuerfe,
      SupportKontexte.bewertungErfassen,
      SupportKontexte.bewertungsentwurfBearbeiten,
      SupportKontexte.getraenkBewertung,
      SupportKontexte.ueberDialog,
      SupportKontexte.barrierefreiheitserklaerung,
    ];

    expect(kontexte.toSet(), hasLength(kontexte.length));
    expect(
      SupportKontexte.produktFormular(bearbeiten: false),
      SupportKontexte.produktErfassen,
    );
    expect(
      SupportKontexte.erlebnis(entwurfBearbeiten: true),
      SupportKontexte.bewertungsentwurfBearbeiten,
    );
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

class _FehlenderAppInfoGateway implements AppInfoGateway {
  const _FehlenderAppInfoGateway();

  @override
  Future<AppInfo> laden() async => throw StateError('Testfehler');
}

class _FakeExternalUrlGateway implements ExternalUrlGateway {
  String? geoeffneteUrl;

  @override
  Future<void> oeffnen(String url) async {
    geoeffneteUrl = url;
  }
}

class _FehlenderExternalUrlGateway implements ExternalUrlGateway {
  @override
  Future<void> oeffnen(String url) async => throw StateError('Testfehler');
}
