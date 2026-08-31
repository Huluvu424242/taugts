import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/presentation/bewertungsverlauf_screen.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/orte/presentation/ort_formular.dart';

class OrteScreen extends StatefulWidget {
  const OrteScreen({
    required this.repository,
    required this.idGenerator,
    this.zurAuswahl = false,
    this.eigenesProfilId,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final bool zurAuswahl;
  final String? eigenesProfilId;

  @override
  State<OrteScreen> createState() => _OrteScreenState();
}

class _OrteScreenState extends State<OrteScreen> {
  final _suche = TextEditingController();
  late Future<List<Ort>> _orte = widget.repository.ladeOrte();

  @override
  void dispose() {
    _suche.dispose();
    super.dispose();
  }

  void _suchen(String suchtext) {
    setState(() => _orte = widget.repository.ladeOrte(suchtext: suchtext));
  }

  Future<void> _formularOeffnen([Ort? ort]) async {
    final gespeichert = await Navigator.of(context).push<Ort>(
      MaterialPageRoute(
        builder: (_) => OrtFormular(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
          ort: ort,
        ),
      ),
    );
    if (gespeichert != null && mounted) {
      _suchen(_suche.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ort gespeichert.')),
      );
    }
  }

  void _ortAntippen(Ort ort) {
    if (widget.zurAuswahl) {
      Navigator.of(context).pop(ort);
    } else {
      _formularOeffnen(ort);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.zurAuswahl ? 'Ort auswählen' : 'Orte'),
          actions: [
            AppSupportMenu(
              contextName: SupportKontexte.orte(
                zurAuswahl: widget.zurAuswahl,
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _formularOeffnen,
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Ort anlegen'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _suche,
                  decoration: const InputDecoration(
                    labelText: 'Orte suchen',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: _suchen,
                  maxLength: 160,
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Ort>>(
                  future: _orte,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: FilledButton.icon(
                          onPressed: () => _suchen(_suche.text),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Orte erneut laden'),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Center(
                        child: Semantics(
                          label: 'Orte werden geladen',
                          child: const CircularProgressIndicator(),
                        ),
                      );
                    }
                    final orte = snapshot.data!;
                    if (orte.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _suche.text.trim().isEmpty
                                    ? 'Noch keine Orte angelegt.'
                                    : 'Keine passenden Orte gefunden.',
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _formularOeffnen,
                                child: const Text('Ort anlegen'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: orte.length,
                      itemBuilder: (context, index) {
                        final ort = orte[index];
                        return ListTile(
                          title: Text(ort.name),
                          subtitle: Text(
                            ort.adresse == null
                                ? _ortstyp(ort.typ)
                                : '${_ortstyp(ort.typ)} · ${ort.adresse}',
                          ),
                          trailing: widget.zurAuswahl
                              ? const Icon(Icons.chevron_right)
                              : IconButton(
                                  tooltip: 'Verlauf von ${ort.name}',
                                  icon: const Icon(Icons.history),
                                  onPressed: () => Navigator.of(context).push<void>(
                                    MaterialPageRoute(
                                      builder: (_) => BewertungsverlaufScreen.fuerOrt(
                                        repository: widget.repository,
                                        ort: ort,
                                        eigenesProfilId: widget.eigenesProfilId,
                                      ),
                                    ),
                                  ),
                                ),
                          onTap: () => _ortAntippen(ort),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

  String _ortstyp(Ortstyp typ) => switch (typ) {
        Ortstyp.gastronomie => 'Gastronomie',
        Ortstyp.geschaeft => 'Geschäft',
        Ortstyp.privat => 'Privater Ort',
        Ortstyp.sonstiger => 'Sonstiger Ort',
      };
}
