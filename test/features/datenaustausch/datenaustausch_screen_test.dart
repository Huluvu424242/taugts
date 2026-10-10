import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/datenaustausch/presentation/datenaustausch_screen.dart';
import 'package:taugts/features/datenaustausch/services/export_service.dart';
import 'package:taugts/features/datenaustausch/services/export_ziel_service.dart';
import 'package:taugts/features/datenaustausch/services/import_ausfuehrung_service.dart';
import 'package:taugts/features/datenaustausch/services/import_konfliktentscheidung_service.dart';
import 'package:taugts/features/datenaustausch/services/import_quelle_service.dart';
import 'package:taugts/features/datenaustausch/services/import_strategie_service.dart';

class _KontrollierteImportQuelle implements ImportQuelleService {
  final completer = Completer<String?>();
  var aufrufe = 0;

  @override
  Future<String?> dateiAuswaehlen() {
    aufrufe += 1;
    return completer.future;
  }
}

class _FesteImportQuelle implements ImportQuelleService {
  const _FesteImportQuelle(this.inhalt);

  final String inhalt;

  @override
  Future<String?> dateiAuswaehlen() async => inhalt;
}

class _NichtVerwendetesExportZiel implements ExportZielService {
  @override
  Future<String?> speichern({
    required String dateiname,
    required String inhalt,
  }) {
    throw StateError('Export darf in diesem Test nicht gestartet werden.');
  }

  @override
  Future<void> teilen({
    required String dateiname,
    required String inhalt,
  }) {
    throw StateError('Export darf in diesem Test nicht gestartet werden.');
  }
}

