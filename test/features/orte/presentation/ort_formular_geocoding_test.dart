import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/orte/presentation/ort_formular.dart';
import 'package:taugts/features/orte/services/geocoding_service.dart';

class _FesterIdGenerator implements IdGenerator {
  @override
  String neueId() => 'a1000000-0000-4000-8000-000000000001';
}

class _GeocodingService implements GeocodingService {
  _GeocodingService({this.ergebnis, this.fehler});

  final Adressvorschlag? ergebnis;
  final Object? fehler;
  var aufrufe = 0;

  @override
  Future<Adressvorschlag?> adresseVorschlagen({
    required double breitengrad,
    required double laengengrad,
  }) async {
    aufrufe++;
    if (fehler != null) throw fehler!;
    return ergebnis;
  }
}

void main() {
  late LokaleDatenbank datenbank;
  late SqliteBewertungsRepository repository;

  setUp(() {
    datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    repository = SqliteBewertungsRepository(datenbank);
  });

  tearDown(() => datenbank.schliessen());

  Future<void> formularAnzeigen(
    WidgetTester tester,
    GeocodingService service, {
    bool privat = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrtFormular(
          repository: repository,
          idGenerator: _FesterIdGenerator(),
          geocodingService: service,
        ),
      ),
    );
    if (privat) {
      await tester.scrollUntilVisible(
        find.byType(DropdownButtonFormField),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(DropdownButtonFormField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Privater Ort').last);
      await tester.pumpAndSettle();
    }
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Breitengrad (optional)'),
      '50.8323',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Längengrad (optional)'),
      '12.9253',
    );
    await tester.scrollUntilVisible(
      find.text('Adresse aus Koordinaten vorschlagen'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
  }

  testWidgets('ruft Geocoding ausschließlich nach Nutzeraktion auf', (tester) async {
    final service = _GeocodingService(
      ergebnis: const Adressvorschlag(
        name: 'Testgaststätte',
        adresse: 'Teststraße 1, Chemnitz',
      ),
    );
    await formularAnzeigen(tester, service);

    expect(service.aufrufe, 0);
    await tester.tap(find.text('Adresse aus Koordinaten vorschlagen'));
    await tester.pumpAndSettle();

    expect(service.aufrufe, 1);
    expect(find.textContaining('Testgaststätte'), findsOneWidget);
    expect(find.textContaining('Teststraße 1, Chemnitz'), findsOneWidget);
  });

  testWidgets('übernimmt Vorschlag erst nach Bestätigung', (tester) async {
    final service = _GeocodingService(
      ergebnis: const Adressvorschlag(
        name: 'Testgaststätte',
        adresse: 'Teststraße 1, Chemnitz',
      ),
    );
    await formularAnzeigen(tester, service);

    await tester.tap(find.text('Adresse aus Koordinaten vorschlagen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vorschlag übernehmen'));
    await tester.pumpAndSettle();

    final name = find.widgetWithText(TextFormField, 'Name');
    final adresse = find.widgetWithText(TextFormField, 'Adresse (optional)');
    await tester.scrollUntilVisible(
      name,
      -120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<TextFormField>(name).controller!.text, 'Testgaststätte');
    await tester.scrollUntilVisible(
      adresse,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.widget<TextFormField>(adresse).controller!.text,
      'Teststraße 1, Chemnitz',
    );
  });

  testWidgets('Providerfehler blockiert das Formular nicht', (tester) async {
    final service = _GeocodingService(
      fehler: const GeocodingAusnahme('Adressdienst nicht erreichbar.'),
    );
    await formularAnzeigen(tester, service);

    await tester.tap(find.text('Adresse aus Koordinaten vorschlagen'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Adressdienst nicht erreichbar.'),
      -120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Adressdienst nicht erreichbar.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ort speichern'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ort speichern'), findsOneWidget);
  });

  testWidgets('private Orte übertragen keine exakten Koordinaten', (tester) async {
    final service = _GeocodingService();
    await formularAnzeigen(tester, service, privat: true);
    await tester.tap(find.text('Adresse aus Koordinaten vorschlagen'));
    await tester.pumpAndSettle();

    expect(service.aufrufe, 0);
    await tester.scrollUntilVisible(
      find.textContaining('private Orte werden exakte Koordinaten nicht'),
      -120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining('private Orte werden exakte Koordinaten nicht'),
      findsOneWidget,
    );
  });
}
