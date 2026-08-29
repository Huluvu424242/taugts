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

  testWidgets('zeigt Pflichtfehler am Feld und im Fehlersammler', (tester) async {
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
      300,
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
}
