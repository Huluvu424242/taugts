import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/erlebnisse/presentation/erlebnis_screen.dart';
import 'package:taugts/features/profil/models/profil.dart';

class EntwuerfeScreen extends StatefulWidget {
  const EntwuerfeScreen({
    required this.repository,
    required this.idGenerator,
    required this.profil,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Profil profil;

  @override
  State<EntwuerfeScreen> createState() => _EntwuerfeScreenState();
}

class _EntwuerfeScreenState extends State<EntwuerfeScreen> {
  late Future<List<Erlebnis>> _erlebnisse = widget.repository.ladeErlebnisse();

  Future<void> _oeffnen([Erlebnis? erlebnis]) async {
    Erlebnistyp? erlebnistyp;
    if (erlebnis == null) {
      erlebnistyp = await showDialog<Erlebnistyp>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const Text('Was möchtest du registrieren?'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(
                Erlebnistyp.restaurantbesuch,
              ),
              child: const ListTile(
                leading: Icon(Icons.restaurant_outlined),
                title: Text('Restaurantbesuch'),
                subtitle: Text('Besuch planen, beginnen oder nachtragen'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(
                Erlebnistyp.einkauf,
              ),
              child: const ListTile(
                leading: Icon(Icons.shopping_bag_outlined),
                title: Text('Einkauf'),
                subtitle: Text('Einkauf planen, beginnen oder nachtragen'),
              ),
            ),
          ],
        ),
      );
      if (erlebnistyp == null || !mounted) return;
    }
    final gespeichert = await Navigator.of(context).push<Erlebnis>(
      MaterialPageRoute(
        builder: (_) => ErlebnisScreen(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
          profil: widget.profil,
          erlebnistyp: erlebnistyp,
          erlebnis: erlebnis,
        ),
      ),
    );
    if (gespeichert != null && mounted) {
      setState(() {
        _erlebnisse = widget.repository.ladeErlebnisse();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erlebnis gespeichert.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Erlebnisse'),
          actions: const [
            AppSupportMenu(contextName: SupportKontexte.bewertungsentwuerfe),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _oeffnen,
          icon: const Icon(Icons.add),
          label: const Text('Erlebnis registrieren'),
        ),
        body: SafeArea(
          child: FutureBuilder<List<Erlebnis>>(
            future: _erlebnisse,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Semantics(
                  liveRegion: true,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Die Erlebnisse konnten nicht geladen werden.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => setState(
                              () => _erlebnisse =
                                  widget.repository.ladeErlebnisse(),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Erlebnisse erneut laden'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return Center(
                  child: Semantics(
                    label: 'Erlebnisse werden geladen',
                    child: const CircularProgressIndicator(),
                  ),
                );
              }
              final erlebnisse = snapshot.data!;
              if (erlebnisse.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Noch keine Erlebnisse',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Registriere einen Restaurantbesuch oder Einkauf. Du kannst jedes Erlebnis jederzeit bearbeiten.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _oeffnen,
                          child: const Text('Erlebnis registrieren'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final sortierte = _sortiere(erlebnisse, aufsteigend: false);

              return ListView(
                padding: const EdgeInsets.only(bottom: 104),
                children: [
                  _Gruppe(
                    titel: 'Alle Erlebnisse',
                    erlebnisse: sortierte,
                    eintragBuilder: _eintrag,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: FilledButton.icon(
                      onPressed: _oeffnen,
                      icon: const Icon(Icons.add),
                      label: const Text('Erlebnis registrieren'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );

  List<Erlebnis> _sortiere(
    Iterable<Erlebnis> quelle, {
    required bool aufsteigend,
  }) {
    final liste = quelle.toList();
    liste.sort((a, b) {
      final aZeit = _sortierZeit(a);
      final bZeit = _sortierZeit(b);
      if (aZeit == null && bZeit == null) {
        return a.geaendertAm.compareTo(b.geaendertAm);
      }
      if (aZeit == null) return 1;
      if (bZeit == null) return -1;
      final vergleich = aZeit.compareTo(bZeit);
      return aufsteigend ? vergleich : -vergleich;
    });
    return liste;
  }

  DateTime? _sortierZeit(Erlebnis erlebnis) => erlebnis.beginn;

  Widget _eintrag(Erlebnis erlebnis) => FutureBuilder<_EintragDetails>(
        future: _detailsLaden(erlebnis),
        builder: (context, snapshot) {
          final details = snapshot.data;
          final titel = details?.ort?.name ?? _typLabel(erlebnis.typ);
          final positionen = details?.positionen;
          final untertitelTeile = <String>[
            _typLabel(erlebnis.typ),
            _zeitLabel(context, erlebnis),
            if (positionen != null)
              '$positionen ${positionen == 1 ? 'Position' : 'Positionen'}',
          ];
          return ListTile(
            title: Text(titel),
            subtitle: Text(untertitelTeile.join(' · ')),
            onTap: () => _oeffnen(erlebnis),
            leading: Icon(
              erlebnis.typ == Erlebnistyp.restaurantbesuch
                  ? Icons.restaurant_outlined
                  : Icons.shopping_bag_outlined,
            ),
            trailing: const Icon(Icons.chevron_right),
          );
        },
      );

  Future<_EintragDetails> _detailsLaden(Erlebnis erlebnis) async {
    final ortId = erlebnis.wirksamerOrtId;
    final ergebnisse = await Future.wait<Object?>([
      widget.repository.ladeErlebnispositionen(erlebnis.id),
      if (ortId != null) widget.repository.ladeOrt(ortId) else Future.value(),
    ]);
    final positionen = ergebnisse[0]! as List<ErlebnispositionMitProdukt>;
    return _EintragDetails(
      positionen: positionen.length,
      ort: ergebnisse[1] as Ort?,
    );
  }

  String _typLabel(Erlebnistyp typ) => switch (typ) {
        Erlebnistyp.restaurantbesuch => 'Restaurantbesuch',
        Erlebnistyp.einkauf => 'Einkauf',
      };

  String _zeitLabel(BuildContext context, Erlebnis erlebnis) {
    final beginn = erlebnis.beginn;
    if (beginn == null) return 'Zeitraum noch offen';
    final localizations = MaterialLocalizations.of(context);
    final datum = localizations.formatShortDate(beginn.toLocal());
    final startZeit = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(beginn.toLocal()),
    );
    final ende = erlebnis.ende;
    if (ende == null) return '$datum · $startZeit';
    final endZeit = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(ende.toLocal()),
    );
    return '$datum · $startZeit–$endZeit';
  }
}

class _EintragDetails {
  const _EintragDetails({required this.positionen, this.ort});

  final int positionen;
  final Ort? ort;
}

class _Gruppe extends StatelessWidget {
  const _Gruppe({
    required this.titel,
    required this.erlebnisse,
    required this.eintragBuilder,
  });

  final String titel;
  final List<Erlebnis> erlebnisse;
  final Widget Function(Erlebnis erlebnis) eintragBuilder;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Semantics(
              header: true,
              child: Text(
                titel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          for (final erlebnis in erlebnisse) eintragBuilder(erlebnis),
        ],
      );
}
