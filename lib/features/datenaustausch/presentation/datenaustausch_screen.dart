import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/features/datenaustausch/services/export_service.dart';
import 'package:taugts/features/datenaustausch/services/export_ziel_service.dart';
import 'package:taugts/features/datenaustausch/services/import_konfliktanalyse_service.dart';
import 'package:taugts/features/datenaustausch/services/import_konfliktentscheidung_service.dart';
import 'package:taugts/features/datenaustausch/services/import_quelle_service.dart';
import 'package:taugts/features/datenaustausch/services/import_strategie_service.dart';
import 'package:taugts/features/datenaustausch/services/import_validierungs_service.dart';

class DatenaustauschScreen extends StatefulWidget {
  const DatenaustauschScreen({
    required this.exportService,
    required this.exportZielService,
    this.importQuelleService,
    this.importValidierungsService = const ImportValidierungsService(),
    this.importKonfliktanalyseService = const ImportKonfliktanalyseService(),
    this.importStrategieService = const ImportStrategieService(),
    this.importKonfliktentscheidungService = const ImportKonfliktentscheidungService(),
    super.key,
  });

  final ExportService exportService;
  final ExportZielService exportZielService;
  final ImportQuelleService? importQuelleService;
  final ImportValidierungsService importValidierungsService;
  final ImportKonfliktanalyseService importKonfliktanalyseService;
  final ImportStrategieService importStrategieService;
  final ImportKonfliktentscheidungService importKonfliktentscheidungService;

  @override
  State<DatenaustauschScreen> createState() => _DatenaustauschScreenState();
}

class _DatenaustauschScreenState extends State<DatenaustauschScreen> {
  bool _laeuft = false;
  String? _status;
  bool _istFehler = false;
  ImportKonfliktAnalyse? _analyse;
  ImportStrategie _strategie = ImportStrategie.importBevorzugen;
  ImportStrategiePlan? _strategiePlan;
  Map<String, Object?>? _importDokument;
  Map<String, Object?>? _lokalesDokument;
  List<ImportValidierungsFehler> _importFehler = const [];
  List<ImportEinzelKonflikt> _konflikte = const [];
  ImportKonfliktEntscheidungsStand _entscheidungsStand =
      const ImportKonfliktEntscheidungsStand();
  final Set<String> _aufTypAnwenden = <String>{};
  bool _konflikteBearbeiten = false;

  String _dateiname() {
    final jetzt = DateTime.now().toUtc();
    String zwei(int wert) => wert.toString().padLeft(2, '0');
    return 'taugts-export-${jetzt.year}-${zwei(jetzt.month)}-${zwei(jetzt.day)}-${zwei(jetzt.hour)}${zwei(jetzt.minute)}.json';
  }

  Future<void> _speichern() async {
    await _ausfuehren(() async {
      final dateiname = _dateiname();
      final pfad = await widget.exportZielService.speichern(
        dateiname: dateiname,
        inhalt: widget.exportService.erzeugeJson(),
      );
      if (pfad == null) return 'Speichern abgebrochen.';
      return 'Export gespeichert: $dateiname';
    });
  }

  Future<void> _teilen() async {
    await _ausfuehren(() async {
      final dateiname = _dateiname();
      await widget.exportZielService.teilen(
        dateiname: dateiname,
        inhalt: widget.exportService.erzeugeJson(),
      );
      return 'Teilen-Dialog geöffnet: $dateiname';
    });
  }

  Future<void> _sicherungExportieren() async {
    await _ausfuehren(() async {
      final dateiname = 'sicherung-${_dateiname()}';
      final pfad = await widget.exportZielService.speichern(
        dateiname: dateiname,
        inhalt: widget.exportService.erzeugeJson(),
      );
      return pfad == null
          ? 'Sicherungsexport abgebrochen.'
          : 'Sicherungsexport gespeichert: $dateiname';
    });
  }

