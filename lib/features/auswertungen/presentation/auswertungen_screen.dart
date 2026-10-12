import 'package:flutter/material.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';
import 'package:taugts/features/auswertungen/presentation/statistik_verlauf_darstellung.dart';
import 'package:taugts/features/auswertungen/services/auswertungs_service.dart';
import 'package:taugts/features/auswertungen/services/statistik_excel_service.dart';
import 'package:taugts/features/auswertungen/services/statistik_export_service.dart';
import 'package:taugts/features/datenaustausch/services/binaer_export_ziel_service.dart';

enum _StatistikAnsicht {
  preise('Preise'),
  ausgaben('Einkaufskosten'),
  produktqualitaet('Produktqualität'),
  ortsqualitaet('Ortsqualität'),
  andrang('Andrang'),
  auffaelligkeiten('Bewertungsauffälligkeiten'),
  qualitaetsvergleich('Produkt- und Ortsbewertungen vergleichen'),
  preisQualitaet('Preis und Qualität'),
  haeufigkeit('Besuchshäufigkeit');

  const _StatistikAnsicht(this.titel);

  final String titel;

  List<Zeitwert> werte(AuswertungsUebersicht daten) => switch (this) {
        _StatistikAnsicht.preise => daten.preisverlauf,
        _StatistikAnsicht.ausgaben => daten.ausgabenverlauf,
        _StatistikAnsicht.produktqualitaet => daten.qualitaetsverlauf,
        _StatistikAnsicht.ortsqualitaet => daten.ortsverlauf,
        _StatistikAnsicht.andrang => daten.andrangBeobachtungen,
        _StatistikAnsicht.auffaelligkeiten => daten.auffaelligkeiten,
        _StatistikAnsicht.qualitaetsvergleich => [
            ...daten.qualitaetsverlauf,
            ...daten.ortsverlauf,
          ],
        _StatistikAnsicht.preisQualitaet => [
            ...daten.preisverlauf,
            ...daten.qualitaetsverlauf,
            ...daten.ortsverlauf,
          ],
        _StatistikAnsicht.haeufigkeit => daten.besuchverlauf,
      };
}

class AuswertungenScreen extends StatefulWidget {
  const AuswertungenScreen({
    required this.service,
    this.statistikExportService,
    this.exportZielService,
    this.excelService = const StatistikExcelService(),
    this.onErlebnisOeffnen,
    super.key,
  });

  final AuswertungsService service;
  final StatistikExportService? statistikExportService;
  final BinaerExportZielService? exportZielService;
  final StatistikExcelService excelService;
  final ValueChanged<String>? onErlebnisOeffnen;

  @override
  State<AuswertungenScreen> createState() => _AuswertungenScreenState();
}

class _AuswertungenScreenState extends State<AuswertungenScreen> {
  var _filter = const AuswertungsFilter();
  var _ansicht = _StatistikAnsicht.preise;
  var _aggregation = StatistikZeitraum.monat;
  late Future<AuswertungsUebersicht> _daten = widget.service.berechne(_filter);
  late Future<AuswertungsFilterOptionen> _filterOptionen =
      _ladeFilterOptionen();
  var _exportLaeuft = false;

  Future<AuswertungsFilterOptionen> _ladeFilterOptionen() async {
    final service = widget.service;
    if (service is AuswertungsFilterOptionenService) {
      return (service as AuswertungsFilterOptionenService).ladeFilterOptionen();
    }
    return const AuswertungsFilterOptionen(
      produkte: [],
      orte: [],
      kategorien: [],
      kriterien: [],
    );
  }

  void _filterAnwenden({
    String? kategorieId,
    bool kategorieAendern = false,
    String? objektId,
    StatistikObjektart? objektArt,
    bool objektAendern = false,
    String? kriteriumId,
    bool kriteriumAendern = false,
  }) {
    setState(() {
      _filter = AuswertungsFilter(
        von: _filter.von,
        bis: _filter.bis,
        herkunftProfilId: _filter.herkunftProfilId,
        kategorieId: kategorieAendern ? kategorieId : _filter.kategorieId,
        objektId: objektAendern ? objektId : _filter.objektId,
        objektArt: objektAendern ? objektArt! : _filter.objektArt,
        kriteriumId: kriteriumAendern ? kriteriumId : _filter.kriteriumId,
      );
      _daten = widget.service.berechne(_filter);
    });
  }

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

