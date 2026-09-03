import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/datenaustausch/presentation/datenaustausch_screen.dart';
import 'package:taugts/features/datenaustausch/services/export_service.dart';
import 'package:taugts/features/datenaustausch/services/export_ziel_service.dart';
import 'package:taugts/features/datenaustausch/services/import_ausfuehrung_service.dart';
import 'package:taugts/features/datenaustausch/services/import_quelle_service.dart';

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
    'führt einen bestätigten Import aus und zeigt getrennte Zähler',
    (tester) async {
      final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
      addTearDown(datenbank.schliessen);
      final exportService = ExportService(
        datenbank,
        appVersion: '0.0.0-test',
        jetzt: () => DateTime.utc(2026, 9, 3),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DatenaustauschScreen(
            exportService: exportService,
            exportZielService: _NichtVerwendetesExportZiel(),
            importQuelleService: _FesteImportQuelle(
              exportService.erzeugeJson(),
            ),
          ),
        ),
      );

      final importPruefen = find.text('Importdatei auswählen und prüfen');
      await tester.scrollUntilVisible(
        importPruefen,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(importPruefen);
      await tester.pumpAndSettle();

      final importAusfuehren = find.text('Import verbindlich ausführen');
      expect(importAusfuehren, findsOneWidget);
      await tester.ensureVisible(importAusfuehren);
      await tester.pumpAndSettle();
      await tester.tap(importAusfuehren);
      await tester.pumpAndSettle();

      for (final bezeichnung in const [
        'Produktbewertungen',
        'Ortsbewertungen',
        'Bewertungswerte zu Orten',
      ]) {
        await tester.scrollUntilVisible(
          find.text(bezeichnung),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(bezeichnung), findsOneWidget);
      }
      expect(
        const ImportAusfuehrungService().ladeProtokoll(datenbank),
        hasLength(1),
      );
    },
  );

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
