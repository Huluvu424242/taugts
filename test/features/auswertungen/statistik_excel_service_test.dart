import 'package:excel_community/excel_community.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';
import 'package:taugts/features/auswertungen/models/statistik_export_modelle.dart';
import 'package:taugts/features/auswertungen/services/statistik_excel_service.dart';

void main() {
  test('erzeugt drei lesbare Tabellenblätter mit Kennzahlen und Verlauf', () {
    final daten = StatistikExportDaten(
      produktbewertungen: const [
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
      ortsbewertungen: const [
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
      statistikTitel: 'Qualitätsverlauf',
      gruppierung: StatistikZeitraum.monat,
      filter: const AuswertungsFilter(
        objektId: 'p1',
        kategorieId: 'k1',
        kriteriumId: 'kriterium1',
      ),
      filterOptionen: const AuswertungsFilterOptionen(
        produkte: [AuswertungsFilterOption(id: 'p1', bezeichnung: 'Produkt 1')],
        orte: [],
        kategorien: [
          AuswertungsFilterOption(id: 'k1', bezeichnung: 'Getränke')
        ],
        kriterien: [
          AuswertungsFilterOption(id: 'kriterium1', bezeichnung: 'Geschmack'),
        ],
      ),
      zeitreihe: [
        Zeitwert(
          zeitpunkt: DateTime.utc(2026, 9, 1),
          wert: 3.5,
          beschreibung: 'Geschmack · Version 1',
          serie: 'Produkt',
          kennzahlen: const StatistikKennzahlen(
            anzahl: 4,
            minimum: 2,
            maximum: 5,
            durchschnitt: 3.5,
          ),
        ),
      ],
    );

    expect(datei.dateiname, 'taugts-statistik-2026-09-06.xlsx');
    expect(datei.inhalt, isNotEmpty);

    final excel = Excel.decodeBytes(datei.inhalt);
    expect(
      excel.tables.keys,
      containsAll(['Produktbewertungen', 'Ortsbewertungen', 'Ortsverlauf']),
    );

    expect(
      excel.tables.keys,
      contains('Aktuelle Auswertung'),
    );
    final aktuelleAuswertung = excel['Aktuelle Auswertung'];
    expect(
      aktuelleAuswertung.cell(CellIndex.indexByString('B1')).value.toString(),
      'Qualitätsverlauf',
    );
    expect(
      aktuelleAuswertung.cell(CellIndex.indexByString('B2')).value.toString(),
      'Monat',
    );
    expect(
      aktuelleAuswertung.cell(CellIndex.indexByString('B4')).value.toString(),
      'Produkt 1',
    );
    expect(
      aktuelleAuswertung.cell(CellIndex.indexByString('B5')).value.toString(),
      'Getränke',
    );
    expect(
      aktuelleAuswertung.cell(CellIndex.indexByString('B6')).value.toString(),
      'Geschmack',
    );
    expect(
      aktuelleAuswertung.cell(CellIndex.indexByString('D9')).value.toString(),
      '3.5',
    );
    expect(
      aktuelleAuswertung.cell(CellIndex.indexByString('E9')).value.toString(),
      '4',
    );

    final produkte = excel['Produktbewertungen'];
    expect(
      produkte.cell(CellIndex.indexByString('A1')).value.toString(),
      'Produkt',
    );
    expect(
      produkte.cell(CellIndex.indexByString('B1')).value.toString(),
      'Ort A',
    );
    expect(
      produkte.cell(CellIndex.indexByString('B2')).value.toString(),
      'Beste Bewertung',
    );
    expect(
      produkte.cell(CellIndex.indexByString('C2')).value.toString(),
      'Schlechteste Bewertung',
    );
    expect(
      produkte.cell(CellIndex.indexByString('A3')).value.toString(),
      'Produkt 1',
    );
    expect(
      produkte.cell(CellIndex.indexByString('B3')).value.toString(),
      '5',
    );
    expect(
      produkte.cell(CellIndex.indexByString('C3')).value.toString(),
      '3',
    );
    expect(
      produkte.cell(CellIndex.indexByString('D3')).value.toString(),
      '4',
    );

    final orte = excel['Ortsbewertungen'];
    expect(
      orte.cell(CellIndex.indexByString('A2')).value.toString(),
      'Ort A',
    );
    expect(
      orte.cell(CellIndex.indexByString('D2')).value.toString(),
      '3.5',
    );

    final verlauf = excel['Ortsverlauf'];
    expect(
      verlauf.cell(CellIndex.indexByString('B2')).value.toString(),
      'Ort A',
    );
    expect(
      verlauf.cell(CellIndex.indexByString('B3')).value.toString(),
      '3',
    );
  });
}
