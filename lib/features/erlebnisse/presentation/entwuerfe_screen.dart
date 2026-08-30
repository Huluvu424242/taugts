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

  Future<void> _verwerfen(
    Erlebnis erlebnis, {
    bool bestaetigungUeberspringen = false,
  }) async {
    final bestaetigt = bestaetigungUeberspringen
        ? true
        : await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Entwurf verwerfen?'),
              content:
                  const Text('Die bisher erfassten Angaben gehen verloren.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Abbrechen'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Verwerfen'),
                ),
              ],
            ),
          );
    if (bestaetigt != true) return;
    try {
      await widget.repository.loescheErlebnis(erlebnis.id);
      if (!mounted) return;
      setState(() {
        _erlebnisse = widget.repository.ladeErlebnisse();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entwurf verworfen.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Der Entwurf konnte nicht verworfen werden.'),
          action: SnackBarAction(
            label: 'Erneut versuchen',
            onPressed: () =>
                _verwerfen(erlebnis, bestaetigungUeberspringen: true),
          ),
        ),
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
                return Center(
                  child: FilledButton.icon(
                    onPressed: () => setState(
                      () => _erlebnisse = widget.repository.ladeErlebnisse(),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Erlebnisse erneut laden'),
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
                        const Text('Noch keine Erlebnisse registriert.'),
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
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: erlebnisse.length,
                itemBuilder: (context, index) {
                  final erlebnis = erlebnisse[index];
                  return ListTile(
                    title: Text(_typLabel(erlebnis.typ)),
                    subtitle: Text(_erlebnisUntertitel(context, erlebnis)),
                    onTap: () => _oeffnen(erlebnis),
                    trailing: erlebnis.istEntwurf
                        ? IconButton(
                            onPressed: () => _verwerfen(erlebnis),
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Entwurf verwerfen',
                          )
                        : const Icon(Icons.chevron_right),
                  );
                },
              );
            },
          ),
        ),
      );

  String _typLabel(Erlebnistyp typ) => switch (typ) {
        Erlebnistyp.restaurantbesuch => 'Restaurantbesuch',
        Erlebnistyp.einkauf => 'Einkauf',
      };

  String _statusLabel(Erlebnisstatus status) => switch (status) {
        Erlebnisstatus.geplant => 'Geplant',
        Erlebnisstatus.aktiv => 'Aktiv',
        Erlebnisstatus.beendet => 'Beendet',
      };

  String _erlebnisUntertitel(BuildContext context, Erlebnis erlebnis) {
    final zeit = erlebnis.tatsaechlicherBeginn ?? erlebnis.geplanterZeitpunkt;
    final zeitText = zeit == null
        ? 'Termin noch offen'
        : MaterialLocalizations.of(context).formatFullDate(zeit.toLocal());
    return '${_statusLabel(erlebnis.status)} · $zeitText';
  }
}
