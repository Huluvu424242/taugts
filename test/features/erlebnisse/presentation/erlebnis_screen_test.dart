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

    // Ein inhaltsleeres neues Erlebnis darf nicht persistiert werden.
    expect(await repository.ladeErlebnisse(), isEmpty);
    expect(
      find.textContaining('Bitte einen Ort mit Besuchszeit'),
      findsOneWidget,
    );

    // Eine Notiz ist als eigenständiger Inhalt ausreichend.
    await tester.enterText(
      find.widgetWithText(TextField, 'Notiz (optional)').first,
      'Einkauf vorbereiten',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    final erlebnisse = await repository.ladeErlebnisse();
    expect(erlebnisse, hasLength(1));
    expect(erlebnisse.single.typ, Erlebnistyp.einkauf);
    expect(erlebnisse.single.geplanteMinute, isNull);
  });

  for (final fall in [
    (typ: Erlebnistyp.restaurantbesuch, ortstyp: Ortstyp.gastronomie),
    (typ: Erlebnistyp.einkauf, ortstyp: Ortstyp.geschaeft),
  ]) {
    testWidgets(
      'Spontaner ${fall.typ.name} ohne Produkte und Bewertung bleibt erhalten',
      (tester) async {
        final ort = Ort(
          id: '79000000-0000-4000-8000-000000000001',
          name: 'Spontaner Testort',
          typ: fall.ortstyp,
          erstelltAm: zeit,
          geaendertAm: zeit,
        );
        await repository.speichereOrt(ort);
        await tester.pumpWidget(
          MaterialApp(
            home: ErlebnisScreen(
              repository: repository,
              idGenerator: _TestIdGenerator(),
              profil: profil,
              erlebnistyp: fall.typ,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('auswählen (optional)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Spontaner Testort'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Spontanen Besuch jetzt erfassen'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Spontanen Besuch jetzt erfassen'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Speichern'));
        await tester.pumpAndSettle();

        final erlebnisse = await repository.ladeErlebnisse();
        expect(erlebnisse, hasLength(1));
        final erlebnis = erlebnisse.single;
        expect(erlebnis.ortId, ort.id);
        expect(erlebnis.tatsaechlicherBeginn, isNotNull);
        expect(erlebnis.geplanterTag, isNull);
        expect(await repository.ladeErlebnispositionen(erlebnis.id), isEmpty);
        expect(
          await repository.ladeOrtsbewertungFuerErlebnis(erlebnis.id),
          isNull,
        );

        // Wiederöffnen ohne die erfasste Besuchszeit zu verlieren.
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
        expect(find.text('Spontaner Testort'), findsOneWidget);
        expect(
          (await repository.ladeErlebnisse()).single.tatsaechlicherBeginn,
          erlebnis.tatsaechlicherBeginn,
        );

        // Die Ortsbewertung darf erst im Nachgang ergänzt werden.
        final abschnitt = fall.typ == Erlebnistyp.einkauf
            ? 'Geschäft bewerten'
            : 'Gaststätte bewerten';
        await tester.scrollUntilVisible(
          find.text(abschnitt),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text(abschnitt));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.widgetWithText(TextField, 'Notiz (optional)').last,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Notiz (optional)').last,
          'Interessanter Ort für später',
        );
        await tester.tap(find.text('Speichern'));
        await tester.pumpAndSettle();
        final bewertung =
            await repository.ladeOrtsbewertungFuerErlebnis(erlebnis.id);
        expect(bewertung?.ortsbewertung.notiz, 'Interessanter Ort für später');
        expect(bewertung?.ortsbewertung.ortId, ort.id);
        expect(await repository.ladeErlebnispositionen(erlebnis.id), isEmpty);
      },
    );
  }

  testWidgets('Ein Ort allein ist noch kein dokumentierter Besuch',
      (tester) async {
    final ort = Ort(
      id: '79000000-0000-4000-8000-000000000002',
      name: 'Nur Ort',
      typ: Ortstyp.geschaeft,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereOrt(ort);
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
    await tester.tap(find.textContaining('auswählen (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nur Ort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(await repository.ladeErlebnisse(), isEmpty);
  });

  testWidgets('Check-in und Checkout setzen editierbare Zeiten',
      (tester) async {
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

  testWidgets('Gaststättenbewertung bleibt beim Ein- und Ausklappen erhalten',
      (tester) async {
    final ort = Ort(
      id: '75000000-0000-4000-8000-000000000001',
      name: 'Testgaststätte',
      typ: Ortstyp.gastronomie,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    final erlebnis = Erlebnis(
      id: '76000000-0000-4000-8000-000000000001',
      ortId: ort.id,
      herkunftProfilId: profil.id,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereOrt(ort);
    await repository.speichereErlebnis(erlebnis);
    await tester.pumpWidget(MaterialApp(
      home: ErlebnisScreen(
        repository: repository,
        idGenerator: _TestIdGenerator(),
        profil: profil,
        erlebnis: erlebnis,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Gaststätte bewerten'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Gaststätte bewerten'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(DropdownButtonFormField<double?>).first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(DropdownButtonFormField<double?>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 – taugt sehr').last);
    await tester.pumpAndSettle();

    final expansionTile = find.byType(ExpansionTile);
    await tester.ensureVisible(expansionTile);
    await tester.pumpAndSettle();
    await tester.tap(expansionTile);
    await tester.pumpAndSettle();
    await tester.ensureVisible(expansionTile);
    await tester.pumpAndSettle();
    await tester.tap(expansionTile);
    await tester.pumpAndSettle();
    expect(find.text('5 – taugt sehr'), findsOneWidget);
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
