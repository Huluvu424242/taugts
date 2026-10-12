import 'package:flutter/material.dart';
import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';

/// Zeigt dieselben Beobachtungen als Diagramm und zugängliche Tabelle.
class StatistikVerlaufDarstellung extends StatelessWidget {
  const StatistikVerlaufDarstellung({
    required this.daten,
    super.key,
  });

  final List<Zeitwert> daten;

  @override
  Widget build(BuildContext context) {
    if (daten.isEmpty) {
      return const Text('Für diesen Zeitraum liegen keine Daten vor.');
    }

    final punkte = [...daten]..sort(
        (a, b) => a.zeitpunkt.compareTo(b.zeitpunkt),
      );
    final serien = punkte.map((punkt) => punkt.serie ?? '').toSet().toList()
      ..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final serie in serien)
          ..._serienDarstellung(
            context,
            punkte.where((punkt) => (punkt.serie ?? '') == serie).toList(),
            serie,
          ),
      ],
    );
  }

  List<Widget> _serienDarstellung(
    BuildContext context,
    List<Zeitwert> punkte,
    String serie,
  ) {
    final mitKennzahlen = punkte.any((punkt) => punkt.kennzahlen != null);
    return [
      if (serie.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Einheit: $serie',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      Semantics(
        label: _diagrammBeschreibung(punkte),
        child: ExcludeSemantics(
          child: SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _VerlaufMaler(
                werte: [for (final punkt in punkte) punkt.wert],
                farbe: Theme.of(context).colorScheme.primary,
                hilfslinienFarbe: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Zeitpunkt')),
            DataColumn(
              label: Text(mitKennzahlen ? 'Mittelwert' : 'Wert'),
            ),
            if (mitKennzahlen) ...const [
              DataColumn(label: Text('Anzahl')),
              DataColumn(label: Text('Minimum')),
              DataColumn(label: Text('Maximum')),
            ],
            const DataColumn(label: Text('Beschreibung')),
          ],
          rows: [
            for (final punkt in punkte)
              DataRow(
                cells: [
                  DataCell(Text(_zeitpunkt(punkt.zeitpunkt))),
                  DataCell(Text(_zahl(punkt.wert))),
                  if (mitKennzahlen) ...[
                    DataCell(Text('${punkt.kennzahlen!.anzahl}')),
                    DataCell(Text(_zahl(punkt.kennzahlen!.minimum))),
                    DataCell(Text(_zahl(punkt.kennzahlen!.maximum))),
                  ],
                  DataCell(Text(punkt.beschreibung)),
                ],
              ),
          ],
        ),
      ),
    ];
  }

  String _diagrammBeschreibung(List<Zeitwert> punkte) {
    final werte = punkte.map((punkt) => punkt.wert).toList();
    return 'Zeitverlauf mit ${punkte.length} Datenpunkten. '
        'Kleinster Wert ${_zahl(werte.reduce((a, b) => a < b ? a : b))}, '
        'größter Wert ${_zahl(werte.reduce((a, b) => a > b ? a : b))}. '
        'Die genaue Datentabelle folgt.';
  }

  String _zahl(double wert) => wert.toStringAsFixed(2).replaceAll('.', ',');

  String _zeitpunkt(DateTime zeitpunkt) {
    final lokal = zeitpunkt.toLocal();
    final tag = lokal.day.toString().padLeft(2, '0');
    final monat = lokal.month.toString().padLeft(2, '0');
    final datum = '$tag.$monat.${lokal.year}';
    if (lokal.hour == 0 && lokal.minute == 0) return datum;
    final stunde = lokal.hour.toString().padLeft(2, '0');
    final minute = lokal.minute.toString().padLeft(2, '0');
    return '$datum, $stunde:$minute';
  }
}

class _VerlaufMaler extends CustomPainter {
  const _VerlaufMaler({
    required this.werte,
    required this.farbe,
    required this.hilfslinienFarbe,
  });

  final List<double> werte;
  final Color farbe;
  final Color hilfslinienFarbe;

  @override
  void paint(Canvas canvas, Size size) {
    const abstand = 12.0;
    final diagramm = Rect.fromLTWH(
      abstand,
      abstand,
      size.width - abstand * 2,
      size.height - abstand * 2,
    );
    final hilfslinien = Paint()
      ..color = hilfslinienFarbe
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index++) {
      final y = diagramm.top + diagramm.height * index / 3;
      canvas.drawLine(
          Offset(diagramm.left, y), Offset(diagramm.right, y), hilfslinien);
    }

    final minimum = werte.reduce((a, b) => a < b ? a : b);
    final maximum = werte.reduce((a, b) => a > b ? a : b);
    final spannweite = maximum - minimum;
    final linie = Paint()
      ..color = farbe
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final punktFarbe = Paint()..color = farbe;
    final pfad = Path();

    for (var index = 0; index < werte.length; index++) {
      final x = werte.length == 1
          ? diagramm.center.dx
          : diagramm.left + diagramm.width * index / (werte.length - 1);
      final anteil =
          spannweite == 0 ? 0.5 : (werte[index] - minimum) / spannweite;
      final y = diagramm.bottom - diagramm.height * anteil;
      final punkt = Offset(x, y);
      if (index == 0) {
        pfad.moveTo(punkt.dx, punkt.dy);
      } else {
        pfad.lineTo(punkt.dx, punkt.dy);
      }
      canvas.drawCircle(punkt, 3.5, punktFarbe);
    }
    canvas.drawPath(pfad, linie);
  }

  @override
  bool shouldRepaint(_VerlaufMaler oldDelegate) =>
      oldDelegate.werte != werte ||
      oldDelegate.farbe != farbe ||
      oldDelegate.hilfslinienFarbe != hilfslinienFarbe;
}
