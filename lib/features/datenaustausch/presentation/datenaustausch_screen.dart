import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/features/datenaustausch/services/export_service.dart';
import 'package:taugts/features/datenaustausch/services/export_ziel_service.dart';
import 'package:taugts/features/datenaustausch/services/import_ausfuehrung_service.dart';
import 'package:taugts/features/datenaustausch/services/import_dubletten_merge_service.dart';
import 'package:taugts/features/datenaustausch/services/import_konfliktanalyse_service.dart';
import 'package:taugts/features/datenaustausch/services/import_konfliktentscheidung_service.dart';
import 'package:taugts/features/datenaustausch/services/import_protokoll_repository.dart';
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
    this.importKonfliktentscheidungService =
        const ImportKonfliktentscheidungService(),
    this.importDublettenMergeService = const ImportDublettenMergeService(),
    this.importAusfuehrungService = const ImportAusfuehrungService(),
    super.key,
  });

  final ExportService exportService;
  final ExportZielService exportZielService;
  final ImportQuelleService? importQuelleService;
  final ImportValidierungsService importValidierungsService;
  final ImportKonfliktanalyseService importKonfliktanalyseService;
  final ImportStrategieService importStrategieService;
  final ImportKonfliktentscheidungService importKonfliktentscheidungService;
  final ImportDublettenMergeService importDublettenMergeService;
  final ImportAusfuehrungService importAusfuehrungService;

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
  final Map<String, Map<String, DublettenFeldQuelle>> _mergeFeldauswahl = {};
  final Map<String, ImportDublettenMergeErgebnis> _mergePlaene = {};
  bool _konflikteBearbeiten = false;
  ImportAusfuehrungsErgebnis? _importErgebnis;
  List<ImportProtokollEintrag> _importProtokoll = const [];

  @override
  void initState() {
    super.initState();
    _importProtokoll = widget.importAusfuehrungService.ladeProtokoll(
      widget.exportService.datenbank,
    );
  }

  String _dateiname() {
    final jetzt = DateTime.now().toUtc();
    String zwei(int wert) => wert.toString().padLeft(2, '0');
    return 'taugts-export-${jetzt.year}-${zwei(jetzt.month)}-${zwei(jetzt.day)}-${zwei(jetzt.hour)}${zwei(jetzt.minute)}.json';
  }

  Future<void> _speichern() async {
    await _exportAusfuehren(() async {
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
    await _exportAusfuehren(() async {
      final dateiname = _dateiname();
      await widget.exportZielService.teilen(
        dateiname: dateiname,
        inhalt: widget.exportService.erzeugeJson(),
      );
      return 'Teilen-Dialog geöffnet: $dateiname';
    });
  }

  Future<void> _sicherungExportieren() async {
    await _exportAusfuehren(() async {
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
      _mergeFeldauswahl.clear();
      _mergePlaene.clear();
      _konflikteBearbeiten = false;
      _importErgebnis = null;
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
      final importDokument =
          widget.importAusfuehrungService.normalisiereBekannteAliase(
        widget.exportService.datenbank,
        validierung.dokument!,
      );
      final lokal = Map<String, Object?>.from(
        jsonDecode(widget.exportService.erzeugeJson()) as Map,
      );
      final analyse = widget.importKonfliktanalyseService.analysiere(
        importDokument: importDokument,
        lokalesDokument: lokal,
      );
      final konflikte = widget.importKonfliktentscheidungService.ermittle(
        importDokument: importDokument,
        lokalesDokument: lokal,
        analyse: analyse,
      );
      setState(() {
        _analyse = analyse;
        _importDokument = importDokument;
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

  bool _kannZusammenfuehren(ImportEinzelKonflikt konflikt) =>
      konflikt.art == ImportKonfliktArt.fachlicheDublette &&
      (konflikt.sammlung == 'objekte' || konflikt.sammlung == 'orte');

  bool _istStammdatenFeld(String feld) =>
      feld != 'id' && feld != 'erstelltAm' && feld != 'geaendertAm';

  void _mergePlanAktualisieren(ImportEinzelKonflikt konflikt) {
    if (!_kannZusammenfuehren(konflikt) ||
        _importDokument == null ||
        _lokalesDokument == null) {
      return;
    }
    _mergePlaene[konflikt.schluessel] =
        widget.importDublettenMergeService.plane(
      sammlung: konflikt.sammlung,
      importId: konflikt.importId,
      lokaleId: konflikt.lokaleId,
      importDokument: _importDokument!,
      lokalesDokument: _lokalesDokument!,
      feldauswahl: _mergeFeldauswahl[konflikt.schluessel] ?? const {},
    );
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
      if (aktion == ImportKonfliktAktion.zusammenfuehren &&
          _kannZusammenfuehren(konflikt)) {
        _mergeFeldauswahl.putIfAbsent(konflikt.schluessel, () => {});
        _mergePlanAktualisieren(konflikt);
      } else {
        _mergePlaene.remove(konflikt.schluessel);
      }
    });
  }

  void _mergeFeldAendern(
    ImportEinzelKonflikt konflikt,
    String feld,
    DublettenFeldQuelle? quelle,
  ) {
    if (quelle == null) return;
    setState(() {
      final auswahl = _mergeFeldauswahl.putIfAbsent(
        konflikt.schluessel,
        () => <String, DublettenFeldQuelle>{},
      );
      auswahl[feld] = quelle;
      _mergePlanAktualisieren(konflikt);
    });
  }

  bool get _alleKonflikteEntschieden =>
      _entscheidungsStand.entscheidungen.length >= _konflikte.length;

  Future<void> _importBestaetigen() async {
    if (_laeuft || _importDokument == null || _lokalesDokument == null) return;
    if (!_alleKonflikteEntschieden) {
      setState(() {
        _istFehler = true;
        _status =
            'Vor dem Import müssen alle Konflikte ausdrücklich entschieden werden.';
      });
      return;
    }

    setState(() {
      _laeuft = true;
      _istFehler = false;
      _status = 'Import wird atomar ausgeführt …';
    });

    try {
      var dokument = _tiefeKopie(_importDokument!);
      final mergesNachSammlung = <String, int>{};
      final neueAliase = <ImportAliasReferenz>[];
      for (final konflikt in _konflikte) {
        if (_entscheidungsStand.fuer(konflikt) !=
                ImportKonfliktAktion.zusammenfuehren ||
            !_kannZusammenfuehren(konflikt)) {
          continue;
        }
        final merge = widget.importDublettenMergeService.plane(
          sammlung: konflikt.sammlung,
          importId: konflikt.importId,
          lokaleId: konflikt.lokaleId,
          importDokument: dokument,
          lokalesDokument: _lokalesDokument!,
          feldauswahl: _mergeFeldauswahl[konflikt.schluessel] ?? const {},
        );
        dokument = merge.dokument;
        neueAliase.add(merge.alias);
        mergesNachSammlung.update(
          konflikt.sammlung,
          (wert) => wert + 1,
          ifAbsent: () => 1,
        );
      }

      final ergebnis = widget.importAusfuehrungService.ausfuehren(
        datenbank: widget.exportService.datenbank,
        importDokument: dokument,
        strategie: _strategie,
        entscheidungen: _entscheidungsStand,
        aliase: neueAliase,
        zusammengefuehrtNachSammlung: mergesNachSammlung,
      );
      final protokoll = widget.importAusfuehrungService.ladeProtokoll(
        widget.exportService.datenbank,
      );
      if (!mounted) return;
      setState(() {
        _importErgebnis = ergebnis;
        _importProtokoll = protokoll;
        _status = 'Import erfolgreich abgeschlossen.';
        _importDokument = null;
        _lokalesDokument = null;
        _analyse = null;
        _strategiePlan = null;
        _konflikte = const [];
        _entscheidungsStand = const ImportKonfliktEntscheidungsStand();
        _mergePlaene.clear();
        _mergeFeldauswahl.clear();
        _konflikteBearbeiten = false;
      });
    } catch (_) {
      final protokoll = widget.importAusfuehrungService.ladeProtokoll(
        widget.exportService.datenbank,
      );
      if (!mounted) return;
      setState(() {
        _istFehler = true;
        _importProtokoll = protokoll;
        _status =
            'Import fehlgeschlagen. Alle fachlichen Änderungen wurden zurückgerollt.';
      });
    } finally {
      if (mounted) setState(() => _laeuft = false);
    }
  }

  Map<String, Object?> _tiefeKopie(Map<String, Object?> dokument) => {
        for (final eintrag in dokument.entries)
          eintrag.key: _kopiereWert(eintrag.value),
      };

  Object? _kopiereWert(Object? wert) {
    if (wert is Map) {
      return {
        for (final eintrag in wert.entries)
          eintrag.key.toString(): _kopiereWert(eintrag.value),
      };
    }
    if (wert is List) return wert.map(_kopiereWert).toList();
    return wert;
  }

  Future<void> _exportAusfuehren(Future<String> Function() aktion) async {
    if (_laeuft) return;
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
          'Noch nicht importiert. Prüfe Strategie und Konflikte und bestätige den Import anschließend ausdrücklich.',
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
          onChanged: _laeuft ? null : _strategieAendern,
        ),
        if (_strategie == ImportStrategie.bestandErsetzen) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              'Warnung: Nicht in der Importdatei enthaltene lokale Datensätze werden gelöscht.',
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
              '${_entscheidungsStand.entscheidungen.length} von ${_konflikte.length} Konflikten entschieden.',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _laeuft
                ? null
                : () => setState(() => _konflikteBearbeiten = true),
            icon: const Icon(Icons.rule_outlined),
            label: const Text('Konflikte einzeln entscheiden'),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed:
              _laeuft || !_alleKonflikteEntschieden ? null : _importBestaetigen,
          icon: const Icon(Icons.download_done_outlined),
          label: const Text('Import verbindlich ausführen'),
        ),
        if (!_alleKonflikteEntschieden) ...[
          const SizedBox(height: 8),
          const Text(
            'Der Import kann erst ausgeführt werden, wenn alle Konflikte entschieden sind.',
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
            'Diese Entscheidungen sind Teil der Vorschau. Erst die ausdrückliche Importbestätigung verändert lokale Daten.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _laeuft
                ? null
                : () => setState(() => _konflikteBearbeiten = false),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Zurück zur Importvorschau'),
          ),
          const SizedBox(height: 16),
          for (final konflikt in _konflikte)
            _buildKonfliktKarte(context, konflikt),
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
              Text(
                '${konflikt.sammlung} · Import ${konflikt.importId} · lokal ${konflikt.lokaleId}',
              ),
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
                Text(
                  'Unterschiede',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
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
                key: ValueKey(
                  'entscheidung-${konflikt.schluessel}-$entscheidung',
                ),
                initialValue: entscheidung,
                decoration: const InputDecoration(labelText: 'Entscheidung'),
                hint: const Text('Bitte auswählen'),
                items: konflikt.erlaubteAktionen
                    .where(
                      (aktion) =>
                          aktion != ImportKonfliktAktion.zusammenfuehren ||
                          _kannZusammenfuehren(konflikt),
                    )
                    .map(
                      (aktion) => DropdownMenuItem(
                        value: aktion,
                        child: Text(_aktionsName(aktion)),
                      ),
                    )
                    .toList(),
                onChanged: _laeuft
                    ? null
                    : (aktion) => _entscheidungAendern(konflikt, aktion),
              ),
              if (entscheidung == ImportKonfliktAktion.zusammenfuehren &&
                  _kannZusammenfuehren(konflikt)) ...[
                const SizedBox(height: 12),
                Text(
                  'Stammdaten für das kanonische Objekt',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Die lokale UUID bleibt erhalten. Wähle für abweichende Stammdaten den gewünschten Wert.',
                ),
                const SizedBox(height: 8),
                for (final unterschied in konflikt.unterschiede.where(
                  (u) => _istStammdatenFeld(u.feld),
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DropdownButtonFormField<DublettenFeldQuelle>(
                      key: ValueKey(
                        'merge-${konflikt.schluessel}-${unterschied.feld}',
                      ),
                      initialValue: _mergeFeldauswahl[konflikt.schluessel]
                              ?[unterschied.feld] ??
                          DublettenFeldQuelle.lokal,
                      decoration: InputDecoration(labelText: unterschied.feld),
                      items: [
                        DropdownMenuItem(
                          value: DublettenFeldQuelle.lokal,
                          child: Text(
                            'Lokal: ${_wertText(unterschied.lokal)}',
                          ),
                        ),
                        DropdownMenuItem(
                          value: DublettenFeldQuelle.import,
                          child: Text(
                            'Import: ${_wertText(unterschied.import)}',
                          ),
                        ),
                      ],
                      onChanged: _laeuft
                          ? null
                          : (quelle) => _mergeFeldAendern(
                                konflikt,
                                unterschied.feld,
                                quelle,
                              ),
                    ),
                  ),
                if (_mergePlaene.containsKey(konflikt.schluessel))
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'Merge geplant: Import-ID ${konflikt.importId} wird mit ${konflikt.lokaleId} zusammengeführt.',
                    ),
                  ),
              ],
              const SizedBox(height: 4),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Auf weitere Konflikte dieses Typs anwenden',
                ),
                value: _aufTypAnwenden.contains(konflikt.schluessel),
                onChanged: _laeuft
                    ? null
                    : (wert) {
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

  Widget _buildImportErgebnis(BuildContext context) {
    final ergebnis = _importErgebnis;
    if (ergebnis == null) return const SizedBox.shrink();
    const historischeSammlungen = <String, String>{
      'erlebnisse': 'Erlebnisse',
      'erlebnisPositionen': 'Positionen',
      'preisbeobachtungen': 'Preisbeobachtungen',
      'bewertungen': 'Produktbewertungen',
      'ortsbewertungen': 'Ortsbewertungen',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        Semantics(
          header: true,
          child: Text(
            'Letztes Importergebnis',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 8),
        for (final eintrag in historischeSammlungen.entries)
          _ergebnisKarte(
            eintrag.value,
            ergebnis.nachSammlung[eintrag.key] ?? const ImportErgebnisZaehler(),
          ),
        const SizedBox(height: 8),
        Text(
          'Gesamt: ${_zaehlerText(ergebnis.gesamt)}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }

  Widget _ergebnisKarte(String titel, ImportErgebnisZaehler zaehler) => Card(
        child: ListTile(
          title: Text(titel),
          subtitle: Text(_zaehlerText(zaehler)),
        ),
      );

  String _zaehlerText(ImportErgebnisZaehler zaehler) =>
      '${zaehler.hinzugefuegt} hinzugefügt · ${zaehler.aktualisiert} aktualisiert · ${zaehler.uebersprungen} übersprungen · ${zaehler.zusammengefuehrt} zusammengeführt · ${zaehler.fehlerhaft} fehlerhaft';

  Widget _buildImportProtokoll(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          Semantics(
            header: true,
            child: Text(
              'Importprotokoll',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Das Protokoll bleibt ausschließlich lokal und enthält nur Zeitpunkt, Status, Strategie und Zähler – keine importierten Fachinhalte.',
          ),
          const SizedBox(height: 8),
          if (_importProtokoll.isEmpty)
            const Text('Noch keine Importausführung protokolliert.')
          else
            for (final eintrag in _importProtokoll.take(10))
              Card(
                child: ListTile(
                  leading: Icon(
                    eintrag.erfolgreich
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                  ),
                  title: Text(
                    eintrag.erfolgreich
                        ? 'Import erfolgreich'
                        : 'Import zurückgerollt',
                  ),
                  subtitle: Text(
                    '${eintrag.ausgefuehrtAm.toLocal()} · ${_strategieName(eintrag.strategie)}\n${eintrag.hinzugefuegt} hinzugefügt · ${eintrag.aktualisiert} aktualisiert · ${eintrag.uebersprungen} übersprungen · ${eintrag.zusammengefuehrt} zusammengeführt · ${eintrag.fehlerhaft} fehlerhaft',
                  ),
                ),
              ),
        ],
      );

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
                'Wähle eine Taugt’s?-Exportdatei aus. Sie wird validiert und mit deinen lokalen Daten verglichen. Erst die ausdrückliche Importbestätigung speichert Daten.',
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
                  label: 'Datenaustausch wird ausgeführt',
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
              _buildImportErgebnis(context),
              _buildImportProtokoll(context),
            ],
          ),
        ),
      );
}
