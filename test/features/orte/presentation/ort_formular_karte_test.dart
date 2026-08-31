import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/orte/presentation/ort_formular.dart';

class _FesterIdGenerator implements IdGenerator {
  @override
  String neueId() => 'a2000000-0000-4000-8000-000000000001';
}

void main() {
  testWidgets(
    'übergibt vorhandene Koordinaten und übernimmt die Kartenposition',
    (tester) async {
      final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
      addTearDown(datenbank.schliessen);
      final repository = SqliteBewertungsRepository(datenbank);
      LatLng? ausgangsposition;
      final zeit = DateTime.utc(2026, 8, 31);

      await tester.pumpWidget(
        MaterialApp(
          home: OrtFormular(
            repository: repository,
            idGenerator: _FesterIdGenerator(),
            ort: Ort(
              id: 'a2000000-0000-4000-8000-000000000002',
              name: 'Vorhandener Ort',
              typ: Ortstyp.gastronomie,
              breitengrad: 50.8323,
              laengengrad: 12.9253,
              erstelltAm: zeit,
              geaendertAm: zeit,
            ),
            karteOeffnen: (context, position) async {
              ausgangsposition = position;
              return const LatLng(50.9, 13.1);
            },
          ),
        ),
      );

      await tester.tap(find.text('Position auf OpenStreetMap auswählen'));
      await tester.pumpAndSettle();

      expect(ausgangsposition?.latitude, 50.8323);
      expect(ausgangsposition?.longitude, 12.9253);
      expect(
        find.text('Kartenposition übernommen und weiter bearbeitbar.'),
        findsOneWidget,
      );
      final breite = find.widgetWithText(
        TextFormField,
        'Breitengrad (optional)',
      );
      final laenge = find.widgetWithText(
        TextFormField,
        'Längengrad (optional)',
      );
      expect(
        tester.widget<TextFormField>(breite).controller!.text,
        '50.900000',
      );
      expect(
        tester.widget<TextFormField>(laenge).controller!.text,
        '13.100000',
      );
    },
  );
}