  Future<void> _importPruefen() async {
    final quelle = widget.importQuelleService ?? SystemImportQuelleService();
    setState(() {
      _laeuft = true;
      _status = null;
      _istFehler = false;
      _analyse = null;
      _strategiePlan = null;
      _importDokument = null;
      _lokalesDokument = null;
      _importFehler = const [];
      _konflikte = const [];
      _entscheidungsStand = const ImportKonfliktEntscheidungsStand();
      _aufTypAnwenden.clear();
      _konflikteBearbeiten = false;
    });
    try {
      final inhalt = await quelle.dateiAuswaehlen();
      if (!mounted) return;
      if (inhalt == null) {
        setState(() => _status = 'Dateiauswahl abgebrochen.');
        return;
      }
      final validierung = widget.importValidierungsService.validiere(inhalt);
      if (!validierung.istGueltig) {
        setState(() {
          _istFehler = true;
          _status =
              'Die Importdatei ist nicht gültig. Es wurden keine Daten verändert.';
          _importFehler = validierung.fehler;
        });
        return;
      }
      final lokal = Map<String, Object?>.from(
        jsonDecode(widget.exportService.erzeugeJson()) as Map,
      );
      final analyse = widget.importKonfliktanalyseService.analysiere(
        importDokument: validierung.dokument!,
        lokalesDokument: lokal,
      );
      final konflikte = widget.importKonfliktentscheidungService.ermittle(
        importDokument: validierung.dokument!,
        lokalesDokument: lokal,
        analyse: analyse,
      );
      setState(() {
        _analyse = analyse;
        _importDokument = validierung.dokument!;
        _lokalesDokument = lokal;
        _strategiePlan = _planeStrategie(analyse);
        _konflikte = konflikte;
        _status = 'Import geprüft. Die Vorschau verändert keine lokalen Daten.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _istFehler = true;
        _status =
            'Die Importdatei konnte nicht geprüft werden. Die lokalen Daten wurden nicht verändert.';
      });
    } finally {
      if (mounted) setState(() => _laeuft = false);
    }
  }

  ImportStrategiePlan _planeStrategie(ImportKonfliktAnalyse analyse) =>
      widget.importStrategieService.plane(
        strategie: _strategie,
        importDokument: _importDokument!,
        lokalesDokument: _lokalesDokument!,
        fachlicheDubletten: analyse.fachlicheDubletten.map(
          (d) => FachlicheDubletteHinweis(
            sammlung: d.sammlung,
            importId: d.importId,
            lokaleId: d.lokaleId,
          ),
        ),
      );

  void _strategieAendern(ImportStrategie? strategie) {
    if (strategie == null || _analyse == null) return;
    setState(() {
      _strategie = strategie;
      _strategiePlan = _planeStrategie(_analyse!);
    });
  }

  void _entscheidungAendern(
    ImportEinzelKonflikt konflikt,
    ImportKonfliktAktion? aktion,
  ) {
    if (aktion == null) return;
    setState(() {
      _entscheidungsStand = widget.importKonfliktentscheidungService.entscheide(
        stand: _entscheidungsStand,
        konflikt: konflikt,
        aktion: aktion,
        alleKonflikte: _konflikte,
        aufGleichenTypAnwenden: _aufTypAnwenden.contains(konflikt.schluessel),
      );
    });
  }

