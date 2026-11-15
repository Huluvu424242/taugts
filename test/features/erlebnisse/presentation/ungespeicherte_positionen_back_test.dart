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
  testWidgets(
    'Zurück nach Übernahme eines neuen Produkts fragt vor dem Verwerfen nach',
    (tester) async {
      final zeit = DateTime.utc(2026, 11, 15, 18);
      final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
      addTearDown(datenbank.schliessen);
      final repository = SqliteBewertungsRepository(datenbank);
      final profil = Profil(
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        erstelltAm: zeit,
        geaendertAm: zeit,
      );
      datenbank.verbindung.execute(
        'INSERT INTO profile VALUES (?, NULL, ?, ?)',
        [profil.id, zeit.toIso8601String(), zeit.toIso8601String()],
      );
      final erlebnis = Erlebnis(
        id: '71000000-0000-4000-8000-000000000001',
        typ: Erlebnistyp.einkauf,
        herkunftProfilId: profil.id,
        notiz: 'Bereits gespeichert',
        erstelltAm: zeit,
        geaendertAm: zeit,
      );
      await repository.speichereErlebnis(erlebnis);
      await repository.speichereProdukt(
        Produkt(
          id: '72000000-0000-4000-8000-000000000001',
          name: 'Regressionstest-Produkt',
          erstelltAm: zeit,
          geaendertAm: zeit,
        ),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ErlebnisScreen(
                    repository: repository,
                    idGenerator: _TestIdGenerator(),
                    profil: profil,
                    erlebnis: erlebnis,
                  ),
                ),
              ),
              child: const Text('Erlebnis öffnen'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Erlebnis öffnen'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Produkt hinzufügen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Produkt auswählen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Regressionstest-Produkt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Position übernehmen'));
      await tester.pumpAndSettle();

      expect(find.text('Regressionstest-Produkt'), findsWidgets);
      expect(await repository.ladeErlebnispositionen(erlebnis.id), isEmpty,
          reason: 'Die Position darf vor dem allgemeinen Speichern nur im Entwurf liegen.');

      // Android-System-Zurück statt des allgemeinen Speichern-Buttons.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Sollverhalten: Der Entwurf bleibt geöffnet, bis das Verwerfen
      // ausdrücklich bestätigt wurde. Dieser Test ist vor dem Bugfix rot.
      expect(find.byType(AlertDialog), findsOneWidget,
          reason: 'Ungespeicherte Erlebnispositionen erfordern eine Rückfrage.');
      expect(find.byType(ErlebnisScreen), findsOneWidget);
      expect(await repository.ladeErlebnispositionen(erlebnis.id), isEmpty);
    },
  );
}

class _TestIdGenerator implements IdGenerator {
  var _wert = 0;

  @override
  String neueId() {
    _wert++;
    return '73000000-0000-4000-8000-${_wert.toString().padLeft(12, '0')}';
  }
}
