import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/produkte/presentation/produkt_formular.dart';

class ProdukteScreen extends StatefulWidget {
  const ProdukteScreen({
    required this.repository,
    required this.idGenerator,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;

  @override
  State<ProdukteScreen> createState() => _ProdukteScreenState();
}

class _ProdukteScreenState extends State<ProdukteScreen> {
  late Future<List<Produkt>> _produkte = widget.repository.ladeProdukte();

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
      setState(() => _produkte = widget.repository.ladeProdukte());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Produkte')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _formularOeffnen,
          icon: const Icon(Icons.add),
          label: const Text('Produkt anlegen'),
        ),
        body: SafeArea(
          child: FutureBuilder<List<Produkt>>(
            future: _produkte,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Produkte konnten nicht geladen werden.'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final produkte = snapshot.data!;
              if (produkte.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Noch keine Produkte angelegt.'),
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
                        ? const Text('Unvollständig – kann später ergänzt werden')
                        : Text(produkt.marke ?? produkt.produktart.name),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _formularOeffnen(produkt),
                  );
                },
              );
            },
          ),
        ),
      );
}
