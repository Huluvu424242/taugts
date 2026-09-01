import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/presentation/bewertungsverlauf_screen.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/produkte/presentation/barcode_scanner_screen.dart';
import 'package:taugts/features/produkte/presentation/produkt_erneut_bewerten_screen.dart';
import 'package:taugts/features/produkte/presentation/produkt_formular.dart';
import 'package:taugts/features/profil/models/profil.dart';

typedef BarcodeScanStart = Future<String?> Function(BuildContext context);

class ProdukteScreen extends StatefulWidget {
  const ProdukteScreen({
    required this.repository,
    required this.idGenerator,
    this.zurAuswahl = false,
    this.eigenesProfilId,
    this.profil,
    this.barcodeScanStart,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final bool zurAuswahl;
  final String? eigenesProfilId;
  final Profil? profil;
  final BarcodeScanStart? barcodeScanStart;

  @override
  State<ProdukteScreen> createState() => _ProdukteScreenState();
}

class _ProdukteScreenState extends State<ProdukteScreen> {
  final _suche = TextEditingController();
  late Future<List<Produkt>> _produkte = widget.repository.ladeProdukte();

  String? get _profilId => widget.profil?.id ?? widget.eigenesProfilId;

  Profil? get _profilFuerBewertung {
    final vorhandenesProfil = widget.profil;
    if (vorhandenesProfil != null) return vorhandenesProfil;
    final id = widget.eigenesProfilId;
    if (id == null) return null;
    final jetzt = DateTime.now().toUtc();
    return Profil(id: id, erstelltAm: jetzt, geaendertAm: jetzt);
  }

  @override
  void dispose() {
    _suche.dispose();
    super.dispose();
  }

  void _laden() {
    setState(() {
      _produkte = widget.repository.ladeProdukte(suchtext: _suche.text);
    });
  }

  Future<void> _erneutBewerten(Produkt produkt) async {
    final profil = _profilFuerBewertung;
    if (profil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Für eine Bewertung muss das eigene Profil geladen sein.'),
        ),
      );
      return;
    }
    await Navigator.of(context).push<Erlebnis>(
      MaterialPageRoute(
        builder: (_) => ProduktErneutBewertenScreen(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
          profil: profil,
          produkt: produkt,
        ),
      ),
    );
  }

  Future<void> _formularOeffnen([Produkt? produkt]) async {
    final gespeichert = await Navigator.of(context).push<Produkt>(
      MaterialPageRoute(
        builder: (_) => ProduktFormular(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
          produkt: produkt,
          onErneutBewerten: produkt == null || _profilFuerBewertung == null
              ? null
              : () => _erneutBewerten(produkt),
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

  Future<void> _barcodeScannen() async {
    final barcode = await (widget.barcodeScanStart?.call(context) ??
        Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
        ));
    if (barcode == null || !mounted) return;
    Produkt? vorhanden;
    try {
      vorhanden = await widget.repository.ladeProduktMitBarcode(barcode);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Der Barcode konnte nicht gesucht werden. Die manuelle Eingabe bleibt verfügbar.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    if (vorhanden != null) {
      final gefunden = vorhanden;
      final verwenden = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Produkt gefunden'),
          content: Text(
            '${gefunden.anzeigetitel}\nBarcode: $barcode\n\n'
            'Dieses vorhandene Produkt verwenden?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Zurück'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Produkt verwenden'),
            ),
          ],
        ),
      );
      if (verwenden == true && mounted) {
        if (widget.zurAuswahl) {
          Navigator.of(context).pop(gefunden);
        } else {
          await _formularOeffnen(gefunden);
        }
      }
      return;
    }
    final produkt = await Navigator.of(context).push<Produkt>(
      MaterialPageRoute(
        builder: (_) => ProduktFormular(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
          barcodeVorgabe: barcode,
        ),
      ),
    );
    if (produkt == null || !mounted) return;
    if (widget.zurAuswahl) {
      Navigator.of(context).pop(produkt);
    } else {
      _laden();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unvollständiges Produkt gespeichert.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.zurAuswahl ? 'Produkt auswählen' : 'Produkte'),
          actions: [
            IconButton(
              tooltip: 'Barcode scannen',
              onPressed: _barcodeScannen,
              icon: const Icon(Icons.qr_code_scanner),
            ),
            AppSupportMenu(
              contextName: SupportKontexte.produkte(
                zurAuswahl: widget.zurAuswahl,
              ),
            ),
          ],
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
                          trailing: widget.zurAuswahl
                              ? const Icon(Icons.chevron_right)
                              : Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      tooltip:
                                          '${produkt.anzeigetitel} erneut bewerten',
                                      onPressed: _profilFuerBewertung == null
                                          ? null
                                          : () => _erneutBewerten(produkt),
                                      icon: const Icon(
                                          Icons.rate_review_outlined),
                                    ),
                                    IconButton(
                                      tooltip:
                                          'Verlauf von ${produkt.anzeigetitel}',
                                      icon: const Icon(Icons.history),
                                      onPressed: () =>
                                          Navigator.of(context).push<void>(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BewertungsverlaufScreen
                                                  .fuerProdukt(
                                            repository: widget.repository,
                                            produkt: produkt,
                                            eigenesProfilId: _profilId,
                                            onErneutBewerten:
                                                _profilFuerBewertung == null
                                                    ? null
                                                    : () => _erneutBewerten(
                                                        produkt),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
