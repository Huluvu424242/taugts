import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/erlebnisse/presentation/erlebnisposition_formular.dart';

void main() {
  testWidgets(
    'bearbeitet Produkt zentral und erhält ungespeicherte Positionsdaten',
    (tester) async {
      final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
      addTearDown(datenbank.schliessen);
      final repository = SqliteBewertungsRepository(datenbank);
      final zeit = DateTime.utc(2026, 10, 7);
      final produkt = Produkt(
        id: '21900000-0000-4000-8000-000000000001',
        name: 'Altes Pils',
        erstelltAm: zeit,
        geaendertAm: zeit,
      );
      await repository.speichereProdukt(produkt);
      final erlebnis = Erlebnis(
        id: '21900000-0000-4000-8000-000000000002',
        herkunftProfilId: '21900000-0000-4000-8000-000000000009',
        erstelltAm: zeit,
        geaendertAm: zeit,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ErlebnispositionFormular(
            repository: repository,
            idGenerator: _TestIdGenerator(),
            erlebnis: erlebnis,
            produktVorgabe: produkt,
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('positions-anzahl')),
        '3',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Preis (optional)'),
        '4,20',
      );

      await tester.tap(find.text('Produkt bearbeiten'));
      await tester.pumpAndSettle();
      expect(find.text('Produkt bearbeiten'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Neues Pils',
      );
      await tester.ensureVisible(find.text('Produkt speichern'));
      await tester.tap(find.text('Produkt speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Neues Pils'), findsOneWidget);
      expect(
        tester.widget<TextField>(
          find.byKey(const ValueKey('positions-anzahl')),
        ).controller?.text,
        '3',
      );
      expect(
        tester.widget<TextField>(
          find.widgetWithText(TextField, 'Preis (optional)'),
        ).controller?.text,
        '4,20',
      );
    },
  );

  testWidgets('Abbruch der Produktbearbeitung lässt Auswahl unverändert',
      (tester) async {
    final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(datenbank.schliessen);
    final repository = SqliteBewertungsRepository(datenbank);
    final zeit = DateTime.utc(2026, 10, 7);
    final produkt = Produkt(
      id: '21900000-0000-4000-8000-000000000003',
      name: 'Bleibt Pils',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereProdukt(produkt);

    await tester.pumpWidget(
      MaterialApp(
        home: ErlebnispositionFormular(
          repository: repository,
          idGenerator: _TestIdGenerator(),
          erlebnis: Erlebnis(
            id: '21900000-0000-4000-8000-000000000004',
            herkunftProfilId: '21900000-0000-4000-8000-000000000009',
            erstelltAm: zeit,
            geaendertAm: zeit,
          ),
          produktVorgabe: produkt,
        ),
      ),
    );

    await tester.tap(find.text('Produkt bearbeiten'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Nicht gespeichert',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Bleibt Pils'), findsOneWidget);
    expect(find.text('Nicht gespeichert'), findsNothing);
  });
}

class _TestIdGenerator implements IdGenerator {
  var _wert = 10;

  @override
  String neueId() {
    _wert++;
    return '21900000-0000-4000-8000-0000000000$_wert';
  }
}
