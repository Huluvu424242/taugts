import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/datenaustausch/services/import_alias_repository.dart';
import 'package:taugts/features/datenaustausch/services/import_ausfuehrung_service.dart';
import 'package:taugts/features/datenaustausch/services/import_dubletten_merge_service.dart';
import 'package:taugts/features/datenaustausch/services/import_strategie_service.dart';

void main() {
  const repository = ImportAliasRepository();

  test('Alias bleibt nach erneutem Öffnen der Datenbank erhalten', () async {
    final temp = await Directory.systemTemp.createTemp('taugts-alias-test-');
    final pfad = '${temp.path}/taugts.sqlite';
    try {
      var datenbank = LokaleDatenbank.oeffnen(sqlite3.open(pfad));
      repository.speichere(
        datenbank,
        const ImportAliasReferenz(
          sammlung: 'objekte',
          aliasId: 'produkt-alt',
          kanonischeId: 'produkt-neu',
        ),
        erstelltAm: DateTime.utc(2026, 9, 2),
      );
      datenbank.schliessen();

      datenbank = LokaleDatenbank.oeffnen(sqlite3.open(pfad));
      final aliases = repository.lade(datenbank);
      expect(aliases, hasLength(1));
      expect(aliases.single.aliasId, 'produkt-alt');
      expect(aliases.single.kanonischeId, 'produkt-neu');
      datenbank.schliessen();
    } finally {
      await temp.delete(recursive: true);
    }
  });

  test('bekannter Produktalias normalisiert Stammdaten und Historienbezüge', () {
    final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(datenbank.schliessen);
    repository.speichere(
      datenbank,
      const ImportAliasReferenz(
        sammlung: 'objekte',
        aliasId: 'produkt-alt',
        kanonischeId: 'produkt-neu',
      ),
    );

    final normalisiert = repository.normalisiereDokument(datenbank, {
      'objekte': [
        {'id': 'produkt-alt', 'name': 'Pils'},
      ],
      'erlebnisPositionen': [
        {'id': 'pos-1', 'produktId': 'produkt-alt'},
      ],
      'preisbeobachtungen': [
        {'id': 'preis-1', 'produktId': 'produkt-alt'},
      ],
      'bewertungen': [
        {'id': 'bew-1', 'objektId': 'produkt-alt'},
      ],
    });

    expect(((normalisiert['objekte'] as List).single as Map)['id'], 'produkt-neu');
    expect(
      ((normalisiert['erlebnisPositionen'] as List).single as Map)['produktId'],
      'produkt-neu',
    );
    expect(
      ((normalisiert['preisbeobachtungen'] as List).single as Map)['produktId'],
      'produkt-neu',
    );
    expect(
      ((normalisiert['bewertungen'] as List).single as Map)['objektId'],
      'produkt-neu',
    );
  });

  test('widersprüchliche Aliaszuordnung und Aliaszyklus werden verhindert', () {
    final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(datenbank.schliessen);
    repository.speichere(
      datenbank,
      const ImportAliasReferenz(
        sammlung: 'objekte',
        aliasId: 'a',
        kanonischeId: 'b',
      ),
    );

    expect(
      () => repository.speichere(
        datenbank,
        const ImportAliasReferenz(
          sammlung: 'objekte',
          aliasId: 'a',
          kanonischeId: 'c',
        ),
      ),
      throwsStateError,
    );
    expect(
      () => repository.speichere(
        datenbank,
        const ImportAliasReferenz(
          sammlung: 'objekte',
          aliasId: 'b',
          kanonischeId: 'a',
        ),
      ),
      throwsStateError,
    );
  });

  test('Aliasfehler rollt Fachdatenschreibvorgang atomar zurück', () {
    final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(datenbank.schliessen);
    repository.speichere(
      datenbank,
      const ImportAliasReferenz(
        sammlung: 'objekte',
        aliasId: 'a',
        kanonischeId: 'b',
      ),
    );
    const service = ImportAusfuehrungService();

    expect(
      () => service.ausfuehren(
        datenbank: datenbank,
        importDokument: {
          'objekte': [
            {
              'id': 'produkt-rollback',
              'name': 'Rollback-Pils',
              'art': 'produkt',
              'produktart': 'bier',
              'erstelltAm': '2026-09-02T20:00:00Z',
              'geaendertAm': '2026-09-02T20:00:00Z',
            },
          ],
        },
        strategie: ImportStrategie.importBevorzugen,
        aliase: const [
          ImportAliasReferenz(
            sammlung: 'objekte',
            aliasId: 'b',
            kanonischeId: 'a',
          ),
        ],
      ),
      throwsStateError,
    );

    expect(
      datenbank.verbindung.select(
        'SELECT id FROM objekte WHERE id = ?',
        ['produkt-rollback'],
      ),
      isEmpty,
    );
  });
}
