import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/erlebnisse/presentation/entwuerfe_screen.dart';
import 'package:taugts/features/erlebnisse/presentation/erlebnis_screen.dart';
import 'package:taugts/features/profil/models/profil.dart';

void main() {
  late LokaleDatenbank datenbank;
  late SqliteBewertungsRepository repository;
  late Profil profil;
  final zeit = DateTime.utc(2026, 8, 30, 18);

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

  testWidgets('registriert Restaurantbesuch oder Einkauf', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EntwuerfeScreen(
          repository: repository,
          idGenerator: _TestIdGenerator(),
          profil: profil,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Restaurantbesuch'), findsOneWidget);
    expect(find.text('Einkauf'), findsOneWidget);

    await tester.tap(find.text('Einkauf'));
    await tester.pumpAndSettle();
    expect(find.text('Status: Geplant'), findsOneWidget);
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    final erlebnisse = await repository.ladeErlebnisse();
    expect(erlebnisse, hasLength(1));
    expect(erlebnisse.single.typ, Erlebnistyp.einkauf);
    expect(erlebnisse.single.geplanteMinute, isNull);
  });

  testWidgets('Check-in und Checkout setzen editierbare Zeiten', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ErlebnisScreen(
          repository: repository,
          idGenerator: _TestIdGenerator(),
          profil: profil,
          erlebnistyp: Erlebnistyp.restaurantbesuch,
        ),
      ),
    );

    await tester.tap(find.text('Check-in'));
    await tester.pumpAndSettle();
    expect(find.text('Status: Aktiv'), findsOneWidget);
    expect(find.text('Checkout'), findsOneWidget);

    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();
    expect(find.text('Status: Beendet'), findsOneWidget);
    expect(find.text('Bearbeiten speichern'), findsOneWidget);

    final erlebnis = (await repository.ladeErlebnisse()).single;
    expect(erlebnis.status, Erlebnisstatus.beendet);
    expect(erlebnis.tatsaechlicherBeginn, isNotNull);
    expect(erlebnis.tatsaechlichesEnde, isNotNull);
  });

  testWidgets('zeigt ungültige Dauer am Feld und im Fehlersammler', (
    tester,
  ) async {
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

    await tester.enterText(
      find.widgetWithText(
        TextField,
        'Geplante Dauer in Minuten (optional)',
      ),
      '-5',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Bitte Zeitangaben prüfen.'), findsOneWidget);
    expect(
      find.text('Die geplante Dauer muss größer als null sein.'),
      findsOneWidget,
    );
    expect(await repository.ladeErlebnisse(), isEmpty);
  });
}

class _TestIdGenerator implements IdGenerator {
  var _wert = 0;

  @override
  String neueId() {
    _wert++;
    return '70000000-0000-4000-8000-00000000000$_wert';
  }
}
