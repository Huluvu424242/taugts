import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/produkte/presentation/produkt_formular.dart';

class ProdukteScreen extends StatefulWidget {
  const ProdukteScreen({
    required this.repository,
    required this.idGenerator,
    this.zurAuswahl = false,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final bool zurAuswahl;

  @override
  State<ProdukteScreen> createState() => _ProdukteScreenState();
}

class _ProdukteScreenState extends State<ProdukteScreen> {
  final _suche = TextEditingController();
  late Future<List<Produkt>> _produkte = widget.repository.ladeProdukte();

  @override
  void dispose() {
    _suche.dispose();
    super.dispose();
  }

  void _laden() {
    setState(
      () => _produkte = widget.repository.ladeProdukte(suchtext: _suche.text),
    );
  }

  Future<void> _formularOeffnen([Produkt? produkt]) async {
    final gespeichert = await Navigator.of(context).push<Produkt>(
      MaterialPageRoute(
        builder: (_) => ProduktFormular(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
          produkt: produkt,
        ),
      ),
    );
    if (gespeichert != null && mounted) {
      _laden();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produkt gespeichert.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.zurAuswahl ? 'Produkt auswählen' : 'Produkte'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _formularOeffnen,
          icon: const Icon(Icons.add),
          label: const Text('Produkt anlegen'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _suche,
                  decoration: const InputDecoration(
                    labelText: 'Produkte suchen',
                    prefixIcon: Icon(Icons.search),
                  ),
                  maxLength: 160,
                  onChanged: (_) => _laden(),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Produkt>>(
                  future: _produkte,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: FilledButton.icon(
                          onPressed: _laden,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Produkte erneut laden'),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Center(
                        child: Semantics(
                          label: 'Produkte werden geladen',
                          child: const CircularProgressIndicator(),
                        ),
                      );
                    }
                    final produkte = snapshot.data!;
                    if (produkte.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _suche.text.trim().isEmpty
                                    ? 'Noch keine Produkte angelegt.'
                                    : 'Keine passenden Produkte gefunden.',
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _formularOeffnen,
                                child: const Text('Produkt anlegen'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: produkte.length,
                      itemBuilder: (context, index) {
                        final produkt = produkte[index];
                        return ListTile(
                          title: Text(produkt.anzeigetitel),
                          subtitle: produkt.istUnvollstaendig
                              ? const Text(
                                  'Unvollständig – kann später ergänzt werden',
                                )
                              : Text(produkt.marke ?? produkt.produktart.name),
                          trailing: Icon(
                            widget.zurAuswahl
                                ? Icons.chevron_right
                                : Icons.edit_outlined,
                          ),
                          onTap: () => widget.zurAuswahl
                              ? Navigator.of(context).pop(produkt)
                              : _formularOeffnen(produkt),
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
}
