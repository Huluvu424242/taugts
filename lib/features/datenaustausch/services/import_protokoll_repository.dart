import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/datenaustausch/services/import_strategie_service.dart';

class ImportProtokollEintrag {
  const ImportProtokollEintrag({
    required this.id,
    required this.ausgefuehrtAm,
    required this.erfolgreich,
    required this.strategie,
    required this.hinzugefuegt,
    required this.aktualisiert,
    required this.uebersprungen,
    required this.zusammengefuehrt,
    required this.fehlerhaft,
  });

  final int id;
  final DateTime ausgefuehrtAm;
  final bool erfolgreich;
  final ImportStrategie strategie;
  final int hinzugefuegt;
  final int aktualisiert;
  final int uebersprungen;
  final int zusammengefuehrt;
  final int fehlerhaft;
}

class ImportProtokollRepository {
  const ImportProtokollRepository();

  void speichere({
    required LokaleDatenbank datenbank,
    required DateTime ausgefuehrtAm,
    required bool erfolgreich,
    required ImportStrategie strategie,
    required int hinzugefuegt,
    required int aktualisiert,
    required int uebersprungen,
    required int zusammengefuehrt,
    required int fehlerhaft,
  }) {
    _stelleTabelleBereit(datenbank);
    datenbank.verbindung.execute(
      '''
        INSERT INTO import_protokoll (
          ausgefuehrt_am, erfolgreich, strategie, hinzugefuegt,
          aktualisiert, uebersprungen, zusammengefuehrt, fehlerhaft
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        ausgefuehrtAm.toUtc().toIso8601String(),
        erfolgreich ? 1 : 0,
        strategie.name,
        hinzugefuegt,
        aktualisiert,
        uebersprungen,
        zusammengefuehrt,
        fehlerhaft,
      ],
    );
  }

  List<ImportProtokollEintrag> lade(
    LokaleDatenbank datenbank, {
    int limit = 20,
  }) {
    _stelleTabelleBereit(datenbank);
    return datenbank.verbindung
        .select(
          'SELECT * FROM import_protokoll ORDER BY id DESC LIMIT ?',
          [limit],
        )
        .map(
          (zeile) => ImportProtokollEintrag(
            id: zeile['id'] as int,
            ausgefuehrtAm: DateTime.parse(zeile['ausgefuehrt_am'] as String),
            erfolgreich: zeile['erfolgreich'] == 1,
            strategie: ImportStrategie.values.byName(zeile['strategie'] as String),
            hinzugefuegt: zeile['hinzugefuegt'] as int,
            aktualisiert: zeile['aktualisiert'] as int,
            uebersprungen: zeile['uebersprungen'] as int,
            zusammengefuehrt: zeile['zusammengefuehrt'] as int,
            fehlerhaft: zeile['fehlerhaft'] as int,
          ),
        )
        .toList(growable: false);
  }

  void _stelleTabelleBereit(LokaleDatenbank datenbank) {
    datenbank.verbindung.execute('''
      CREATE TABLE IF NOT EXISTS import_protokoll (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ausgefuehrt_am TEXT NOT NULL,
        erfolgreich INTEGER NOT NULL,
        strategie TEXT NOT NULL,
        hinzugefuegt INTEGER NOT NULL,
        aktualisiert INTEGER NOT NULL,
        uebersprungen INTEGER NOT NULL,
        zusammengefuehrt INTEGER NOT NULL,
        fehlerhaft INTEGER NOT NULL
      )
    ''');
  }
}