  List<Zeitwert> _auswertungsPunkte(AuswertungsUebersicht daten) {
    final werte = _ansicht.werte(daten);
    final einzelBeobachtungen =
        _ansicht == _StatistikAnsicht.auffaelligkeiten ||
            (_ansicht == _StatistikAnsicht.preise &&
                _filter.objektArt == StatistikObjektart.ort &&
                _aggregation == StatistikZeitraum.tag);
    if (einzelBeobachtungen) return werte;
    return StatistikRechnung.aggregiere(
      werte,
      _aggregation,
      summieren: _ansicht == _StatistikAnsicht.ausgaben ||
          _ansicht == _StatistikAnsicht.haeufigkeit,
    );
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
      final exportDaten = await statistikExportService.ladeDaten();
      final auswertungsDaten = await _daten;
      final verlauf = _auswertungsPunkte(auswertungsDaten);
      final optionen = await _filterOptionen;
      if (!mounted) return;
      if (!exportDaten.hatAuswertbareWertungen && verlauf.isEmpty) {
        _meldung('Für den Excel-Export liegen keine passenden Daten vor.');
        return;
      }

      final datei = widget.excelService.erstelle(
        exportDaten,
        zeitreihe: verlauf,
        statistikTitel: _ansicht.titel,
        filter: _filter,
        gruppierung: _aggregation,
        filterOptionen: optionen,
      );
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

  Widget _preisExtrema(List<Zeitwert> werte) {
    final nachWaehrung = <String, List<Zeitwert>>{};
    for (final wert in werte) {
      final waehrung = wert.serie?.split(' · ').last ?? '';
      nachWaehrung.putIfAbsent(waehrung, () => []).add(wert);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Beobachtete Preise im Zeitraum',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final eintrag in nachWaehrung.entries) ...[
              const SizedBox(height: 8),
              Text(
                'Währung: ${eintrag.key}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final (titel, istMinimum) in [
                ('Günstigster beobachteter Preis', true),
                ('Teuerster beobachteter Preis', false),
              ])
                _preisExtremZeile(eintrag.value, titel, istMinimum),
            ],
            if (nachWaehrung.isEmpty)
              const Text('Für diesen Zeitraum liegen keine Preise vor.'),
          ],
        ),
      ),
    );
  }

  Widget _preisExtremZeile(
    List<Zeitwert> werte,
    String titel,
    bool minimum,
  ) {
    if (werte.isEmpty) return const SizedBox.shrink();
    final extrem = werte
        .map((wert) => wert.wert)
        .reduce(minimum ? (a, b) => a < b ? a : b : (a, b) => a > b ? a : b);
    final passende = werte.where((wert) => wert.wert == extrem).toList();
    final orte = passende.map((wert) => wert.beschreibung).toSet().join('; ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$titel: ${extrem.toStringAsFixed(2)} · $orte'),
    );
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Auswertungen konnten nicht geladen werden.',
                      ),
                      FilledButton.icon(
                        onPressed: _neuLaden,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Erneut laden'),
                      ),
                    ],
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
              final punkte = _auswertungsPunkte(daten);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  const Text(
                    'Alle Berechnungen erfolgen lokal. Mittelwerte werden nur für Qualitätswertungen derselben Kriterienversion gebildet; fehlende Werte werden ausgelassen.',
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<_StatistikAnsicht>(
                            initialValue: _ansicht,
                            decoration: const InputDecoration(
                              labelText: 'Statistik',
                            ),
                            items: [
                              for (final ansicht in _StatistikAnsicht.values)
                                DropdownMenuItem(
                                  value: ansicht,
                                  child: Text(ansicht.titel),
                                ),
                            ],
                            onChanged: (wert) {
                              if (wert == null) return;
                              setState(() => _ansicht = wert);
                            },
                          ),
                          DropdownButtonFormField<StatistikZeitraum>(
                            initialValue: _aggregation,
                            decoration: const InputDecoration(
                              labelText: 'Gruppierung',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: StatistikZeitraum.tag,
                                child: Text('Tag'),
                              ),
                              DropdownMenuItem(
                                value: StatistikZeitraum.woche,
                                child: Text('Woche'),
                              ),
                              DropdownMenuItem(
                                value: StatistikZeitraum.monat,
                                child: Text('Monat'),
                              ),
                              DropdownMenuItem(
                                value: StatistikZeitraum.jahr,
                                child: Text('Jahr'),
                              ),
                            ],
                            onChanged: (wert) {
                              if (wert == null) return;
                              setState(() => _aggregation = wert);
                            },
                          ),
                          FutureBuilder<AuswertungsFilterOptionen>(
                            future: _filterOptionen,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return TextButton.icon(
                                  onPressed: () => setState(() {
                                    _filterOptionen = _ladeFilterOptionen();
                                  }),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text(
                                    'Filteroptionen erneut laden',
                                  ),
                                );
                              }
                              if (!snapshot.hasData) {
                                return Semantics(
                                  label: 'Filteroptionen werden geladen',
                                  child: LinearProgressIndicator(),
                                );
                              }
                              final optionen = snapshot.data!;
                              return Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    initialValue: _filter.objektArt ==
                                            StatistikObjektart.produkt
                                        ? _filter.objektId
                                        : null,
                                    decoration: const InputDecoration(
                                      labelText: 'Produkt',
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Alle Produkte'),
                                      ),
                                      for (final option in optionen.produkte)
                                        DropdownMenuItem(
                                          value: option.id,
                                          child: Text(option.bezeichnung),
                                        ),
                                    ],
                                    onChanged: (id) => _filterAnwenden(
                                      objektId: id,
                                      objektArt: StatistikObjektart.produkt,
                                      objektAendern: true,
                                    ),
                                  ),
                                  DropdownButtonFormField<String>(
                                    initialValue: _filter.objektArt ==
                                            StatistikObjektart.ort
                                        ? _filter.objektId
                                        : null,
                                    decoration: const InputDecoration(
                                      labelText: 'Ort',
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Alle Orte'),
                                      ),
                                      for (final option in optionen.orte)
                                        DropdownMenuItem(
                                          value: option.id,
                                          child: Text(option.bezeichnung),
                                        ),
                                    ],
                                    onChanged: (id) => _filterAnwenden(
                                      objektId: id,
                                      objektArt: StatistikObjektart.ort,
                                      objektAendern: true,
                                    ),
                                  ),
                                  DropdownButtonFormField<String>(
                                    initialValue: _filter.kategorieId,
                                    decoration: const InputDecoration(
                                      labelText: 'Kategorie',
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Alle Kategorien'),
                                      ),
                                      for (final option in optionen.kategorien)
                                        DropdownMenuItem(
                                          value: option.id,
                                          child: Text(option.bezeichnung),
                                        ),
                                    ],
                                    onChanged: (id) => _filterAnwenden(
                                      kategorieId: id,
                                      kategorieAendern: true,
                                    ),
                                  ),
                                  DropdownButtonFormField<String>(
                                    initialValue: _filter.kriteriumId,
                                    decoration: const InputDecoration(
                                      labelText: 'Kriterium',
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Alle Kriterien'),
                                      ),
                                      for (final option in optionen.kriterien)
                                        DropdownMenuItem(
                                          value: option.id,
                                          child: Text(option.bezeichnung),
                                        ),
                                    ],
                                    onChanged: (id) => _filterAnwenden(
                                      kriteriumId: id,
                                      kriteriumAendern: true,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Wrap(
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
                      'Der Excel-Export enthält Produkt- und Ortsbewertungen, den Ortsverlauf sowie die aktuell gefilterte Zeitreihe mit Metadaten.',
                    ),
                  ],
                  const SizedBox(height: 16),
                  _Karte(
                    titel: _ansicht.titel,
                    zeilen: [
                      for (final wert in punkte)
                        '${wert.zeitpunkt.toLocal()}: ${wert.wert.toStringAsFixed(2)} · ${wert.beschreibung}',
                    ],
                    verlauf: punkte,
                    onErlebnisOeffnen: widget.onErlebnisOeffnen,
                  ),
                  if (_ansicht == _StatistikAnsicht.preise &&
                      _filter.objektArt == StatistikObjektart.produkt &&
                      _filter.objektId != null)
                    _preisExtrema(daten.preisverlauf),
                  if (_ansicht == _StatistikAnsicht.preisQualitaet)
                    const Text(
                      'Preise und Wertungen werden in getrennten Diagrammreihen und eigenen Skalen dargestellt. Der Verlauf zeigt keine Ursache-Wirkung-Beziehung.',
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
    this.onErlebnisOeffnen,
  });

  final String titel;
  final List<String> zeilen;
  final List<Zeitwert>? verlauf;
  final ValueChanged<String>? onErlebnisOeffnen;

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
              if (verlauf == null)
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
                StatistikVerlaufDarstellung(
                  daten: verlauf!,
                  onErlebnisOeffnen: onErlebnisOeffnen,
                ),
              ],
            ],
          ),
        ),
      );
}
