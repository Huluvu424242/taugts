import 'package:flutter/material.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';
import 'package:taugts/features/auswertungen/presentation/statistik_verlauf_darstellung.dart';
import 'package:taugts/features/auswertungen/services/auswertungs_service.dart';
import 'package:taugts/features/auswertungen/services/statistik_excel_service.dart';
import 'package:taugts/features/auswertungen/services/statistik_export_service.dart';
import 'package:taugts/features/datenaustausch/services/binaer_export_ziel_service.dart';

class AuswertungenScreen extends StatefulWidget {
  const AuswertungenScreen({
    required this.service,
    this.statistikExportService,
    this.exportZielService,
    this.excelService = const StatistikExcelService(),
    super.key,
  });

  final AuswertungsService service;
  final StatistikExportService? statistikExportService;
  final BinaerExportZielService? exportZielService;
  final StatistikExcelService excelService;

  @override
  State<AuswertungenScreen> createState() => _AuswertungenScreenState();
}

class _AuswertungenScreenState extends State<AuswertungenScreen> {
  var _filter = const AuswertungsFilter();
  late Future<AuswertungsUebersicht> _daten = widget.service.berechne(_filter);
  var _exportLaeuft = false;

  void _neuLaden() => setState(() {
        _daten = widget.service.berechne(_filter);
      });

  void _filterZuruecksetzen() => setState(() {
        _filter = const AuswertungsFilter();
        _daten = widget.service.berechne(_filter);
      });

