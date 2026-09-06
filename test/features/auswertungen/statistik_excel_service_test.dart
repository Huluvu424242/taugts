import 'package:excel_community/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/auswertungen/models/statistik_export_modelle.dart';
import 'package:taugts/features/auswertungen/services/statistik_excel_service.dart';

void main() {
  test('erzeugt drei lesbare Tabellenblätter mit Kennzahlen und Verlauf', () {
    const daten = StatistikExportDaten(
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
      ortsbewertungen: [
        OrtsKennzahlen(
          ortId: 'o1',
          ortName: 'Ort A',
          kennzahlen: BewertungsKennzahlen(
            beste: 5,
            schlechteste: 2,
            durchschnitt: 3.5,
            anzahl: 2,
          ),
        ),
      ],
      ortsverlauf: [
        OrtsVerlaufsPunkt(
          ortId: 'o1',
          ortName: 'Ort A',
          zeitpunkt: DateTime.utc(2026, 9, 5, 18),
          durchschnitt: 3,
        ),
        OrtsVerlaufsPunkt(
          ortId: 'o1',
          ortName: 'Ort A',
          zeitpunkt: DateTime.utc(2026, 9, 6, 18),
          durchschnitt: 4,
        ),
      ],
    );

    final datei = const StatistikExcelService().erstelle(
      daten,
      zeitpunkt: DateTime.utc(2026, 9, 6),
    );

    expect(datei.dateiname, 'taugts-statistik-2026-09-06.xlsx');
    expect(datei.inhalt, isNotEmpty);

    final excel = Excel.decodeBytes(datei.inhalt);
    expect(
      excel.tables.keys,
      containsAll(['Produktbewertungen', 'Ortsbewertungen', 'Ortsverlauf']),
    );

    final produkte = excel['Produktbewertungen'];
    expect(produkte.cell(CellIndex.indexByString('A1')).value.toString(), 'Produkt');
    expect(produkte.cell(CellIndex.indexByString('B1')).value.toString(), 'Ort A');
    expect(
      produkte.cell(CellIndex.indexByString('B2')).value.toString(),
      'Beste Bewertung',
    );
    expect(
      produkte.cell(CellIndex.indexByString('C2')).value.toString(),
      'Schlechteste Bewertung',
    );
    expect(produkte.cell(CellIndex.indexByString('A3')).value.toString(), 'Produkt 1');
    expect(
      (produkte.cell(CellIndex.indexByString('B3')).value as DoubleCellValue)
          .value,
      5,
    );
    expect(
      (produkte.cell(CellIndex.indexByString('C3')).value as DoubleCellValue)
          .value,
      3,
    );
    expect(
      (produkte.cell(CellIndex.indexByString('D3')).value as DoubleCellValue)
          .value,
      4,
    );

    final orte = excel['Ortsbewertungen'];
    expect(orte.cell(CellIndex.indexByString('A2')).value.toString(), 'Ort A');
    expect(
      (orte.cell(CellIndex.indexByString('D2')).value as DoubleCellValue).value,
      3.5,
    );

    final verlauf = excel['Ortsverlauf'];
    expect(verlauf.cell(CellIndex.indexByString('B2')).value.toString(), 'Ort A');
    expect(
      (verlauf.cell(CellIndex.indexByString('B3')).value as DoubleCellValue)
          .value,
      3,
    );
  });
}
