import 'package:flutter/material.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/suche/models/suchmodelle.dart';
import 'package:taugts/features/suche/services/suche_service.dart';

class SucheScreen extends StatefulWidget {
  const SucheScreen({
    required this.service,
    this.initialZiel = Suchziel.alle,
    super.key,
  });

  final SucheService service;
  final Suchziel initialZiel;

  @override
  State<SucheScreen> createState() => _SucheScreenState();
}

class _SucheScreenState extends State<SucheScreen> {
  final _text = TextEditingController();
  late Suchziel _ziel = widget.initialZiel;
  Erlebnistyp? _erlebnistyp;
  Erlebnisstatus? _status;
  Historienart? _historienart;
  Future<List<Suchtreffer>>? _treffer;

  @override
  void initState() {
    super.initState();
    _suchen();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _suchen() {
    final filter = Suchfilter(
      ziel: _ziel,
      text: _text.text,
      erlebnistyp: _ziel == Suchziel.erlebnisse ? _erlebnistyp : null,
      erlebnisstatus: _ziel == Suchziel.erlebnisse ? _status : null,
      historienart: _ziel == Suchziel.historie ? _historienart : null,
    );
    final treffer = widget.service.suche(filter);
    setState(() {
      _treffer = treffer;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Suche'),
          actions: const [
            AppSupportMenu(contextName: SupportKontexte.suche),
          ],
        ),
        body: SafeArea(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              TextField(
                controller: _text,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Suchbegriff',
                  hintText: 'Name, Marke, Kategorie, Barcode oder Schlagwort',
                  suffixIcon: IconButton(
                    tooltip: 'Suchbegriff löschen',
                    onPressed: () {
                      _text.clear();
                      _suchen();
                    },
                    icon: const Icon(Icons.clear),
                  ),
                ),
                onSubmitted: (_) => _suchen(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Suchziel>(
                initialValue: _ziel,
                decoration: const InputDecoration(labelText: 'Suchbereich'),
                items: [
                  for (final ziel in Suchziel.values)
                    DropdownMenuItem(
                      value: ziel,
                      child: Text(_zielLabel(ziel)),
                    ),
                ],
                onChanged: (wert) {
                  if (wert != null) _ziel = wert;
                  _suchen();
                },
              ),
              if (_ziel == Suchziel.erlebnisse) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<Erlebnistyp?>(
                  initialValue: _erlebnistyp,
                  decoration: const InputDecoration(labelText: 'Erlebnistyp'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Alle Typen')),
                    DropdownMenuItem(
                      value: Erlebnistyp.restaurantbesuch,
                      child: Text('Restaurantbesuch'),
                    ),
                    DropdownMenuItem(
                      value: Erlebnistyp.einkauf,
                      child: Text('Einkauf'),
                    ),
                  ],
                  onChanged: (wert) {
                    _erlebnistyp = wert;
                    _suchen();
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Erlebnisstatus?>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Alle Status')),
                    DropdownMenuItem(
                      value: Erlebnisstatus.geplant,
                      child: Text('Geplant'),
                    ),
                    DropdownMenuItem(
                      value: Erlebnisstatus.aktiv,
                      child: Text('Aktiv'),
                    ),
                    DropdownMenuItem(
                      value: Erlebnisstatus.beendet,
                      child: Text('Beendet'),
                    ),
                  ],
                  onChanged: (wert) {
                    _status = wert;
                    _suchen();
                  },
                ),
              ],
              if (_ziel == Suchziel.historie) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<Historienart?>(
                  initialValue: _historienart,
                  decoration: const InputDecoration(labelText: 'Historienart'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Alle historischen Daten'),
                    ),
                    for (final art in Historienart.values)
                      DropdownMenuItem(
                        value: art,
                        child: Text(_historieLabel(art)),
                      ),
                  ],
                  onChanged: (wert) {
                    _historienart = wert;
                    _suchen();
                  },
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Bereich: ${_zielLabel(_ziel)}')),
                  if (_erlebnistyp != null && _ziel == Suchziel.erlebnisse)
                    Chip(label: Text('Typ: ${_erlebnistyp!.name}')),
                  if (_status != null && _ziel == Suchziel.erlebnisse)
                    Chip(label: Text('Status: ${_status!.name}')),
                  if (_historienart != null && _ziel == Suchziel.historie)
                    Chip(label: Text('Art: ${_historieLabel(_historienart!)}')),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _suchen,
                icon: const Icon(Icons.search),
                label: const Text('Suchen'),
              ),
              const SizedBox(height: 20),
              Semantics(
                header: true,
                child: Text(
                  'Ergebnisse',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (_treffer != null)
                FutureBuilder<List<Suchtreffer>>(
                  future: _treffer,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Semantics(
                        liveRegion: true,
                        child: const Text(
                          'Die Suche konnte nicht ausgeführt werden.',
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Semantics(
                        label: 'Suche läuft',
                        child: const LinearProgressIndicator(),
                      );
                    }
                    if (snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text('Keine Treffer für die aktiven Filter.'),
                      );
                    }
                    return Column(
                      children: [
                        for (final treffer in snapshot.data!)
                          ListTile(
                            title: Text(treffer.titel),
                            subtitle: Text(treffer.untertitel),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    SuchtrefferDetailScreen(treffer: treffer),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      );

  String _zielLabel(Suchziel ziel) => switch (ziel) {
        Suchziel.alle => 'Alle',
        Suchziel.produkte => 'Produkte',
        Suchziel.orte => 'Orte',
        Suchziel.erlebnisse => 'Erlebnisse',
        Suchziel.historie => 'Bewertungen und Preise',
      };

  String _historieLabel(Historienart art) => switch (art) {
        Historienart.produktbewertung => 'Produktbewertungen',
        Historienart.gaststaettenbewertung => 'Gaststättenbewertungen',
        Historienart.geschaeftsbewertung => 'Geschäftsbewertungen',
        Historienart.preisbeobachtung => 'Preisbeobachtungen',
      };
}

class SuchtrefferDetailScreen extends StatelessWidget {
  const SuchtrefferDetailScreen({required this.treffer, super.key});

  final Suchtreffer treffer;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Historischer Datensatz'),
          actions: const [
            AppSupportMenu(contextName: SupportKontexte.suchtreffer),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Semantics(
                header: true,
                child: Text(
                  treffer.titel,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 12),
              Text(treffer.untertitel),
              const SizedBox(height: 20),
              if (treffer.zeitpunkt != null)
                Text('Zeitpunkt: ${treffer.zeitpunkt!.toLocal()}'),
              if (treffer.erlebnisId != null)
                SelectableText('Erlebnis: ${treffer.erlebnisId}'),
              if (treffer.produktId != null)
                SelectableText('Produkt: ${treffer.produktId}'),
              if (treffer.ortId != null)
                SelectableText('Ort: ${treffer.ortId}'),
              const SizedBox(height: 16),
              const Text(
                'Der Treffer bezeichnet genau den gespeicherten Datensatz und nennt seinen Erlebniskontext. Korrekturen desselben Datensatzes behalten dieselbe Identität.',
              ),
            ],
          ),
        ),
      );
}
