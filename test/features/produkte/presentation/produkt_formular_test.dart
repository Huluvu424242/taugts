import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/produkte/presentation/produkt_formular.dart';

class _FesterIdGenerator implements IdGenerator {
  @override
  String neueId() => '55e34e0e-fb72-450d-9db7-20d42188d237';
}

void main() {
  late LokaleDatenbank datenbank;
  late SqliteBewertungsRepository repository;

  setUp(() {
    datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    repository = SqliteBewertungsRepository(datenbank);
  });

  tearDown(() => datenbank.schliessen());

  testWidgets('zeigt Pflichtfehler am Feld und im Fehlersammler',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProduktFormular(
          repository: repository,
          idGenerator: _FesterIdGenerator(),
        ),
      ),
    );

    final speichern = find.text('Produkt speichern');
    await tester.scrollUntilVisible(
      speichern,
      300.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(speichern);
    await tester.pumpAndSettle();

    expect(find.text('Bitte Eingaben prüfen'), findsOneWidget);
    expect(find.text('Name oder Barcode ist erforderlich.'), findsNWidgets(3));
    expect(await repository.ladeProdukte(), isEmpty);

    await tester.tap(
      find.widgetWithText(
        TextButton,
        'Name oder Barcode ist erforderlich.',
      ),
    );
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.context, isNotNull);
  });

  testWidgets('übernimmt gescannte EAN und erhält vorhandene Formulardaten',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProduktFormular(
          repository: repository,
          idGenerator: _FesterIdGenerator(),
          barcodeScanStart: (_) async => '4006381333931',
        ),
      ),
    );

    final textfelder = find.byType(TextFormField);
    await tester.enterText(textfelder.at(0), 'Testprodukt');
    await tester.enterText(textfelder.at(2), 'Testmarke');

    await tester.tap(find.byTooltip('EAN scannen'));
    await tester.pumpAndSettle();

    final name = tester.widget<TextFormField>(textfelder.at(0));
    final barcode = tester.widget<TextFormField>(textfelder.at(1));
    final marke = tester.widget<TextFormField>(textfelder.at(2));
    expect(name.controller?.text, 'Testprodukt');
    expect(barcode.controller?.text, '4006381333931');
    expect(marke.controller?.text, 'Testmarke');
  });

  testWidgets('behält vorhandene EAN bei Scan-Abbruch bei', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProduktFormular(
          repository: repository,
          idGenerator: _FesterIdGenerator(),
          barcodeVorgabe: '9780201379624',
          barcodeScanStart: (_) async => null,
        ),
      ),
    );

    await tester.tap(find.byTooltip('EAN scannen'));
    await tester.pumpAndSettle();

    final barcode =
        tester.widget<TextFormField>(find.byType(TextFormField).at(1));
    expect(barcode.controller?.text, '9780201379624');
  });
}
