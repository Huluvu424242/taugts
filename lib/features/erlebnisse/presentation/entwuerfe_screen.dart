import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
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
  late Future<List<Erlebnis>> _entwuerfe = widget.repository.ladeEntwuerfe();

  Future<void> _oeffnen([Erlebnis? erlebnis]) async {
    final gespeichert = await Navigator.of(context).push<Erlebnis>(
      MaterialPageRoute(
        builder: (_) => ErlebnisScreen(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
          profil: widget.profil,
          erlebnis: erlebnis,
        ),
      ),
    );
    if (gespeichert != null && mounted) {
      setState(() => _entwuerfe = widget.repository.ladeEntwuerfe());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entwurf gespeichert.')),
      );
    }
  }

  Future<void> _verwerfen(Erlebnis erlebnis) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Entwurf verwerfen?'),
        content: const Text('Die bisher erfassten Angaben gehen verloren.'),
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
    await widget.repository.loescheErlebnis(erlebnis.id);
    if (!mounted) return;
    setState(() => _entwuerfe = widget.repository.ladeEntwuerfe());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entwurf verworfen.')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Bewertungsentwürfe')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _oeffnen,
          icon: const Icon(Icons.add),
          label: const Text('Jetzt bewerten'),
        ),
        body: SafeArea(
          child: FutureBuilder<List<Erlebnis>>(
            future: _entwuerfe,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: FilledButton.icon(
                    onPressed: () => setState(
                      () => _entwuerfe = widget.repository.ladeEntwuerfe(),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Entwürfe erneut laden'),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: Semantics(
                    label: 'Bewertungsentwürfe werden geladen',
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final entwuerfe = snapshot.data!;
              if (entwuerfe.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Noch keine Bewertungsentwürfe.'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _oeffnen,
                          child: const Text('Jetzt bewerten'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: entwuerfe.length,
                itemBuilder: (context, index) {
                  final erlebnis = entwuerfe[index];
                  return ListTile(
                    title: const Text('Getränk in Gaststätte'),
                    subtitle: Text(
                      MaterialLocalizations.of(context).formatFullDate(
                        erlebnis.erlebtAm.toLocal(),
                      ),
                    ),
                    onTap: () => _oeffnen(erlebnis),
                    trailing: IconButton(
                      onPressed: () => _verwerfen(erlebnis),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Entwurf verwerfen',
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
}