  Future<void> _zeitraumWaehlen() async {
    final jetzt = DateTime.now();
    final initial = _filter.von != null && _filter.bis != null
        ? DateTimeRange(start: _filter.von!, end: _filter.bis!)
        : null;
    final zeitraum = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(jetzt.year + 1, 12, 31),
      initialDateRange: initial,
      helpText: 'Zeitraum für die Auswertung wählen',
      cancelText: 'Abbrechen',
      confirmText: 'Übernehmen',
    );
    if (!mounted || zeitraum == null) return;
    setState(() {
      _filter = AuswertungsFilter(
        von: zeitraum.start,
        bis: DateTime(
          zeitraum.end.year,
          zeitraum.end.month,
          zeitraum.end.day,
          23,
          59,
          59,
          999,
        ),
      );
      _daten = widget.service.berechne(_filter);
    });
  }

  Future<void> _exportieren() async {
    final statistikExportService = widget.statistikExportService;
    final exportZielService = widget.exportZielService;
    if (_exportLaeuft ||
        statistikExportService == null ||
        exportZielService == null) {
      return;
    }

    setState(() => _exportLaeuft = true);
    try {
      final daten = await statistikExportService.ladeDaten();
      if (!mounted) return;
      if (!daten.hatAuswertbareWertungen) {
        _meldung(
          'Für den Excel-Export sind noch keine Qualitätswertungen vorhanden.',
        );
        return;
      }

      final datei = widget.excelService.erstelle(daten);
      final ziel = await exportZielService.speichern(
        dateiname: datei.dateiname,
        inhalt: datei.inhalt,
        dateiendung: 'xlsx',
      );
      if (!mounted) return;
      _meldung(
        ziel == null
            ? 'Excel-Export abgebrochen.'
            : 'Excel-Export gespeichert: ${datei.dateiname}',
      );
    } catch (_) {
      if (!mounted) return;
      _meldung('Excel-Export fehlgeschlagen. Bitte erneut versuchen.');
    } finally {
      if (mounted) {
        setState(() => _exportLaeuft = false);
      }
    }
  }

  void _meldung(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Auswertungen'),
          actions: const [
            AppSupportMenu(contextName: SupportKontexte.auswertungen),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<AuswertungsUebersicht>(
            future: _daten,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: FilledButton.icon(
                    onPressed: _neuLaden,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Auswertungen erneut laden'),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return Semantics(
                  label: 'Auswertungen werden berechnet',
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              final daten = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  const Text(
                    'Alle Berechnungen erfolgen lokal. Mittelwerte werden nur für Qualitätswertungen derselben Kriterienversion gebildet; fehlende Werte werden ausgelassen.',
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _zeitraumWaehlen,
                            icon: const Icon(Icons.date_range),
                            label: const Text('Zeitraum wählen'),
                          ),
                          if (_filter.von != null)
                            Text(
                              '${_filter.von!.toLocal().toString().split(' ').first} bis ${_filter.bis!.toLocal().toString().split(' ').first}',
                            ),
                          TextButton(
                            onPressed: _filter.von == null
                                ? null
                                : _filterZuruecksetzen,
                            child: const Text('Filter zurücksetzen'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.statistikExportService != null &&
                      widget.exportZielService != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: FilledButton.icon(
                        onPressed: _exportLaeuft ? null : _exportieren,
                        icon: _exportLaeuft
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.table_view_outlined),
                        label: Text(
                          _exportLaeuft
                              ? 'Excel-Export wird erstellt'
                              : 'Exportieren',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Der Excel-Export enthält Produktbewertungen, Ortsbewertungen und einen Ortsverlauf mit Liniendiagramm.',
                    ),
                  ],
                  const SizedBox(height: 16),
                  _Karte(
                    titel: 'Bewertungen',
                    zeilen: [
                      '${daten.bewertungsanzahl} gespeicherte Kriterienwerte'
                    ],
                  ),
                  _Karte(
                    titel: 'Vergleichbare Durchschnittswerte',
                    zeilen: [
                      for (final wert in daten.durchschnitte)
                        '${wert.kriterium} · Version ${wert.kriteriumVersion}: ${wert.durchschnitt.toStringAsFixed(2)} aus ${wert.anzahl} Werten',
                    ],
                  ),
                  _Karte(
                    titel: 'Preisentwicklung nach Ort',
                    zeilen: [
                      for (final wert in daten.preisverlauf)
                        '${wert.zeitpunkt.toLocal()}: ${wert.wert.toStringAsFixed(2)} · ${wert.beschreibung}',
                    ],
                    verlauf: daten.preisverlauf,
                  ),
                  _Karte(
                    titel: 'Qualitätsverlauf von Produkten',
                    zeilen: [
                      for (final wert in daten.qualitaetsverlauf)
                        '${wert.zeitpunkt.toLocal()}: ${wert.wert} · ${wert.beschreibung}',
                    ],
                    verlauf: daten.qualitaetsverlauf,
                  ),
                  _Karte(
                    titel: 'Ortsbewertungen im Zeitverlauf',
                    zeilen: [
                      for (final wert in daten.ortsverlauf)
                        '${wert.zeitpunkt.toLocal()}: ${wert.wert} · ${wert.beschreibung}',
                    ],
                    verlauf: daten.ortsverlauf,
                  ),
                  _Karte(
                    titel: 'Erlebnisse nach Typ, Wochentag und Tageszeit',
                    zeilen: [
                      for (final gruppe in daten.erlebnisgruppen)
                        '${gruppe.schluessel}: ${gruppe.anzahl} Erlebnisse, ${gruppe.gesamtdauerMinuten} Minuten Gesamtdauer',
                    ],
                  ),
                  _Karte(
                    titel: 'Andrang / Auslastung',
                    zeilen: [
                      for (final wert in daten.andrangBeobachtungen)
                        '${wert.zeitpunkt.toLocal()}: ${wert.wert} · ${wert.beschreibung}',
                    ],
                    verlauf: daten.andrangBeobachtungen,
                  ),
                  const Text(
                    'Zeitliche Zusammenhänge werden als Beobachtung dargestellt. Aus Uhrzeit oder Wochentag wird kein Andrang abgeleitet und keine Ursache behauptet.',
                  ),
                ],
              );
            },
          ),
        ),
      );
}

class _Karte extends StatelessWidget {
  const _Karte({
    required this.titel,
    required this.zeilen,
    this.verlauf,
  });

  final String titel;
  final List<String> zeilen;
  final List<Zeitwert>? verlauf;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child:
                    Text(titel, style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              if (zeilen.isEmpty)
                const Text('Noch keine passenden Daten vorhanden.')
              else
                for (final zeile in zeilen)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(zeile),
                  ),
              if (verlauf != null) ...[
                const SizedBox(height: 12),
                StatistikVerlaufDarstellung(daten: verlauf!),
              ],
            ],
          ),
        ),
      );
}
