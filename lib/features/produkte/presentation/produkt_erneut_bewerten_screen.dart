import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/presentation/getraenkebewertung_screen.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/erlebnisse/presentation/erlebnis_screen.dart';
import 'package:taugts/features/erlebnisse/presentation/erlebnisposition_formular.dart';
import 'package:taugts/features/profil/models/profil.dart';

class ProduktErneutBewertenScreen extends StatefulWidget {
  const ProduktErneutBewertenScreen({
    required this.repository,
    required this.idGenerator,
    required this.profil,
    required this.produkt,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Profil profil;
  final Produkt produkt;

  @override
  State<ProduktErneutBewertenScreen> createState() =>
      _ProduktErneutBewertenScreenState();
}

class _ProduktErneutBewertenScreenState
    extends State<ProduktErneutBewertenScreen> {
  late Future<List<Erlebnis>> _erlebnisse = widget.repository.ladeErlebnisse();
  var _oeffnet = false;

  Future<void> _neuesErlebnis() async {
    final typ = await showDialog<Erlebnistyp>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Neues Erlebnis'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(
              Erlebnistyp.restaurantbesuch,
            ),
            child: const ListTile(
              leading: Icon(Icons.restaurant_outlined),
              title: Text('Restaurantbesuch'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(
              Erlebnistyp.einkauf,
            ),
            child: const ListTile(
              leading: Icon(Icons.shopping_bag_outlined),
              title: Text('Einkauf'),
            ),
          ),
        ],
      ),
    );
    if (typ == null || !mounted) return;

    final jetzt = DateTime.now();
    final utcJetzt = jetzt.toUtc();
    final entwurf = Erlebnis(
      id: widget.idGenerator.neueId(),
      typ: typ,
      status: Erlebnisstatus.geplant,
      geplanterTag: DateTime.utc(jetzt.year, jetzt.month, jetzt.day),
      geplanteMinute: jetzt.hour * 60 + jetzt.minute,
      herkunftProfilId: widget.profil.id,
      istEntwurf: true,
      erstelltAm: utcJetzt,
      geaendertAm: utcJetzt,
    );

    final gespeichert = await Navigator.of(context).push<Erlebnis>(
      MaterialPageRoute(
        builder: (_) => ErlebnisScreen(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
          profil: widget.profil,
          erlebnis: entwurf,
        ),
      ),
    );
    if (gespeichert == null || !mounted) return;
    setState(() {
      _erlebnisse = widget.repository.ladeErlebnisse();
    });
    await _bewertenInErlebnis(gespeichert);
  }

  Future<void> _bewertenInErlebnis(Erlebnis erlebnis) async {
    if (_oeffnet) return;
    setState(() => _oeffnet = true);
    try {
      var positionen = await widget.repository.ladeErlebnispositionen(erlebnis.id);
      if (!mounted) return;
      ErlebnispositionMitProdukt? position;
      for (final eintrag in positionen) {
        if (eintrag.produkt.id == widget.produkt.id) {
          position = eintrag;
          break;
        }
      }

      if (position == null) {
        final gespeichert = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ErlebnispositionFormular(
              repository: widget.repository,
              idGenerator: widget.idGenerator,
              erlebnis: erlebnis,
              produktVorgabe: widget.produkt,
            ),
          ),
        );
        if (gespeichert != true || !mounted) return;
        positionen = await widget.repository.ladeErlebnispositionen(erlebnis.id);
        if (!mounted) return;
        for (final eintrag in positionen) {
          if (eintrag.produkt.id == widget.produkt.id) {
            position = eintrag;
            break;
          }
        }
      }

      if (position == null || !mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Die Produktposition konnte nicht vorbereitet werden.'),
            ),
          );
        }
        return;
      }

      final bewertet = await Navigator.of(context).push<Erlebnis>(
        MaterialPageRoute(
          builder: (_) => GetraenkebewertungScreen(
            repository: widget.repository,
            idGenerator: widget.idGenerator,
            profil: widget.profil,
            erlebnis: erlebnis,
            erlebnisposition: position,
          ),
        ),
      );
      if (bewertet != null && mounted) {
        Navigator.of(context).pop(bewertet);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Die erneute Bewertung konnte nicht vorbereitet werden.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _oeffnet = false);
    }
  }

  String _typText(Erlebnistyp typ) => switch (typ) {
        Erlebnistyp.restaurantbesuch => 'Restaurantbesuch',
        Erlebnistyp.einkauf => 'Einkauf',
      };

  String _zeitText(BuildContext context, Erlebnis erlebnis) {
    final lokal = erlebnis.erlebtAm.toLocal();
    final l10n = MaterialLocalizations.of(context);
    return '${l10n.formatShortDate(lokal)} · '
        '${l10n.formatTimeOfDay(TimeOfDay.fromDateTime(lokal))}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Erneut bewerten'),
          actions: const [
            AppSupportMenu(contextName: 'Produkt erneut bewerten'),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<Erlebnis>>(
            future: _erlebnisse,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Die Erlebnisse konnten nicht geladen werden.'),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => setState(
                            () => _erlebnisse = widget.repository.ladeErlebnisse(),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Erneut versuchen'),
                        ),
                      ],
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
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      widget.produkt.anzeigetitel,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Wähle ein vorhandenes Erlebnis oder registriere ein neues. '
                    'Das Produkt wird als bestehender Stammdatensatz wiederverwendet.',
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _oeffnet ? null : _neuesErlebnis,
                    icon: const Icon(Icons.add),
                    label: const Text('Neues Erlebnis registrieren'),
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    header: true,
                    child: Text(
                      'Vorhandenes Erlebnis',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (erlebnisse.isEmpty)
                    const Text('Noch keine vorhandenen Erlebnisse verfügbar.')
                  else
                    for (final erlebnis in erlebnisse)
                      Card(
                        child: ListTile(
                          enabled: !_oeffnet,
                          leading: Icon(
                            erlebnis.typ == Erlebnistyp.restaurantbesuch
                                ? Icons.restaurant_outlined
                                : Icons.shopping_bag_outlined,
                          ),
                          title: Text(_typText(erlebnis.typ)),
                          subtitle: Text(_zeitText(context, erlebnis)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _bewertenInErlebnis(erlebnis),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      );
}