void main() {
  testWidgets(
    'führt einen bestätigten Import aus und protokolliert den Erfolg',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
      addTearDown(datenbank.schliessen);
      final exportService = ExportService(
        datenbank,
        appVersion: '0.0.0-test',
        jetzt: () => DateTime.utc(2026, 9, 3),
      );
      final importDokument = Map<String, Object?>.from(
        jsonDecode(exportService.erzeugeJson()) as Map,
      );
      importDokument['bewertungskriterien'] = <Object?>[];

      await tester.pumpWidget(
        MaterialApp(
          home: DatenaustauschScreen(
            exportService: exportService,
            exportZielService: _NichtVerwendetesExportZiel(),
            importQuelleService: _FesteImportQuelle(
              jsonEncode(importDokument),
            ),
          ),
        ),
      );

      final importPruefen = find.text('Importdatei auswählen und prüfen');
      await tester.tap(importPruefen);
      await tester.pumpAndSettle();

      final importAusfuehren = find.text('Import verbindlich ausführen');
      expect(importAusfuehren, findsOneWidget);
      final bestaetigungsButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Import verbindlich ausführen'),
      );
      expect(bestaetigungsButton.onPressed, isNotNull);
      bestaetigungsButton.onPressed!();
      await tester.pumpAndSettle();

      final protokoll =
          const ImportAusfuehrungService().ladeProtokoll(datenbank);
      expect(protokoll, hasLength(1));
      expect(protokoll.single.erfolgreich, isTrue);
    },
  );

  testWidgets(
    'wählt ergänzenden Import als Standard und verlangt keine Einzelklicks',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
      addTearDown(datenbank.schliessen);
      final exportService = ExportService(
        datenbank,
        appVersion: '0.0.0-test',
      );
      final dokument = Map<String, Object?>.from(
        jsonDecode(exportService.erzeugeJson()) as Map,
      );
      dokument['bewertungskriterien'] = <Object?>[];
      final profile = (dokument['profile'] as List).cast<Map>();
      if (profile.isNotEmpty) {
        // Derselbe Datensatz ist vorhanden; die Vorschau benötigt
        // keine manuell ausgewählte Entscheidung.
        dokument['profile'] =
            profile.map((profil) => Map<String, Object?>.from(profil)).toList();
      }

      await tester.pumpWidget(MaterialApp(
        home: DatenaustauschScreen(
          exportService: exportService,
          exportZielService: _NichtVerwendetesExportZiel(),
          importQuelleService: _FesteImportQuelle(jsonEncode(dokument)),
        ),
      ));
      await tester.tap(find.text('Importdatei auswählen und prüfen'));
      await tester.pumpAndSettle();

      final auswahl = tester.widget<DropdownButtonFormField<ImportStrategie>>(
        find.byType(DropdownButtonFormField<ImportStrategie>).first,
      );
      expect(auswahl.initialValue, ImportStrategie.lokalBevorzugen);
      final importButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Import verbindlich ausführen'),
      );
      expect(importButton.onPressed, isNotNull);
    },
  );

  testWidgets(
    'bevorzugt Import bei Versionskonflikt ohne Einzelentscheidung',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final db = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
      addTearDown(db.schliessen);
      db.verbindung.execute(
        'INSERT INTO profile (id, anzeigename, erstellt_am, geaendert_am) '
        'VALUES (?, ?, ?, ?)',
        [
          '11111111-1111-4111-8111-111111111111',
          'Lokal',
          '2026-09-01T00:00:00Z',
          '2026-09-01T00:00:00Z'
        ],
      );
      final export = ExportService(db, appVersion: '0.0.0-test');
      final dokument = Map<String, Object?>.from(
        jsonDecode(export.erzeugeJson()) as Map,
      );
      dokument['bewertungskriterien'] = <Object?>[];
      final profile = (dokument['profile'] as List).cast<Map>();
      dokument['profile'] = [
        for (final profil in profile)
          {...Map<String, Object?>.from(profil), 'anzeigename': 'Import'},
      ];
      await tester.pumpWidget(MaterialApp(
        home: DatenaustauschScreen(
          exportService: export,
          exportZielService: _NichtVerwendetesExportZiel(),
          importQuelleService: _FesteImportQuelle(jsonEncode(dokument)),
        ),
      ));
      await tester.tap(find.text('Importdatei auswählen und prüfen'));
      await tester.pumpAndSettle();
      final aktion = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Import verbindlich ausführen'),
      );
      expect(aktion.onPressed, isNotNull);
      await tester
          .tap(find.text('Automatische Entscheidungen ansehen / anpassen'));
      await tester.pumpAndSettle();
      final konfliktAuswahl =
          tester.widget<DropdownButtonFormField<ImportKonfliktAktion>>(
        find.byType(DropdownButtonFormField<ImportKonfliktAktion>).first,
      );
      expect(konfliktAuswahl.initialValue, ImportKonfliktAktion.importVersion);
      await tester.tap(find.text('Zurück zur Importvorschau'));
      await tester.pumpAndSettle();
      final importAktion = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Import verbindlich ausführen'),
      );
      importAktion.onPressed!();
      await tester.pumpAndSettle();
      expect(
        db.verbindung
            .select(
              "SELECT anzeigename FROM profile WHERE id = '11111111-1111-4111-8111-111111111111'",
            )
            .single['anzeigename'],
        'Import',
      );
    },
  );

  testWidgets('Ersatz verlangt separate Checkbox und lässt Abbruch unverändert',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final db = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(db.schliessen);
    const alt = '11111111-1111-4111-8111-111111111111';
    const neu = '22222222-2222-4222-8222-222222222222';
    db.verbindung.execute(
      'INSERT INTO profile VALUES (?, ?, ?, ?)',
      [alt, 'Alt', '2026-09-01T00:00:00.000Z', '2026-09-01T00:00:00.000Z'],
    );
    final export = ExportService(db, appVersion: '0.0.0-test');
    final dokument = Map<String, Object?>.from(
      jsonDecode(export.erzeugeJson()) as Map,
    );
    dokument['bewertungskriterien'] = <Object?>[];
    dokument['profile'] = [
      {
        'id': neu,
        'anzeigename': 'Neu',
        'erstelltAm': '2026-09-01T00:00:00.000Z',
        'geaendertAm': '2026-09-01T00:00:00.000Z',
      },
    ];
    await tester.pumpWidget(MaterialApp(
      home: DatenaustauschScreen(
        exportService: export,
        exportZielService: _NichtVerwendetesExportZiel(),
        importQuelleService: _FesteImportQuelle(jsonEncode(dokument)),
      ),
    ));
    await tester.tap(find.text('Importdatei auswählen und prüfen'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<ImportStrategie>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gesamten lokalen Datenbestand ersetzen').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Zu entfernende Datensätze:'), findsOneWidget);

    FilledButton ersatzAktion() => tester.widget<FilledButton>(
          find
              .widgetWithText(FilledButton, 'Bestand ersetzen und importieren')
              .last,
        );
    ersatzAktion().onPressed!();
    await tester.pumpAndSettle();
    final dialogAktion = tester.widget<FilledButton>(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(
          FilledButton,
          'Bestand ersetzen und importieren',
        ),
      ),
    );
    expect(dialogAktion.onPressed, isNull);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(db.verbindung.select('SELECT id FROM profile').single['id'], alt);

    ersatzAktion().onPressed!();
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Ich bestätige den vollständigen Ersatz der lokalen Daten'),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(
          FilledButton,
          'Bestand ersetzen und importieren',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(db.verbindung.select('SELECT id FROM profile').single['id'], neu);
  });

  testWidgets('verwirft eine durch lokale Änderungen veraltete Importvorschau',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final db = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(db.schliessen);
    const id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    db.verbindung.execute(
      'INSERT INTO profile VALUES (?, ?, ?, ?)',
      [id, 'Vorher', '2026-09-01T00:00:00.000Z', '2026-09-01T00:00:00.000Z'],
    );
    final export = ExportService(db, appVersion: '0.0.0-test');
    final dokument = Map<String, Object?>.from(
      jsonDecode(export.erzeugeJson()) as Map,
    );
    dokument['bewertungskriterien'] = <Object?>[];
    await tester.pumpWidget(MaterialApp(
      home: DatenaustauschScreen(
        exportService: export,
        exportZielService: _NichtVerwendetesExportZiel(),
        importQuelleService: _FesteImportQuelle(jsonEncode(dokument)),
      ),
    ));
    await tester.tap(find.text('Importdatei auswählen und prüfen'));
    await tester.pumpAndSettle();
    db.verbindung.execute(
      'UPDATE profile SET anzeigename = ? WHERE id = ?',
      ['Nachher', id],
    );
    final aktion = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Import verbindlich ausführen'),
    );
    aktion.onPressed!();
    await tester.pumpAndSettle();
    expect(
      find.textContaining('seit der Vorschau verändert'),
      findsOneWidget,
    );
    expect(
      db.verbindung
          .select('SELECT anzeigename FROM profile')
          .single['anzeigename'],
      'Nachher',
    );
    expect(const ImportAusfuehrungService().ladeProtokoll(db), isEmpty);
  });

  testWidgets(
    'sperrt weitere Aktionen und verändert bei abgebrochener Auswahl nichts',
    (tester) async {
      final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
      addTearDown(datenbank.schliessen);
      final quelle = _KontrollierteImportQuelle();
      const importService = ImportAusfuehrungService();

      await tester.pumpWidget(
        MaterialApp(
          home: DatenaustauschScreen(
            exportService: ExportService(
              datenbank,
              appVersion: '0.0.0-test',
            ),
            exportZielService: _NichtVerwendetesExportZiel(),
            importQuelleService: quelle,
          ),
        ),
      );

      final importAktion = find.text('Importdatei auswählen und prüfen');
      await tester.scrollUntilVisible(
        importAktion,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(importAktion);
      await tester.pump();

      expect(quelle.aufrufe, 1);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final deaktivierteImportAktion = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Importdatei auswählen und prüfen'),
      );
      expect(deaktivierteImportAktion.onPressed, isNull);
      await tester.tap(importAktion, warnIfMissed: false);
      await tester.pump();
      expect(quelle.aufrufe, 1);

      quelle.completer.complete(null);
      await tester.pumpAndSettle();

      expect(find.text('Dateiauswahl abgebrochen.'), findsOneWidget);
      expect(
        find.text('Noch keine Importausführung protokolliert.'),
        findsOneWidget,
      );
      expect(importService.ladeProtokoll(datenbank), isEmpty);
      for (final tabelle in const [
        'profile',
        'objekte',
        'orte',
        'erlebnisse',
        'erlebnispositionen',
        'preisbeobachtungen',
        'ortsbewertungen',
        'bewertungen',
      ]) {
        expect(
          datenbank.verbindung
              .select('SELECT COUNT(*) AS anzahl FROM $tabelle')
              .single['anzahl'],
          0,
          reason: tabelle,
        );
      }
    },
  );
}
