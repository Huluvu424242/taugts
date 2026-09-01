import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/produkte/presentation/produkt_erneut_bewerten_screen.dart';
import 'package:taugts/features/profil/services/sqlite_profil_repository.dart';

class _FesterIdGenerator implements IdGenerator {
  var _index = 0;

  @override
  String neueId() => 'story29-${_index++}';
}

void main() {
  testWidgets(
      'verwendet ein bekanntes Produkt als Position und öffnet den zentralen Bewertungsbogen',
      (tester) async {
    final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(datenbank.schliessen);
    final idGenerator = _FesterIdGenerator();
    final profilRepository = SqliteProfilRepository(
      datenbank,
      idGenerator: idGenerator,
    );
    final profil = await profilRepository.ladeOderErstelleProfil();
    final repository = SqliteBewertungsRepository(datenbank);
    final zeit = DateTime.utc(2026, 9, 1, 12);
    final produkt = Produkt(
      id: 'produkt-1',
      name: 'Testbier',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereProdukt(produkt);
    final erlebnis = Erlebnis(
      id: 'erlebnis-1',
      typ: Erlebnistyp.einkauf,
      status: Erlebnisstatus.geplant,
      geplanterTag: DateTime.utc(2026, 9, 1),
      geplanteMinute: 12 * 60,
      herkunftProfilId: profil.id,
      istEntwurf: true,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereErlebnis(erlebnis);

    await tester.pumpWidget(
      MaterialApp(
        home: ProduktErneutBewertenScreen(
          repository: repository,
          idGenerator: idGenerator,
          profil: profil,
          produkt: produkt,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Testbier'), findsOneWidget);
    await tester.tap(find.text('Einkauf'));
    await tester.pumpAndSettle();

    expect(find.text('Erlebnisposition hinzufügen'), findsOneWidget);
    expect(find.text('Testbier'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), '2,50');
    await tester.tap(find.text('Position speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Testbier bewerten'), findsOneWidget);
    expect((await repository.ladeProdukte()).length, 1);
    expect((await repository.ladeErlebnispositionen(erlebnis.id)).length, 1);
  });
}
