import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/produkte/presentation/produkte_screen.dart';

class _FesterIdGenerator implements IdGenerator {
  @override
  String neueId() => '55e34e0e-fb72-450d-9db7-20d42188d238';
}

void main() {
  testWidgets('filtert Produkte und zeigt einen zugänglichen Leerzustand', (
    tester,
  ) async {
    final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(datenbank.schliessen);
    final repository = SqliteBewertungsRepository(datenbank);
    final zeit = DateTime.utc(2026, 8, 29);
    await repository.speichereProdukt(Produkt(
      id: '55e34e0e-fb72-450d-9db7-20d42188d239',
      name: 'Sonnenpils',
      erstelltAm: zeit,
      geaendertAm: zeit,
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: ProdukteScreen(
          repository: repository,
          idGenerator: _FesterIdGenerator(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sonnenpils'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Apfelsaft');
    await tester.pumpAndSettle();

    expect(find.text('Keine passenden Produkte gefunden.'), findsOneWidget);
    expect(find.text('Produkt anlegen'), findsWidgets);
  });
}