  Future<void> _ausfuehren(Future<String> Function() aktion) async {
    setState(() {
      _laeuft = true;
      _status = null;
      _istFehler = false;
    });
    try {
      final status = await aktion();
      if (!mounted) return;
      setState(() => _status = status);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _istFehler = true;
        _status =
            'Der Export konnte nicht abgeschlossen werden. Die lokalen Daten wurden nicht verändert.';
      });
    } finally {
      if (mounted) setState(() => _laeuft = false);
    }
  }

  String _strategieName(ImportStrategie strategie) => switch (strategie) {
        ImportStrategie.bestandErsetzen => 'Bestand ersetzen',
        ImportStrategie.importBevorzugen => 'Import bevorzugen',
        ImportStrategie.lokalBevorzugen => 'Lokalen Bestand bevorzugen',
      };

  String _aktionsName(ImportKonfliktAktion aktion) => switch (aktion) {
        ImportKonfliktAktion.lokaleVersion => 'Lokale Version',
        ImportKonfliktAktion.importVersion => 'Importversion',
        ImportKonfliktAktion.ueberspringen => 'Überspringen',
        ImportKonfliktAktion.beideBehalten => 'Beide behalten',
        ImportKonfliktAktion.zusammenfuehren => 'Zusammenführen',
      };

  String _konfliktArtName(ImportKonfliktArt art) => switch (art) {
        ImportKonfliktArt.versionskonflikt => 'Versionskonflikt',
        ImportKonfliktArt.identitaetskonflikt => 'Identitätskonflikt',
        ImportKonfliktArt.fachlicheDublette => 'Mögliche fachliche Dublette',
      };

  String _wertText(Object? wert) {
    if (wert == null) return '—';
    if (wert is Map || wert is List) return jsonEncode(wert);
    return wert.toString();
  }

  Widget _buildImportVorschau(BuildContext context) {
    final plan = _strategiePlan!;
    final analyse = _analyse!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            'Importvorschau',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Noch nicht importiert. Wähle, wie vorhandene Daten bei einer späteren Bestätigung behandelt werden sollen.',
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ImportStrategie>(
          initialValue: _strategie,
          decoration: const InputDecoration(labelText: 'Importstrategie'),
          items: ImportStrategie.values
              .map(
                (strategie) => DropdownMenuItem(
                  value: strategie,
                  child: Text(_strategieName(strategie)),
                ),
              )
              .toList(),
          onChanged: _strategieAendern,
        ),
        if (_strategie == ImportStrategie.bestandErsetzen) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              'Warnung: Nicht in der Importdatei enthaltene lokale Datensätze würden gelöscht.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _laeuft ? null : _sicherungExportieren,
            icon: const Icon(Icons.backup_outlined),
            label: const Text('Vorher Sicherung exportieren'),
          ),
        ],
        const SizedBox(height: 12),
        for (final sammlung in plan.sammlungen.where(
          (s) => s.hinzufuegen + s.aktualisieren + s.entfernen > 0,
        ))
          Card(
            child: ListTile(
              title: Text(sammlung.name),
              subtitle: Text(
                '${sammlung.hinzufuegen} hinzufügen · ${sammlung.aktualisieren} aktualisieren · ${sammlung.behalten} behalten · ${sammlung.entfernen} entfernen',
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Herkunft: ${analyse.eigeneHerkunft} eigene · ${analyse.fremdeHerkunft} fremde Erlebnisse',
        ),
        if (_konflikte.isNotEmpty) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              '${_konflikte.length} Konflikt${_konflikte.length == 1 ? '' : 'e'} benötigen eine Einzelentscheidung.',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => setState(() => _konflikteBearbeiten = true),
            icon: const Icon(Icons.rule_outlined),
            label: const Text('Konflikte einzeln entscheiden'),
          ),
        ],
      ],
    );
  }

  Widget _buildKonfliktBearbeitung(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(
              'Importkonflikte entscheiden',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Diese Entscheidungen sind nur Teil der Vorschau. Solange der Import nicht ausdrücklich bestätigt wird, werden keine lokalen Daten verändert.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _konflikteBearbeiten = false),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Zurück zur Importvorschau'),
          ),
          const SizedBox(height: 16),
          for (final konflikt in _konflikte) _buildKonfliktKarte(context, konflikt),
          Semantics(
            liveRegion: true,
            child: Text(
              '${_entscheidungsStand.entscheidungen.length} von ${_konflikte.length} Konflikten entschieden.',
            ),
          ),
        ],
      );

  Widget _buildKonfliktKarte(
    BuildContext context,
    ImportEinzelKonflikt konflikt,
  ) {
    final entscheidung = _entscheidungsStand.fuer(konflikt);
    final kontext = konflikt.kontext;
    final kontextTeile = <String>[
      if (kontext.objektId != null) 'Objekt: ${kontext.objektId}',
      if (kontext.erlebnisId != null) 'Erlebnis: ${kontext.erlebnisId}',
      if (kontext.ortId != null) 'Ort: ${kontext.ortId}',
      if (kontext.zeitpunkt != null) 'Zeitpunkt: ${kontext.zeitpunkt}',
    ];

    return Semantics(
      container: true,
      label: '${_konfliktArtName(konflikt.art)} in ${konflikt.sammlung}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _konfliktArtName(konflikt.art),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text('${konflikt.sammlung} · Import ${konflikt.importId} · lokal ${konflikt.lokaleId}'),
              if (kontextTeile.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(kontextTeile.join(' · ')),
              ],
              if (konflikt.art == ImportKonfliktArt.identitaetskonflikt) ...[
                const SizedBox(height: 8),
                Text(
                  'Die stabile ID verweist auf unterschiedliche historische Kontexte. „Beide behalten“ wird deshalb nicht angeboten.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (konflikt.unterschiede.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Unterschiede', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                for (final unterschied in konflikt.unterschiede)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${unterschied.feld}: lokal „${_wertText(unterschied.lokal)}“ · Import „${_wertText(unterschied.import)}“',
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              DropdownButtonFormField<ImportKonfliktAktion>(
                key: ValueKey('entscheidung-${konflikt.schluessel}-$entscheidung'),
                initialValue: entscheidung,
                decoration: const InputDecoration(labelText: 'Entscheidung'),
                hint: const Text('Bitte auswählen'),
                items: konflikt.erlaubteAktionen
                    .map(
                      (aktion) => DropdownMenuItem(
                        value: aktion,
                        child: Text(_aktionsName(aktion)),
                      ),
                    )
                    .toList(),
                onChanged: (aktion) => _entscheidungAendern(konflikt, aktion),
              ),
              const SizedBox(height: 4),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auf weitere Konflikte dieses Typs anwenden'),
                value: _aufTypAnwenden.contains(konflikt.schluessel),
                onChanged: (wert) {
                  setState(() {
                    if (wert ?? false) {
                      _aufTypAnwenden.add(konflikt.schluessel);
                    } else {
                      _aufTypAnwenden.remove(konflikt.schluessel);
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Import/Export'),
          actions: const [AppSupportMenu(contextName: 'Datenaustausch')],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Gesamtdaten exportieren',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Erstellt eine vollständige JSON-Datei mit deinen lokal gespeicherten Daten. Der Export funktioniert ohne Server und verändert deine Daten nicht.',
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _laeuft ? null : _speichern,
                icon: const Icon(Icons.save_alt),
                label: const Text('Export speichern'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _laeuft ? null : _teilen,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Export teilen'),
              ),
              const SizedBox(height: 28),
              Semantics(
                header: true,
                child: Text(
                  'Import prüfen',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Wähle eine Taugt’s?-Exportdatei aus. Sie wird validiert und mit deinen lokalen Daten verglichen. Vor einer späteren ausdrücklichen Importbestätigung wird nichts gespeichert.',
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: _laeuft ? null : _importPruefen,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Importdatei auswählen und prüfen'),
              ),
              if (_laeuft) ...[
                const SizedBox(height: 20),
                Semantics(
                  label: 'Datenaustausch wird vorbereitet',
                  child: const LinearProgressIndicator(),
                ),
              ],
              if (_status != null) ...[
                const SizedBox(height: 20),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _status!,
                    style: _istFehler
                        ? TextStyle(color: Theme.of(context).colorScheme.error)
                        : null,
                  ),
                ),
              ],
              if (_importFehler.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final fehler in _importFehler.take(10))
                  Text('• ${fehler.pfad}: ${fehler.nachricht}'),
              ],
              if (_analyse != null && _strategiePlan != null)
                if (_konflikteBearbeiten)
                  _buildKonfliktBearbeitung(context)
                else
                  _buildImportVorschau(context),
            ],
          ),
        ),
      );
}
