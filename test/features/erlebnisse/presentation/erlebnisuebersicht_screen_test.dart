import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/erlebnisse/presentation/entwuerfe_screen.dart';
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

  testWidgets('Leerzustand erklärt Restaurantbesuch und Einkauf',
      (tester) async {
    await tester.pumpWidget(_app(repository, profil));
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Erlebnisse'), findsOneWidget);
    expect(
        find.textContaining('Restaurantbesuch oder Einkauf'), findsOneWidget);
    expect(find.text('Erlebnis registrieren'), findsWidgets);
  });

  testWidgets('Erlebnisse werden nach Status gruppiert', (tester) async {
    await repository.speichereErlebnis(
      Erlebnis(
        id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        typ: Erlebnistyp.restaurantbesuch,
        status: Erlebnisstatus.aktiv,
        herkunftProfilId: profil.id,
        tatsaechlicherBeginn: zeit,
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
    );
    await repository.speichereErlebnis(
      Erlebnis(
        id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        typ: Erlebnistyp.einkauf,
        status: Erlebnisstatus.geplant,
        herkunftProfilId: profil.id,
        geplanterTag: DateTime.utc(2026, 9, 2),
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
    );
    await repository.speichereErlebnis(
      Erlebnis(
        id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        typ: Erlebnistyp.einkauf,
        status: Erlebnisstatus.beendet,
        herkunftProfilId: profil.id,
        tatsaechlicherBeginn: zeit.subtract(const Duration(hours: 2)),
        tatsaechlichesEnde: zeit.subtract(const Duration(hours: 1)),
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
    );

    await tester.pumpWidget(_app(repository, profil));
    await tester.pumpAndSettle();

    expect(find.text('Aktiv'), findsOneWidget);
    expect(find.text('Geplant'), findsOneWidget);
    expect(find.text('Vergangen'), findsOneWidget);
    expect(find.textContaining('Termin noch offen'), findsNothing);
    expect(find.textContaining('Positionen'), findsNWidgets(3));
  });
}

Widget _app(SqliteBewertungsRepository repository, Profil profil) =>
    MaterialApp(
      home: EntwuerfeScreen(
        repository: repository,
        idGenerator: _TestIdGenerator(),
        profil: profil,
      ),
    );

class _TestIdGenerator implements IdGenerator {
  var _index = 0;

  @override
  String neueId() {
    _index++;
    return 'eeeeeeee-eeee-4eee-8eee-${_index.toString().padLeft(12, '0')}';
  }
}
