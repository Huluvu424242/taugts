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
      'Scan aktualisiert genau die Position und erhält Anzahl und Preis',
      (tester) async {
    final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(datenbank.schliessen);
    final repository = SqliteBewertungsRepository(datenbank);
    final zeit = DateTime.utc(2026, 8, 31);
    const profilId = '61000000-0000-4000-8000-000000000000';
    datenbank.verbindung.execute(
      'INSERT INTO profile VALUES (?, NULL, ?, ?)',
      [profilId, zeit.toIso8601String(), zeit.toIso8601String()],
    );
    final erlebnis = Erlebnis(
      id: '61000000-0000-4000-8000-000000000001',
      herkunftProfilId: profilId,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    final altesProdukt = Produkt(
      id: '61000000-0000-4000-8000-000000000002',
      name: 'Altes Produkt',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    final scanProdukt = Produkt(
      id: '61000000-0000-4000-8000-000000000003',
      name: 'Scan-Produkt',
      barcode: '4012345678901',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereErlebnis(erlebnis);
    await repository.speichereProdukt(altesProdukt);
    await repository.speichereProdukt(scanProdukt);
    final vorhandenePosition = ErlebnisPosition(
      id: '61000000-0000-4000-8000-000000000004',
      erlebnisId: erlebnis.id,
      produktId: altesProdukt.id,
      anzahl: 2,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereErlebnisposition(position: vorhandenePosition);

    await tester.pumpWidget(MaterialApp(
      home: ErlebnispositionFormular(
        repository: repository,
        idGenerator: _FortlaufenderIdGenerator(),
        erlebnis: erlebnis,
        vorhanden: ErlebnispositionMitProdukt(
          position: vorhandenePosition,
          produkt: altesProdukt,
        ),
        barcodeScanStart: (_) async => '4012345678901',
      ),
    ));
    await tester.enterText(
      find.byKey(const ValueKey('positions-anzahl')),
      '3',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Preis (optional)'),
      '4,20',
    );
    await tester.tap(find.text('Altes Produkt'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Barcode scannen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Produkt verwenden'));
    await tester.pumpAndSettle();

    expect(find.text('Scan-Produkt'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('positions-anzahl')),
          )
          .controller
          ?.text,
      '3',
    );
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Preis (optional)'))
          .controller
          ?.text,
      '4,20',
    );
    await tester.tap(find.text('Position speichern'));
    await tester.pumpAndSettle();

    final positionen = await repository.ladeErlebnispositionen(erlebnis.id);
    expect(positionen, hasLength(1));
    expect(positionen.single.position.id, vorhandenePosition.id);
    expect(positionen.single.position.produktId, scanProdukt.id);
    expect(positionen.single.position.anzahl, 3);
    expect(positionen.single.preis?.betrag.minorEinheiten, 420);
  });
}

class _FortlaufenderIdGenerator implements IdGenerator {
  var _index = 10;

  @override
  String neueId() =>
      '61000000-0000-4000-8000-${(_index++).toString().padLeft(12, '0')}';
}
