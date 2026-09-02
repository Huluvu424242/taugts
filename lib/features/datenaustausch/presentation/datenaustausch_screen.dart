import 'package:flutter/material.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/features/datenaustausch/services/export_service.dart';
import 'package:taugts/features/datenaustausch/services/export_ziel_service.dart';

class DatenaustauschScreen extends StatefulWidget {
  const DatenaustauschScreen({
    required this.exportService,
    required this.exportZielService,
    super.key,
  });

  final ExportService exportService;
  final ExportZielService exportZielService;

  @override
  State<DatenaustauschScreen> createState() => _DatenaustauschScreenState();
}

class _DatenaustauschScreenState extends State<DatenaustauschScreen> {
  bool _laeuft = false;
  String? _status;
  bool _istFehler = false;

  String _dateiname() {
    final jetzt = DateTime.now().toUtc();
    String zwei(int wert) => wert.toString().padLeft(2, '0');
    return 'taugts-export-${jetzt.year}-${zwei(jetzt.month)}-${zwei(jetzt.day)}-'
        '${zwei(jetzt.hour)}${zwei(jetzt.minute)}.json';
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
              if (_laeuft) ...[
                const SizedBox(height: 20),
                Semantics(
                  label: 'Export wird vorbereitet',
                  child: LinearProgressIndicator(),
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
              const SizedBox(height: 28),
              Text(
                'Import',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Das Einlesen und Prüfen von Exportdateien folgt in den nächsten Stories. Bis zur ausdrücklichen Bestätigung eines späteren Imports werden keine lokalen Daten verändert.',
              ),
            ],
          ),
        ),
      );
}
