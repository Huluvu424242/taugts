import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/presentation/kriterien_screen.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';

void main() {
  late LokaleDatenbank datenbank;
  late SqliteBewertungsRepository repository;

  setUp(() {
    datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    repository = SqliteBewertungsRepository(datenbank);
  });

  tearDown(() => datenbank.schliessen());

  testWidgets('zeigt Lade- und Leerzustand auch mit großer Schrift',
      (tester) async {
    final gesteuert = _GesteuertesLadenRepository(datenbank);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: KriterienScreen(
          repository: gesteuert,
          idGenerator: _FesterIdGenerator(),
        ),
      ),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gesteuert.laden.complete([]);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Keine Kriterien für diese Objektart.',
        skipOffstage: false,
      ),
      findsNWidgets(KriteriumObjektart.values.length),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('zeigt einen verständlichen Ladefehler mit Wiederholung',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: KriterienScreen(
        repository: _LadefehlerRepository(datenbank),
        idGenerator: _FesterIdGenerator(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
      find.text('Die Bewertungskriterien konnten nicht geladen werden.'),
      findsOneWidget,
    );
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });

  testWidgets('validiert Auswahlkriterien und speichert sie', (tester) async {
    await _pumpScreen(tester, repository);
    await tester.tap(find.text('Kriterium anlegen'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wertung').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auswahl').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Name ist erforderlich.'), findsNWidgets(2));
    expect(
      find.text('Mindestens ein Auswahlwert ist erforderlich.'),
      findsNWidgets(2),
    );
    expect(find.text('Bitte Eingaben prüfen.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Name (Pflichtfeld)'),
      'Schaumart',
    );
    await tester.enterText(
      find.widgetWithText(
        TextField,
        'Auswahlwerte (eine Zeile je Wert)',
      ),
      'Fein\nGrob',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Kriterium wurde angelegt.'), findsOneWidget);
    final gespeichert = (await repository.ladeKriterien())
        .singleWhere((wert) => wert.name == 'Schaumart');
    expect(gespeichert.eingabetyp, KriteriumEingabetyp.auswahl);
    expect(gespeichert.auswahlwerte, ['Fein', 'Grob']);
  });

  testWidgets('löscht ein unbenutztes Kriterium nach Bestätigung',
      (tester) async {
    const id = '9ef4ace9-f038-40d4-a042-042eac68ca50';
    final zeit = DateTime.utc(2026, 8, 31);
    await repository.speichereKriterium(Bewertungskriterium(
      id: id,
      name: 'Temporär',
      erstelltAm: zeit,
      geaendertAm: zeit,
    ));
    await _pumpScreen(tester, repository);

    await tester.tap(find.byTooltip('Temporär – Aktionen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entfernen'));
    await tester.pumpAndSettle();
    expect(find.text('Kriterium entfernen?'), findsOneWidget);
    await tester.tap(find.text('Entfernen'));
    await tester.pumpAndSettle();

    expect(find.text('Das unbenutzte Kriterium wurde gelöscht.'), findsOneWidget);
    expect(
      (await repository.ladeKriterien()).any((wert) => wert.id == id),
      isFalse,
    );
  });

  testWidgets('behält Eingaben bei einem Persistenzfehler', (tester) async {
    await _pumpScreen(tester, _SpeicherfehlerRepository(datenbank));
    await tester.tap(find.text('Kriterium anlegen'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Name (Pflichtfeld)'),
      'Bleibt erhalten',
    );

    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(
      find.text('Das Kriterium konnte nicht gespeichert werden.'),
      findsOneWidget,
    );
    expect(find.text('Bleibt erhalten'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Kriterium anlegen'),
      ),
      findsOneWidget,
    );
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  SqliteBewertungsRepository repository,
) async {
  await tester.pumpWidget(MaterialApp(
    home: KriterienScreen(
      repository: repository,
      idGenerator: _FesterIdGenerator(),
    ),
  ));
  await tester.pumpAndSettle();
}

class _FesterIdGenerator implements IdGenerator {
  @override
  String neueId() => '9ef4ace9-f038-40d4-a042-042eac68ca51';
}

class _GesteuertesLadenRepository extends SqliteBewertungsRepository {
  _GesteuertesLadenRepository(super.datenbank);

  final laden = Completer<List<Bewertungskriterium>>();

  @override
  Future<List<Bewertungskriterium>> ladeKriterien({bool nurAktive = false}) =>
      laden.future;
}

class _LadefehlerRepository extends SqliteBewertungsRepository {
  _LadefehlerRepository(super.datenbank);

  @override
  Future<List<Bewertungskriterium>> ladeKriterien({bool nurAktive = false}) =>
      Future.error(StateError('Testfehler'));
}

class _SpeicherfehlerRepository extends SqliteBewertungsRepository {
  _SpeicherfehlerRepository(super.datenbank);

  @override
  Future<void> speichereKriterium(Bewertungskriterium kriterium) =>
      Future.error(StateError('Testfehler'));
}
