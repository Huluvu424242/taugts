import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/features/datenaustausch/services/export_service.dart';
import 'package:taugts/features/datenaustausch/services/export_ziel_service.dart';
import 'package:taugts/features/datenaustausch/services/import_konfliktanalyse_service.dart';
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
    super.key,
  });

  final ExportService exportService;
  final ExportZielService exportZielService;
  final ImportQuelleService? importQuelleService;
  final ImportValidierungsService importValidierungsService;
  final ImportKonfliktanalyseService importKonfliktanalyseService;
  final ImportStrategieService importStrategieService;

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

  String _dateiname() {
    final jetzt = DateTime.now().toUtc();
    String zwei(int wert) => wert.toString().padLeft(2, '0');
    return 'taugts-export-${jetzt.year}-${zwei(jetzt.month)}-${zwei(jetzt.day)}-${zwei(jetzt.hour)}${zwei(jetzt.minute)}.json';
  }

  Future<void> _speichern() async {
    await _ausfuehren(() async {
      final dateiname = _dateiname();
      final pfad = await widget.exportZielService.speichern(dateiname: dateiname, inhalt: widget.exportService.erzeugeJson());
      if (pfad == null) return 'Speichern abgebrochen.';
      return 'Export gespeichert: $dateiname';
    });
  }

  Future<void> _teilen() async {
    await _ausfuehren(() async {
      final dateiname = _dateiname();
      await widget.exportZielService.teilen(dateiname: dateiname, inhalt: widget.exportService.erzeugeJson());
      return 'Teilen-Dialog geöffnet: $dateiname';
    });
  }

  Future<void> _sicherungExportieren() async {
    await _ausfuehren(() async {
      final dateiname = 'sicherung-${_dateiname()}';
      final pfad = await widget.exportZielService.speichern(dateiname: dateiname, inhalt: widget.exportService.erzeugeJson());
      return pfad == null ? 'Sicherungsexport abgebrochen.' : 'Sicherungsexport gespeichert: $dateiname';
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
          _status = 'Die Importdatei ist nicht gültig. Es wurden keine Daten verändert.';
          _importFehler = validierung.fehler;
        });
        return;
      }
      final lokal = Map<String, Object?>.from(jsonDecode(widget.exportService.erzeugeJson()) as Map);
      final analyse = widget.importKonfliktanalyseService.analysiere(importDokument: validierung.dokument!, lokalesDokument: lokal);
      setState(() {
        _analyse = analyse;
        _importDokument = validierung.dokument!;
        _lokalesDokument = lokal;
        _strategiePlan = _planeStrategie(analyse);
        _status = 'Import geprüft. Die Vorschau verändert keine lokalen Daten.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _istFehler = true;
        _status = 'Die Importdatei konnte nicht geprüft werden. Die lokalen Daten wurden nicht verändert.';
      });
    } finally {
      if (mounted) setState(() => _laeuft = false);
    }
  }

  ImportStrategiePlan _planeStrategie(ImportKonfliktAnalyse analyse) => widget.importStrategieService.plane(
        strategie: _strategie,
        importDokument: _importDokument!,
        lokalesDokument: _lokalesDokument!,
        fachlicheDubletten: analyse.fachlicheDubletten.map((d) => FachlicheDubletteHinweis(sammlung: d.sammlung, importId: d.importId, lokaleId: d.lokaleId)),
      );

  void _strategieAendern(ImportStrategie? strategie) {
    if (strategie == null || _analyse == null) return;
    setState(() {
      _strategie = strategie;
      _strategiePlan = _planeStrategie(_analyse!);
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
        _status = 'Der Export konnte nicht abgeschlossen werden. Die lokalen Daten wurden nicht verändert.';
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Import/Export'), actions: const [AppSupportMenu(contextName: 'Datenaustausch')]),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Semantics(header: true, child: Text('Gesamtdaten exportieren', style: Theme.of(context).textTheme.headlineSmall)),
              const SizedBox(height: 12),
              const Text('Erstellt eine vollständige JSON-Datei mit deinen lokal gespeicherten Daten. Der Export funktioniert ohne Server und verändert deine Daten nicht.'),
              const SizedBox(height: 20),
              FilledButton.icon(onPressed: _laeuft ? null : _speichern, icon: const Icon(Icons.save_alt), label: const Text('Export speichern')),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: _laeuft ? null : _teilen, icon: const Icon(Icons.share_outlined), label: const Text('Export teilen')),
              const SizedBox(height: 28),
              Semantics(header: true, child: Text('Import prüfen', style: Theme.of(context).textTheme.headlineSmall)),
              const SizedBox(height: 8),
              const Text('Wähle eine Taugt’s?-Exportdatei aus. Sie wird validiert und mit deinen lokalen Daten verglichen. Vor einer späteren ausdrücklichen Importbestätigung wird nichts gespeichert.'),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(onPressed: _laeuft ? null : _importPruefen, icon: const Icon(Icons.fact_check_outlined), label: const Text('Importdatei auswählen und prüfen')),
              if (_laeuft) ...[
                const SizedBox(height: 20),
                Semantics(label: 'Datenaustausch wird vorbereitet', child: const LinearProgressIndicator()),
              ],
              if (_status != null) ...[
                const SizedBox(height: 20),
                Semantics(liveRegion: true, child: Text(_status!, style: _istFehler ? TextStyle(color: Theme.of(context).colorScheme.error) : null)),
              ],
              if (_importFehler.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final fehler in _importFehler.take(10)) Text('• ${fehler.pfad}: ${fehler.nachricht}'),
              ],
              if (_analyse != null && _strategiePlan != null) ...[
                const SizedBox(height: 24),
                Semantics(header: true, child: Text('Importvorschau', style: Theme.of(context).textTheme.titleLarge)),
                const SizedBox(height: 8),
                const Text('Noch nicht importiert. Wähle, wie vorhandene Daten bei einer späteren Bestätigung behandelt werden sollen.'),
                const SizedBox(height: 12),
                DropdownButtonFormField<ImportStrategie>(
                  initialValue: _strategie,
                  decoration: const InputDecoration(labelText: 'Importstrategie'),
                  items: ImportStrategie.values.map((s) => DropdownMenuItem(value: s, child: Text(_strategieName(s)))).toList(),
                  onChanged: _strategieAendern,
                ),
                if (_strategie == ImportStrategie.bestandErsetzen) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text('Warnung: Nicht in der Importdatei enthaltene lokale Datensätze würden gelöscht.', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(onPressed: _laeuft ? null : _sicherungExportieren, icon: const Icon(Icons.backup_outlined), label: const Text('Vorher Sicherung exportieren')),
                ],
                const SizedBox(height: 12),
                for (final sammlung in _strategiePlan!.sammlungen.where((s) => s.hinzufuegen + s.aktualisieren + s.entfernen > 0))
                  Card(
                    child: ListTile(
                      title: Text(sammlung.name),
                      subtitle: Text('${sammlung.hinzufuegen} hinzufügen · ${sammlung.aktualisieren} aktualisieren · ${sammlung.behalten} behalten · ${sammlung.entfernen} entfernen'),
                    ),
                  ),
                const SizedBox(height: 12),
                Text('Herkunft: ${_analyse!.eigeneHerkunft} eigene · ${_analyse!.fremdeHerkunft} fremde Erlebnisse'),
                if (_strategiePlan!.identitaetsKonflikte.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Semantics(header: true, child: Text('Identitätskonflikte', style: Theme.of(context).textTheme.titleMedium)),
                  for (final konflikt in _strategiePlan!.identitaetsKonflikte)
                    ListTile(leading: const Icon(Icons.error_outline), title: Text(konflikt.nachricht), subtitle: Text('${konflikt.sammlung}: ${konflikt.id}')),
                ],
                if (_analyse!.fachlicheDubletten.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Semantics(header: true, child: Text('Mögliche fachliche Dubletten', style: Theme.of(context).textTheme.titleMedium)),
                  const SizedBox(height: 8),
                  for (final dublette in _analyse!.fachlicheDubletten)
                    ListTile(
                      leading: const Icon(Icons.warning_amber_outlined),
                      title: Text(dublette.begruendung),
                      subtitle: Text('${dublette.sammlung}: Import ${dublette.importId} · lokal ${dublette.lokaleId}'),
                    ),
                ],
              ],
            ],
          ),
        ),
      );
}
