import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/datenaustausch/services/import_alias_repository.dart';
import 'package:taugts/features/datenaustausch/services/import_ausfuehrung_service.dart';
import 'package:taugts/features/datenaustausch/services/import_strategie_service.dart';

class _ReentrantAliasRepository extends ImportAliasRepository {
  late ImportAusfuehrungService service;
  var zweiterAufrufVersucht = false;

  @override
  void stelleTabelleBereit(LokaleDatenbank datenbank) {
    super.stelleTabelleBereit(datenbank);
    if (zweiterAufrufVersucht) return;
    zweiterAufrufVersucht = true;
    expect(
      () => service.ausfuehren(
        datenbank: datenbank,
        importDokument: const {},
        strategie: ImportStrategie.importBevorzugen,
      ),
      throwsA(
        isA<StateError>().having(
          (fehler) => fehler.message,
          'message',
          contains('läuft bereits ein Import'),
        ),
      ),
    );
  }
}

void main() {
  test('Service verhindert zweite Ausführung für dieselbe Datenbank', () {
    final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(datenbank.schliessen);
    final aliasRepository = _ReentrantAliasRepository();
    final service = ImportAusfuehrungService(aliasRepository: aliasRepository);
    aliasRepository.service = service;

    final ergebnis = service.ausfuehren(
      datenbank: datenbank,
      importDokument: const {},
      strategie: ImportStrategie.importBevorzugen,
    );

    expect(aliasRepository.zweiterAufrufVersucht, isTrue);
    expect(ergebnis.gesamt.hinzugefuegt, 0);
  });

  test('Sperre wird nach einem fehlgeschlagenen Import wieder freigegeben', () {
    final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(datenbank.schliessen);
    const service = ImportAusfuehrungService();

    expect(
      () => service.ausfuehren(
        datenbank: datenbank,
        importDokument: const {
          'objekte': [
            {'id': ''},
          ],
        },
        strategie: ImportStrategie.importBevorzugen,
      ),
      throwsFormatException,
    );

    expect(
      () => service.ausfuehren(
        datenbank: datenbank,
        importDokument: const {},
        strategie: ImportStrategie.importBevorzugen,
      ),
      returnsNormally,
    );
  });
}
