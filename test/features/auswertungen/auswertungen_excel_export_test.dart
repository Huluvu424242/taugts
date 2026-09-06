import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';
import 'package:taugts/features/auswertungen/models/statistik_export_modelle.dart';
import 'package:taugts/features/auswertungen/presentation/auswertungen_screen.dart';
import 'package:taugts/features/auswertungen/services/auswertungs_service.dart';
import 'package:taugts/features/auswertungen/services/statistik_export_service.dart';
import 'package:taugts/features/datenaustausch/services/binaer_export_ziel_service.dart';

void main() {
  testWidgets('Exportieren speichert eine xlsx-Datei und meldet Erfolg',
      (tester) async {
    final ziel = _FakeBinaerExportZielService();
    await tester.pumpWidget(
      MaterialApp(
        home: AuswertungenScreen(
          service: const _FakeAuswertungsService(),
          statistikExportService: const _FakeStatistikExportService(),
          exportZielService: ziel,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Exportieren'));
    await tester.pumpAndSettle();

    expect(ziel.dateiname, startsWith('taugts-statistik-'));
    expect(ziel.dateiname, endsWith('.xlsx'));
    expect(ziel.dateiendung, 'xlsx');
    expect(ziel.inhalt, isNotNull);
    expect(ziel.inhalt, isNotEmpty);
    expect(find.textContaining('Excel-Export gespeichert:'), findsOneWidget);
  });

  testWidgets('ohne Qualitätswertungen wird keine leere Datei gespeichert',
      (tester) async {
    final ziel = _FakeBinaerExportZielService();
    await tester.pumpWidget(
      MaterialApp(
        home: AuswertungenScreen(
          service: const _FakeAuswertungsService(),
          statistikExportService: const _LeererStatistikExportService(),
          exportZielService: ziel,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Exportieren'));
    await tester.pumpAndSettle();

    expect(ziel.inhalt, isNull);
    expect(
      find.textContaining('noch keine Qualitätswertungen vorhanden'),
      findsOneWidget,
    );
  });
}

class _FakeAuswertungsService implements AuswertungsService {
  const _FakeAuswertungsService();

  @override
  Future<AuswertungsUebersicht> berechne(AuswertungsFilter filter) async =>
      const AuswertungsUebersicht(
        bewertungsanzahl: 1,
        durchschnitte: [],
        preisverlauf: [],
        qualitaetsverlauf: [],
        ortsverlauf: [],
        erlebnisgruppen: [],
        andrangBeobachtungen: [],
      );
}

class _FakeStatistikExportService implements StatistikExportService {
  const _FakeStatistikExportService();

  @override
  Future<StatistikExportDaten> ladeDaten() async => const StatistikExportDaten(
        produktbewertungen: [
          ProduktOrtKennzahlen(
            produktId: 'p1',
            produktName: 'Produkt 1',
            ortId: 'o1',
            ortName: 'Ort A',
            kennzahlen: BewertungsKennzahlen(
              beste: 5,
              schlechteste: 3,
              durchschnitt: 4,
              anzahl: 2,
            ),
          ),
        ],
        ortsbewertungen: [],
        ortsverlauf: [],
      );
}

class _LeererStatistikExportService implements StatistikExportService {
  const _LeererStatistikExportService();

  @override
  Future<StatistikExportDaten> ladeDaten() async => const StatistikExportDaten(
        produktbewertungen: [],
        ortsbewertungen: [],
        ortsverlauf: [],
      );
}

class _FakeBinaerExportZielService implements BinaerExportZielService {
  String? dateiname;
  String? dateiendung;
  Uint8List? inhalt;

  @override
  Future<String?> speichern({
    required String dateiname,
    required Uint8List inhalt,
    required String dateiendung,
  }) async {
    this.dateiname = dateiname;
    this.inhalt = inhalt;
    this.dateiendung = dateiendung;
    return '/tmp/$dateiname';
  }
}
