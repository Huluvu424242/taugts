import 'dart:typed_data';

import 'package:excel_community/excel.dart';
import 'package:taugts/features/auswertungen/models/statistik_export_modelle.dart';

class StatistikExcelDatei {
  const StatistikExcelDatei({
    required this.dateiname,
    required this.inhalt,
  });

  final String dateiname;
  final Uint8List inhalt;
}

class StatistikExcelService {
  const StatistikExcelService();

  StatistikExcelDatei erstelle(
    StatistikExportDaten daten, {
    DateTime? zeitpunkt,
  }) {
    final excel = Excel.createExcel();
    _produktbewertungen(excel, daten.produktbewertungen);
    _ortsbewertungen(excel, daten.ortsbewertungen);
    _ortsverlauf(excel, daten.ortsverlauf);
    excel.delete('Sheet1');

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Die Excel-Datei konnte nicht erzeugt werden.');
    }
    final jetzt = (zeitpunkt ?? DateTime.now()).toLocal();
    return StatistikExcelDatei(
      dateiname: 'taugts-statistik-${_dateiDatum(jetzt)}.xlsx',
      inhalt: Uint8List.fromList(bytes),
    );
  }

  void _produktbewertungen(
    Excel excel,
    List<ProduktOrtKennzahlen> daten,
  ) {
    final sheet = excel['Produktbewertungen'];
    sheet.frozenRows = 2;
    sheet.frozenColumns = 1;
    sheet.setColumnWidth(0, 30);

    final orte = <String, String>{};
    final produkte = <String, String>{};
    final matrix = <String, Map<String, BewertungsKennzahlen>>{};
    for (final eintrag in daten) {
      orte[eintrag.ortId] = eintrag.ortName;
      produkte[eintrag.produktId] = eintrag.produktName;
      matrix
          .putIfAbsent(eintrag.produktId, () => {})[eintrag.ortId] =
          eintrag.kennzahlen;
    }

    final ortIds = orte.keys.toList()
      ..sort((a, b) => orte[a]!.compareTo(orte[b]!));
    final produktIds = produkte.keys.toList()
      ..sort((a, b) => produkte[a]!.compareTo(produkte[b]!));

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      customValue: TextCellValue('Produkt'),
    );
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle = _hauptKopfStyle;

    for (var ortIndex = 0; ortIndex < ortIds.length; ortIndex++) {
      final start = 1 + ortIndex * 3;
      final ende = start + 2;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: start, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: ende, rowIndex: 0),
        customValue: TextCellValue(orte[ortIds[ortIndex]]!),
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: start, rowIndex: 0))
          .cellStyle = _hauptKopfStyle;
      for (var offset = 0; offset < 3; offset++) {
        sheet.setColumnWidth(start + offset, 16);
      }
      _textZelle(sheet, start, 1, 'Beste Bewertung', _kopfStyle);
      _textZelle(sheet, start + 1, 1, 'Schlechteste Bewertung', _kopfStyle);
      _textZelle(sheet, start + 2, 1, 'Durchschnitt', _kopfStyle);
    }

    for (var produktIndex = 0;
        produktIndex < produktIds.length;
        produktIndex++) {
      final zeile = produktIndex + 2;
      final produktId = produktIds[produktIndex];
      _textZelle(sheet, 0, zeile, produkte[produktId]!, _zeilenKopfStyle);
      for (var ortIndex = 0; ortIndex < ortIds.length; ortIndex++) {
        final kennzahlen = matrix[produktId]?[ortIds[ortIndex]];
        if (kennzahlen == null) continue;
        final start = 1 + ortIndex * 3;
        _zahlZelle(sheet, start, zeile, kennzahlen.beste, _besteStyle);
        _zahlZelle(
          sheet,
          start + 1,
          zeile,
          kennzahlen.schlechteste,
          _schlechtesteStyle,
        );
        _zahlZelle(
          sheet,
          start + 2,
          zeile,
          kennzahlen.durchschnitt,
          _zahlStyle,
        );
      }
    }
  }

  void _ortsbewertungen(Excel excel, List<OrtsKennzahlen> daten) {
    final sheet = excel['Ortsbewertungen'];
    sheet.frozenRows = 1;
    sheet.setColumnWidth(0, 30);
    for (var spalte = 1; spalte <= 3; spalte++) {
      sheet.setColumnWidth(spalte, 18);
    }
    _textZelle(sheet, 0, 0, 'Ort', _hauptKopfStyle);
    _textZelle(sheet, 1, 0, 'Beste Bewertung', _hauptKopfStyle);
    _textZelle(sheet, 2, 0, 'Schlechteste Bewertung', _hauptKopfStyle);
    _textZelle(sheet, 3, 0, 'Durchschnitt', _hauptKopfStyle);

    for (var index = 0; index < daten.length; index++) {
      final zeile = index + 1;
      final eintrag = daten[index];
      _textZelle(sheet, 0, zeile, eintrag.ortName, _zeilenKopfStyle);
      _zahlZelle(sheet, 1, zeile, eintrag.kennzahlen.beste, _besteStyle);
      _zahlZelle(
        sheet,
        2,
        zeile,
        eintrag.kennzahlen.schlechteste,
        _schlechtesteStyle,
      );
      _zahlZelle(
        sheet,
        3,
        zeile,
        eintrag.kennzahlen.durchschnitt,
        _zahlStyle,
      );
    }
  }

  void _ortsverlauf(Excel excel, List<OrtsVerlaufsPunkt> daten) {
    final sheet = excel['Ortsverlauf'];
    sheet.frozenRows = 2;
    sheet.frozenColumns = 1;
    sheet.setColumnWidth(0, 22);
    _textZelle(
      sheet,
      0,
      0,
      'Jeder Punkt ist der Durchschnitt aller Qualitätswertungen einer einzelnen Ortsbewertung. Kriterienversionen bleiben Bestandteil des jeweiligen historischen Bewertungsstands.',
      _hinweisStyle,
    );

    final orte = <String, String>{};
    for (final punkt in daten) {
      orte[punkt.ortId] = punkt.ortName;
    }
    final ortIds = orte.keys.toList()
      ..sort((a, b) => orte[a]!.compareTo(orte[b]!));
    if (ortIds.isNotEmpty) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: ortIds.length, rowIndex: 0),
      );
    }

    _textZelle(sheet, 0, 1, 'Zeitpunkt', _hauptKopfStyle);
    for (var index = 0; index < ortIds.length; index++) {
      sheet.setColumnWidth(index + 1, 16);
      _textZelle(sheet, index + 1, 1, orte[ortIds[index]]!, _hauptKopfStyle);
    }

    final zeitpunkte = daten.map((punkt) => punkt.zeitpunkt).toSet().toList()
      ..sort();
    final matrix = <DateTime, Map<String, double>>{};
    for (final punkt in daten) {
      matrix.putIfAbsent(punkt.zeitpunkt, () => {})[punkt.ortId] =
          punkt.durchschnitt;
    }

    for (var zeitIndex = 0; zeitIndex < zeitpunkte.length; zeitIndex++) {
      final zeile = zeitIndex + 2;
      final zeit = zeitpunkte[zeitIndex].toLocal();
      final zelle = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: zeile),
      );
      zelle.value = DateTimeCellValue(
        year: zeit.year,
        month: zeit.month,
        day: zeit.day,
        hour: zeit.hour,
        minute: zeit.minute,
        second: zeit.second,
      );
      zelle.cellStyle = _datumStyle;
      for (var ortIndex = 0; ortIndex < ortIds.length; ortIndex++) {
        final wert = matrix[zeitpunkte[zeitIndex]]?[ortIds[ortIndex]];
        if (wert != null) {
          _zahlZelle(sheet, ortIndex + 1, zeile, wert, _zahlStyle);
        }
      }
    }

    if (zeitpunkte.isNotEmpty && ortIds.isNotEmpty) {
      final ersteDatenzeile = 3;
      final letzteDatenzeile = zeitpunkte.length + 2;
      final serien = <ChartSeries>[];
      for (var ortIndex = 0; ortIndex < ortIds.length; ortIndex++) {
        final spalte = _excelSpalte(ortIndex + 1);
        serien.add(
          ChartSeries(
            name: orte[ortIds[ortIndex]]!,
            categoriesRange:
                'Ortsverlauf!\$A\$$ersteDatenzeile:\$A\$$letzteDatenzeile',
            valuesRange:
                'Ortsverlauf!\$$spalte\$$ersteDatenzeile:\$$spalte\$$letzteDatenzeile',
          ),
        );
      }
      sheet.addChart(
        LineChart(
          title: 'Entwicklung der Ortsbewertungen',
          series: serien,
          anchor: ChartAnchor.at(
            column: ortIds.length + 2,
            row: 1,
            width: 14,
            height: 18,
          ),
          showLegend: true,
        ),
      );
    }
  }

  void _textZelle(
    Sheet sheet,
    int spalte,
    int zeile,
    String text,
    CellStyle style,
  ) {
    final zelle = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: spalte, rowIndex: zeile),
    );
    zelle.value = TextCellValue(text);
    zelle.cellStyle = style;
  }

  void _zahlZelle(
    Sheet sheet,
    int spalte,
    int zeile,
    double wert,
    CellStyle style,
  ) {
    final zelle = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: spalte, rowIndex: zeile),
    );
    zelle.value = DoubleCellValue(wert);
    zelle.cellStyle = style;
  }

  String _excelSpalte(int index) {
    var nummer = index + 1;
    var ergebnis = '';
    while (nummer > 0) {
      nummer--;
      ergebnis = String.fromCharCode(65 + nummer % 26) + ergebnis;
      nummer ~/= 26;
    }
    return ergebnis;
  }

  String _dateiDatum(DateTime zeitpunkt) =>
      '${zeitpunkt.year.toString().padLeft(4, '0')}-'
      '${zeitpunkt.month.toString().padLeft(2, '0')}-'
      '${zeitpunkt.day.toString().padLeft(2, '0')}';

  static final _hauptKopfStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('D9EAF7'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );
  static final _kopfStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('EAF2F8'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );
  static final _zeilenKopfStyle = CellStyle(bold: true);
  static final _zahlStyle = CellStyle(
    horizontalAlign: HorizontalAlign.Right,
    numberFormat: CustomNumericNumFormat('0.00'),
  );
  static final _besteStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString('E2F0D9'),
    horizontalAlign: HorizontalAlign.Right,
    numberFormat: CustomNumericNumFormat('0.00'),
  );
  static final _schlechtesteStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString('FCE4D6'),
    horizontalAlign: HorizontalAlign.Right,
    numberFormat: CustomNumericNumFormat('0.00'),
  );
  static final _datumStyle = CellStyle(
    numberFormat: CustomDateTimeNumFormat('dd.mm.yyyy hh:mm'),
  );
  static final _hinweisStyle = CellStyle(
    italic: true,
    textWrapping: TextWrapping.WrapText,
  );
}
