import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/erlebnisse/presentation/erlebnis_screen.dart';
import 'package:taugts/features/profil/models/profil.dart';

void main() {
  late LokaleDatenbank datenbank;
  late SqliteBewertungsRepository repository;
  late Profil profil;
  final zeit = DateTime.utc(2026, 9, 1, 18);

  setUp(() async {
    profil = Profil(
      id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    datenbank.verbindung.execute(
      'INSERT INTO profile VALUES (?, NULL, ?, ?)',
      [profil.id, zeit.toIso8601String(), zeit.toIso8601String()],
    );
    repository = SqliteBewertungsRepository(datenbank);

    final produkt = Produkt(
      id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      name: 'Pils',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    final erlebnis = Erlebnis(
      id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      typ: Erlebnistyp.restaurantbesuch,
      status: Erlebnisstatus.geplant,
      herkunftProfilId: profil.id,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereProdukt(produkt);
    await repository.speichereErlebnis(erlebnis);
    await repository.speichereErlebnisposition(
      position: ErlebnisPosition(
        id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        erlebnisId: erlebnis.id,
        produktId: produkt.id,
        anzahl: 1,
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
    );
  });

  tearDown(() => datenbank.schliessen());

  testWidgets('Restaurantbesuch führt Bestellung mit direkter Mengenänderung',
      (tester) async {
    final erlebnis = (await repository.ladeErlebnisse()).single;
    await tester.pumpWidget(
      MaterialApp(
        home: ErlebnisScreen(
          repository: repository,
          idGenerator: _TestIdGenerator(),
          profil: profil,
          erlebnis: erlebnis,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Bestellung'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Bestellung'), findsOneWidget);
    expect(find.text('Produkt hinzufügen'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Pils'),
      200,
      scrollable: scrollable,
    );
    expect(find.text('Pils'), findsOneWidget);
    expect(find.text('Noch nicht bewertet'), findsOneWidget);
    expect(find.text('1 × Pils'), findsOneWidget);
    expect(find.byTooltip('Pils bewerten'), findsOneWidget);

    await tester.tap(find.byTooltip('Pils Anzahl erhöhen, aktuell 1'));
    await tester.pumpAndSettle();

    final positionen = await repository.ladeErlebnispositionen(erlebnis.id);
    expect(positionen.single.position.anzahl, 2);
    expect(find.text('2 × Pils'), findsOneWidget);
    expect(find.byTooltip('Pils Anzahl verringern, aktuell 2'), findsOneWidget);
  });

  testWidgets('Restaurantbesuch verwendet Check-in und Checkout',
      (tester) async {
    final erlebnis = (await repository.ladeErlebnisse()).single;
    await tester.pumpWidget(
      MaterialApp(
        home: ErlebnisScreen(
          repository: repository,
          idGenerator: _TestIdGenerator(),
          profil: profil,
          erlebnis: erlebnis,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Check-in'), findsOneWidget);
    await tester.tap(find.text('Check-in'));
    await tester.pumpAndSettle();
    expect(find.text('Checkout'), findsOneWidget);
    expect(find.textContaining('Aktiv seit'), findsOneWidget);
  });
}

class _TestIdGenerator implements IdGenerator {
  var _wert = 0;

  @override
  String neueId() {
    _wert++;
    return 'eeeeeeee-eeee-4eee-8eee-${_wert.toString().padLeft(12, '0')}';
  }
}
