import 'package:material_ui/material_ui.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';
import 'package:taugts/features/auswertungen/models/produktvergleich_modelle.dart';
import 'package:taugts/features/auswertungen/services/auswertungs_service.dart';

/// Suchbare Produktauswahl mit gemeinsamem Zeitraum- und Ortstypfilter.
class ProduktvergleichScreen extends StatefulWidget {
  const ProduktvergleichScreen({
    required this.optionenService,
    required this.preisService,
    super.key,
  });

  final AuswertungsFilterOptionenService optionenService;
  final ProduktPreisvergleichService preisService;

  @override
  State<ProduktvergleichScreen> createState() => _ProduktvergleichScreenState();
}

class _ProduktvergleichScreenState extends State<ProduktvergleichScreen> {
  late Future<AuswertungsFilterOptionen> _optionen =
      widget.optionenService.ladeFilterOptionen();
  String? _produktId;
  VergleichOrtstyp _ortstyp = VergleichOrtstyp.gaststaetten;
  DateTime? _von;
  DateTime? _bis;
  Future<List<ProduktPreisRang>>? _preise;

  void _aktualisieren() {
    final produktId = _produktId;
    setState(() {
      _preise = produktId == null
          ? null
          : widget.preisService.ladeLetztePreise(
              ProduktvergleichFilter(
                produktId: produktId,
                ortstyp: _ortstyp,
                von: _von,
                bis: _bis,
              ),
            );
    });
  }

  Future<void> _zeitraumWaehlen() async {
    final heute = DateTime.now();
    final auswahl = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(heute.year + 1, 12, 31),
      initialDateRange: _von == null || _bis == null
          ? null
          : DateTimeRange(start: _von!, end: _bis!),
      helpText: 'Zeitraum für Produktvergleich',
    );
    if (!mounted || auswahl == null) return;
    _von = auswahl.start;
    _bis = DateTime(
      auswahl.end.year,
      auswahl.end.month,
      auswahl.end.day,
      23,
      59,
      59,
      999,
    );
    _aktualisieren();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Produktvergleich'),
      actions: const [
        AppSupportMenu(contextName: SupportKontexte.auswertungen),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          const Text(
            'Historische Beobachtungen, keine aktuellen Marktpreise. '
            'Einheitspreise verwenden die gespeicherte Produktfüllmenge; '
            'bei nachträglich veränderten Stammdaten kann sie vom '
            'früheren Gebinde abweichen.',
          ),
          const SizedBox(height: 12),
          FutureBuilder<AuswertungsFilterOptionen>(
            future: _optionen,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return TextButton.icon(
                  onPressed: () => setState(
                    () => _optionen = widget.optionenService.ladeFilterOptionen(),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Produkte erneut laden'),
                );
              }
              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
              }
              final produkte = snapshot.data!.produkte;
              return Autocomplete<AuswertungsFilterOption>(
                displayStringForOption: (produkt) => produkt.bezeichnung,
                optionsBuilder: (eingabe) => produkte.where(
                  (produkt) => produkt.bezeichnung.toLowerCase().contains(
                    eingabe.text.trim().toLowerCase(),
                  ),
                ),
                onSelected: (produkt) {
                  _produktId = produkt.id;
                  _aktualisieren();
                },
                fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
                    TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLength: 120,
                      decoration: InputDecoration(
                        labelText: 'Produkt suchen und auswählen',
                        helperText: 'Ein Produkt aus der Vorschlagsliste wählen',
                        suffixIcon: IconButton(
                          tooltip: 'Produktauswahl löschen',
                          onPressed: () {
                            controller.clear();
                            _produktId = null;
                            _aktualisieren();
                          },
                          icon: const Icon(Icons.clear),
                        ),
                      ),
                      onChanged: (_) {
                        if (_produktId != null) {
                          _produktId = null;
                          _aktualisieren();
                        }
                      },
                      onSubmitted: (_) => onSubmitted(),
                    ),
              );
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<VergleichOrtstyp>(
            initialValue: _ortstyp,
            decoration: const InputDecoration(labelText: 'Ortstyp'),
            items: const [
              DropdownMenuItem(
                value: VergleichOrtstyp.gaststaetten,
                child: Text('Nur Gaststätten'),
              ),
              DropdownMenuItem(
                value: VergleichOrtstyp.geschaefte,
                child: Text('Nur Geschäfte'),
              ),
              DropdownMenuItem(
                value: VergleichOrtstyp.beide,
                child: Text('Gaststätten und Geschäfte'),
              ),
            ],
            onChanged: (wert) {
              if (wert == null) return;
              _ortstyp = wert;
              _aktualisieren();
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _zeitraumWaehlen,
                icon: const Icon(Icons.date_range),
                label: Text(_von == null
                    ? 'Gesamter Zeitraum'
                    : '${_von!.day}.${_von!.month}.${_von!.year} – '
                        '${_bis!.day}.${_bis!.month}.${_bis!.year}'),
              ),
              if (_von != null)
                TextButton(
                  onPressed: () {
                    _von = null;
                    _bis = null;
                    _aktualisieren();
                  },
                  child: const Text('Gesamten Zeitraum wählen'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Preisvergleich – letzter Kauf je Ort',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (_preise == null)
            const Text('Wählen Sie zuerst ein Produkt aus.')
          else
            FutureBuilder<List<ProduktPreisRang>>(
              future: _preise,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return TextButton.icon(
                    onPressed: _aktualisieren,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Preisvergleich erneut laden'),
                  );
                }
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.data!.isEmpty) {
                  return const Text('Keine Käufe im gewählten Zeitraum.');
                }
                var rang = 0;
                double? vorher;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final eintrag in snapshot.data!)
                      Builder(builder: (context) {
                        final wert = eintrag.euroProLiter;
                        if (wert != null && wert != vorher) rang++;
                        if (wert != null) vorher = wert;
                        return Card(
                          child: ListTile(
                            title: Text(
                              wert == null
                                  ? eintrag.ortName
                                  : '$rang. ${eintrag.ortName}',
                            ),
                            subtitle: Text(
                              '${eintrag.zeitpunkt.toLocal().toString().substring(0, 16)} · '
                              '${eintrag.preis.toStringAsFixed(2)} ${eintrag.waehrung}'
                              '${eintrag.mengeMl == null ? '' : ' / ${eintrag.mengeMl} ml'}',
                            ),
                            trailing: Text(
                              wert == null
                                  ? 'Nicht vergleichbar'
                                  : '${wert.toStringAsFixed(2)} €/l',
                            ),
                            isThreeLine: wert == null,
                            onTap: wert == null
                                ? () => ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(
                                      eintrag.nichtVergleichbar ?? 'Nicht vergleichbar',
                                    )),
                                  )
                                : null,
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
        ],
      ),
    ),
  );
}
