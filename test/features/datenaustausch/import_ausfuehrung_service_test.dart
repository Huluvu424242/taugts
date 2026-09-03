import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/datenaustausch/services/import_ausfuehrung_service.dart';
import 'package:taugts/features/datenaustausch/services/import_strategie_service.dart';

void main() {
  late LokaleDatenbank datenbank;
  const service = ImportAusfuehrungService();

  setUp(() => datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory()));
  tearDown(() => datenbank.schliessen());

  Map<String, Object?> leeresDokument({
    List<Map<String, Object?>> profile = const [],
  }) =>
      {
        'profile': profile,
        'objekte': <Object?>[],
        'orte': <Object?>[],
        'bewertungskriterien': <Object?>[],
        'erlebnisse': <Object?>[],
        'erlebnisPositionen': <Object?>[],
        'preisbeobachtungen': <Object?>[],
        'ortsbewertungen': <Object?>[],
        'bewertungen': <Object?>[],
      };

  Map<String, Object?> vollstaendigesDokument() => {
        'profile': [
          {
            'id': 'profil-1',
            'anzeigename': 'Importprofil',
            'erstelltAm': '2026-09-01T10:00:00.000Z',
            'geaendertAm': '2026-09-01T10:00:00.000Z',
          },
        ],
        'objekte': [
          {
            'id': 'produkt-1',
            'name': 'Testbier',
            'art': 'getraenk',
            'produktart': 'bier',
            'marke': 'Testmarke',
            'erstelltAm': '2026-09-01T10:00:00.000Z',
            'geaendertAm': '2026-09-01T10:00:00.000Z',
          },
        ],
        'orte': [
          {
            'id': 'ort-1',
            'name': 'Testlokal',
            'typ': 'gastronomie',
            'erstelltAm': '2026-09-01T10:00:00.000Z',
            'geaendertAm': '2026-09-01T10:00:00.000Z',
          },
        ],
        'bewertungskriterien': [
          {
            'id': 'kriterium-1',
            'name': 'Geschmack',
            'beschreibung': null,
            'eingabetyp': 'wertung',
            'reihenfolge': 1,
            'aktiv': true,
            'produktart': 'bier',
            'objektart': 'getraenk',
            'version': 1,
            'auswahlwerte': <String>[],
            'erstelltAm': '2026-09-01T10:00:00.000Z',
            'geaendertAm': '2026-09-01T10:00:00.000Z',
          },
        ],
        'erlebnisse': [
          {
            'id': 'erlebnis-1',
            'herkunftProfilId': 'profil-1',
            'typ': 'gastronomie',
            'status': 'abgeschlossen',
            'ortId': 'ort-1',
            'tatsaechlicherBeginn': '2026-09-01T18:00:00.000Z',
            'tatsaechlichesEnde': '2026-09-01T20:00:00.000Z',
            'istEntwurf': false,
            'erstelltAm': '2026-09-01T20:00:00.000Z',
            'geaendertAm': '2026-09-01T20:00:00.000Z',
          },
        ],
        'erlebnisPositionen': [
          {
            'id': 'position-1',
            'erlebnisId': 'erlebnis-1',
            'produktId': 'produkt-1',
            'anzahl': 1,
            'erstelltAm': '2026-09-01T20:00:00.000Z',
            'geaendertAm': '2026-09-01T20:00:00.000Z',
          },
        ],
        'preisbeobachtungen': [
          {
            'id': 'preis-1',
            'erlebnisId': 'erlebnis-1',
            'erlebnisPositionId': 'position-1',
            'produktId': 'produkt-1',
            'ortId': 'ort-1',
            'betragMinor': 450,
            'waehrung': 'EUR',
            'beobachtetAm': '2026-09-01T18:30:00.000Z',
            'erstelltAm': '2026-09-01T20:00:00.000Z',
            'geaendertAm': '2026-09-01T20:00:00.000Z',
          },
        ],
        'ortsbewertungen': [
          {
            'id': 'ortsbewertung-1',
            'erlebnisId': 'erlebnis-1',
            'ortId': 'ort-1',
            'herkunftProfilId': 'profil-1',
            'bewertetAm': '2026-09-01T20:00:00.000Z',
            'notiz': 'Angenehm',
            'erstelltAm': '2026-09-01T20:00:00.000Z',
            'geaendertAm': '2026-09-01T20:00:00.000Z',
          },
        ],
        'bewertungen': [
          {
            'id': 'produktbewertung-1',
            'zielart': 'produkt',
            'objektId': 'produkt-1',
            'erlebnisId': 'erlebnis-1',
            'erlebnisPositionId': 'position-1',
            'ortId': 'ort-1',
            'herkunftProfilId': 'profil-1',
            'wert': 4.0,
            'erstelltAm': '2026-09-01T20:00:00.000Z',
            'geaendertAm': '2026-09-01T20:00:00.000Z',
            'kriterium': {
              'id': 'kriterium-1',
              'name': 'Geschmack',
              'beschreibung': null,
              'eingabetyp': 'wertung',
              'reihenfolge': 1,
              'version': 1,
              'auswahlwerte': <String>[],
            },
          },
          {
            'id': 'ortsbewertungswert-1',
            'zielart': 'ort',
            'objektId': 'ort-1',
            'erlebnisId': 'erlebnis-1',
            'ortsbewertungId': 'ortsbewertung-1',
            'ortId': 'ort-1',
            'herkunftProfilId': 'profil-1',
            'wert': 5.0,
            'erstelltAm': '2026-09-01T20:00:00.000Z',
            'geaendertAm': '2026-09-01T20:00:00.000Z',
            'kriterium': {
              'id': 'kriterium-1',
              'name': 'Geschmack',
              'beschreibung': null,
              'eingabetyp': 'wertung',
              'reihenfolge': 1,
              'version': 1,
              'auswahlwerte': <String>[],
            },
          },
        ],
      };

  test(
      'importiert alle historischen Entitäten anhand stabiler IDs genau einmal',
      () {
    final import = vollstaendigesDokument();

    final erstes = service.ausfuehren(
      datenbank: datenbank,
      importDokument: import,
      strategie: ImportStrategie.importBevorzugen,
      ausgefuehrtAm: DateTime.utc(2026, 9, 2, 10),
    );
    final zweites = service.ausfuehren(
      datenbank: datenbank,
      importDokument: import,
      strategie: ImportStrategie.importBevorzugen,
      ausgefuehrtAm: DateTime.utc(2026, 9, 2, 11),
    );

    expect(erstes.nachSammlung['erlebnisse']!.hinzugefuegt, 1);
    expect(erstes.nachSammlung['erlebnisPositionen']!.hinzugefuegt, 1);
    expect(erstes.nachSammlung['preisbeobachtungen']!.hinzugefuegt, 1);
    expect(erstes.nachSammlung['ortsbewertungen']!.hinzugefuegt, 1);
    expect(erstes.nachSammlung['produktbewertungen']!.hinzugefuegt, 1);
    expect(erstes.nachSammlung['ortsbewertungswerte']!.hinzugefuegt, 1);

    expect(zweites.nachSammlung['erlebnisse']!.aktualisiert, 1);
    expect(zweites.nachSammlung['erlebnisPositionen']!.aktualisiert, 1);
    expect(zweites.nachSammlung['preisbeobachtungen']!.aktualisiert, 1);
    expect(zweites.nachSammlung['ortsbewertungen']!.aktualisiert, 1);
    expect(zweites.nachSammlung['produktbewertungen']!.aktualisiert, 1);
    expect(zweites.nachSammlung['ortsbewertungswerte']!.aktualisiert, 1);
    expect(erstes.gesamt.hinzugefuegt, 10);
    expect(zweites.gesamt.aktualisiert, 10);

    for (final tabelle in const {
      'erlebnisse': 1,
      'erlebnispositionen': 1,
      'preisbeobachtungen': 1,
      'ortsbewertungen': 1,
      'bewertungen': 2,
    }.entries) {
      expect(
        datenbank.verbindung
            .select('SELECT COUNT(*) AS n FROM ${tabelle.key}')
            .single['n'],
        tabelle.value,
        reason: tabelle.key,
      );
    }
  });

  test('rollt den gesamten Import bei einem Fehler zurück', () {
    final vorher = {
      for (final tabelle in const [
        'profile',
        'objekte',
        'orte',
        'erlebnisse',
        'erlebnispositionen',
        'preisbeobachtungen',
        'ortsbewertungen',
        'bewertungen',
      ])
        tabelle: datenbank.verbindung
            .select('SELECT COUNT(*) AS n FROM $tabelle')
            .single['n'],
    };
    final import = vollstaendigesDokument();
    import['orte'] = [
      <String, Object?>{
        'id': 'ort-defekt',
        'name': null,
        'typ': 'gastronomie',
        'erstelltAm': '2026-09-01T10:00:00.000Z',
        'geaendertAm': '2026-09-01T10:00:00.000Z',
      },
    ];

    expect(
      () => service.ausfuehren(
        datenbank: datenbank,
        importDokument: import,
        strategie: ImportStrategie.importBevorzugen,
        ausgefuehrtAm: DateTime.utc(2026, 9, 2, 12),
      ),
      throwsA(anything),
    );

    for (final eintrag in vorher.entries) {
      expect(
        datenbank.verbindung
            .select('SELECT COUNT(*) AS n FROM ${eintrag.key}')
            .single['n'],
        eintrag.value,
        reason: eintrag.key,
      );
    }
  });

  test('protokolliert Erfolg und Rollback lokal ohne Fachinhalte', () {
    service.ausfuehren(
      datenbank: datenbank,
      importDokument: leeresDokument(profile: [
        {
          'id': 'profil-1',
          'anzeigename': 'Nicht im Protokoll speichern',
          'erstelltAm': '2026-09-01T10:00:00.000Z',
          'geaendertAm': '2026-09-01T10:00:00.000Z',
        },
      ]),
      strategie: ImportStrategie.importBevorzugen,
      ausgefuehrtAm: DateTime.utc(2026, 9, 2, 13),
    );

    final fehlerhaft = leeresDokument();
    fehlerhaft['orte'] = [
      {
        'id': 'ort-defekt',
        'name': null,
        'typ': 'gastronomie',
        'erstelltAm': '2026-09-01T10:00:00.000Z',
        'geaendertAm': '2026-09-01T10:00:00.000Z',
      },
    ];
    expect(
      () => service.ausfuehren(
        datenbank: datenbank,
        importDokument: fehlerhaft,
        strategie: ImportStrategie.importBevorzugen,
        ausgefuehrtAm: DateTime.utc(2026, 9, 2, 14),
      ),
      throwsA(anything),
    );

    final protokoll = service.ladeProtokoll(datenbank);
    expect(protokoll, hasLength(2));
    expect(protokoll.first.erfolgreich, isFalse);
    expect(protokoll.first.fehlerhaft, greaterThan(0));
    expect(protokoll.last.erfolgreich, isTrue);
    expect(protokoll.last.hinzugefuegt, 1);

    final spalten = datenbank.verbindung
        .select('PRAGMA table_info(import_protokoll)')
        .map((zeile) => zeile['name'])
        .toSet();
    expect(spalten, isNot(contains('anzeigename')));
    expect(spalten, isNot(contains('inhalt')));
  });

  test('Bestand ersetzen entfernt nicht importierte Fachdaten atomar', () {
    service.ausfuehren(
      datenbank: datenbank,
      importDokument: vollstaendigesDokument(),
      strategie: ImportStrategie.importBevorzugen,
    );

    service.ausfuehren(
      datenbank: datenbank,
      importDokument: leeresDokument(),
      strategie: ImportStrategie.bestandErsetzen,
    );

    for (final tabelle in const [
      'profile',
      'objekte',
      'produkte',
      'orte',
      'kriterien',
      'erlebnisse',
      'erlebnispositionen',
      'preisbeobachtungen',
      'ortsbewertungen',
      'bewertungen',
    ]) {
      expect(
        datenbank.verbindung.select('SELECT * FROM $tabelle'),
        isEmpty,
        reason: tabelle,
      );
    }
  });

  test('weist zusammengeführte Datensätze getrennt von Aktualisierungen aus',
      () {
    final import = leeresDokument(profile: [
      {
        'id': 'profil-1',
        'anzeigename': 'Importprofil',
        'erstelltAm': '2026-09-01T10:00:00.000Z',
        'geaendertAm': '2026-09-01T10:00:00.000Z',
      },
    ]);
    service.ausfuehren(
      datenbank: datenbank,
      importDokument: import,
      strategie: ImportStrategie.importBevorzugen,
    );

    final ergebnis = service.ausfuehren(
      datenbank: datenbank,
      importDokument: import,
      strategie: ImportStrategie.importBevorzugen,
      zusammengefuehrtNachSammlung: const {'profile': 1},
    );

    expect(ergebnis.nachSammlung['profile']!.zusammengefuehrt, 1);
    expect(ergebnis.nachSammlung['profile']!.aktualisiert, 0);
    expect(service.ladeProtokoll(datenbank).first.zusammengefuehrt, 1);
  });
}
