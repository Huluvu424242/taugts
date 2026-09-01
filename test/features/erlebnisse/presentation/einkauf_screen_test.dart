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
  final zeit = DateTime.utc(2026, 9, 1, 10);

  setUp(() {
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
  });

  tearDown(() => datenbank.schliessen());

  testWidgets('Einkauf kann ohne Termin geplant und begonnen werden',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ErlebnisScreen(
          repository: repository,
          idGenerator: _TestIdGenerator(),
          profil: profil,
          erlebnistyp: Erlebnistyp.einkauf,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Einkaufsliste'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Einkaufsliste'), findsOneWidget);
    expect(find.text('Einkauf beginnen'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('ohne Termin'),
      100,
      scrollable: scrollable,
    );
    expect(find.textContaining('ohne Termin'), findsOneWidget);

    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    final gespeichert = (await repository.ladeErlebnisse()).single;
    expect(gespeichert.geplanterTag, isNull);
    expect(gespeichert.geplanteMinute, isNull);
    expect(gespeichert.tatsaechlicherBeginn, isNull);
  });

  testWidgets('Einkauf summiert nur erfasste Preise und ändert Mengen',
      (tester) async {
    final erlebnis = Erlebnis(
      id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      typ: Erlebnistyp.einkauf,
      herkunftProfilId: profil.id,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    final milch = Produkt(
      id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      name: 'Milch',
      produktart: Produktart.sonstiges,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    final brot = Produkt(
      id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
      name: 'Brot',
      produktart: Produktart.speise,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereErlebnis(erlebnis);
    await repository.speichereProdukt(milch);
    await repository.speichereProdukt(brot);
    await repository.speichereErlebnisposition(
      position: ErlebnisPosition(
        id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
        erlebnisId: erlebnis.id,
        produktId: milch.id,
        anzahl: 2,
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
      preis: Preisbeobachtung(
        id: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
        erlebnisId: erlebnis.id,
        erlebnisPositionId: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
        produktId: milch.id,
        betrag: const Geldbetrag(minorEinheiten: 139),
        beobachtetAm: zeit,
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
    );
    await repository.speichereErlebnisposition(
      position: ErlebnisPosition(
        id: '11111111-1111-4111-8111-111111111111',
        erlebnisId: erlebnis.id,
        produktId: brot.id,
        anzahl: 1,
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
    );

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
      find.byTooltip('Milch bewerten'),
      300,
      scrollable: scrollable,
    );
    expect(find.byTooltip('Milch bewerten'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('einkaufssumme')),
      300,
      scrollable: scrollable,
    );
    expect(find.text('2,78 EUR'), findsOneWidget);
    expect(
      find.text('1 Position(en) ohne Preis; nicht als 0 eingerechnet.'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byTooltip('Brot Anzahl erhöhen, aktuell 1'),
      -200,
      scrollable: scrollable,
    );
    await tester.tap(find.byTooltip('Brot Anzahl erhöhen, aktuell 1'));
    await tester.pumpAndSettle();
    final positionen = await repository.ladeErlebnispositionen(erlebnis.id);
    expect(
      positionen.singleWhere((e) => e.produkt.name == 'Brot').position.anzahl,
      2,
    );
  });

  testWidgets('Einkauf beginnen und beenden setzt tatsächliche Zeiten',
      (tester) async {
    final erlebnis = Erlebnis(
      id: '22222222-2222-4222-8222-222222222222',
      typ: Erlebnistyp.einkauf,
      herkunftProfilId: profil.id,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereErlebnis(erlebnis);
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

    await tester.tap(find.text('Einkauf beginnen'));
    await tester.pumpAndSettle();
    expect(find.text('Einkauf beenden'), findsOneWidget);
    expect(find.textContaining('Einkauf läuft seit'), findsOneWidget);

    await tester.tap(find.text('Einkauf beenden'));
    await tester.pumpAndSettle();
    expect(find.text('Status: Beendet'), findsOneWidget);
    final beendet = await repository.ladeErlebnis(erlebnis.id);
    expect(beendet!.tatsaechlicherBeginn, isNotNull);
    expect(beendet.tatsaechlichesEnde, isNotNull);
  });
}

class _TestIdGenerator implements IdGenerator {
  var _wert = 0;

  @override
  String neueId() {
    _wert++;
    return '33333333-3333-4333-8333-${_wert.toString().padLeft(12, '0')}';
  }
}
