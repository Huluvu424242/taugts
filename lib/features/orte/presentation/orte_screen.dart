import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/orte/presentation/ort_formular.dart';

class OrteScreen extends StatefulWidget {
  const OrteScreen({
    required this.repository,
    required this.idGenerator,
    this.zurAuswahl = false,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final bool zurAuswahl;

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
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Ort>>(
                  future: _orte,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Orte konnten nicht geladen werden.'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final orte = snapshot.data!;
                    if (orte.isEmpty) {
                      return Center(
                        child: Text(
                          _suche.text.trim().isEmpty
                              ? 'Noch keine Orte angelegt.'
                              : 'Keine passenden Orte gefunden.',
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
                          trailing: Icon(
                            widget.zurAuswahl
                                ? Icons.chevron_right
                                : Icons.edit_outlined,
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
