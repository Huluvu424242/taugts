import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/orte/presentation/orte_screen.dart';
import 'package:taugts/features/produkte/presentation/produkte_screen.dart';
import 'package:taugts/features/profil/models/profil.dart';

class ErlebnisScreen extends StatefulWidget {
  const ErlebnisScreen({
    required this.repository,
    required this.idGenerator,
    required this.profil,
    this.erlebnis,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Profil profil;
  final Erlebnis? erlebnis;

  @override
  State<ErlebnisScreen> createState() => _ErlebnisScreenState();
}

class _ErlebnisScreenState extends State<ErlebnisScreen> {
  final _fehlerKey = GlobalKey();
  final _produktFokus = FocusNode();
  final _preisFokus = FocusNode();
  final _mengeFokus = FocusNode();
  final _preis = TextEditingController();
  final _menge = TextEditingController();
  final _gebinde = TextEditingController();
  final _notiz = TextEditingController();
  Produkt? _produkt;
  Ort? _kaufort;
  Ort? _konsumort;
  late DateTime _erlebtAm;
  var _speichert = false;
  var _produktFehlt = false;
  var _preisUngueltig = false;
  var _mengeUngueltig = false;

  @override
  void initState() {
    super.initState();
    final erlebnis = widget.erlebnis;
    _erlebtAm = erlebnis?.erlebtAm.toLocal() ?? DateTime.now();
    _preis.text = erlebnis?.preis?.toString() ?? '';
    _menge.text = erlebnis?.menge?.toString() ?? '';
    _gebinde.text = erlebnis?.gebinde ?? '';
    _notiz.text = erlebnis?.notiz ?? '';
    _ladeReferenzen();
  }

  Future<void> _ladeReferenzen() async {
    final erlebnis = widget.erlebnis;
    if (erlebnis == null) return;
    final werte = await Future.wait([
      widget.repository.ladeProdukt(erlebnis.produktId),
      erlebnis.kaufortId == null
          ? Future<Ort?>.value()
          : widget.repository.ladeOrt(erlebnis.kaufortId!),
      erlebnis.konsumortId == null
          ? Future<Ort?>.value()
          : widget.repository.ladeOrt(erlebnis.konsumortId!),
    ]);
    if (!mounted) return;
    setState(() {
      _produkt = werte[0] as Produkt?;
      _kaufort = werte[1] as Ort?;
      _konsumort = werte[2] as Ort?;
    });
  }

  @override
  void dispose() {
    _produktFokus.dispose();
    _preisFokus.dispose();
    _mengeFokus.dispose();
    for (final controller in [_preis, _menge, _gebinde, _notiz]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _produktWaehlen() async {
    final produkt = await Navigator.of(context).push<Produkt>(
      MaterialPageRoute(
        builder: (_) => ProdukteScreen(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
          zurAuswahl: true,
        ),
      ),
    );
    if (produkt != null && mounted) {
      setState(() {
        _produkt = produkt;
        _produktFehlt = false;
      });
    }
  }

  Future<void> _ortWaehlen(bool kauf) async {
    final ort = await Navigator.of(context).push<Ort>(
      MaterialPageRoute(
        builder: (_) => OrteScreen(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
          zurAuswahl: true,
        ),
      ),
    );
    if (ort != null && mounted) {
      setState(() => kauf ? _kaufort = ort : _konsumort = ort);
    }
  }

  Future<void> _zeitWaehlen() async {
    final datum = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: _erlebtAm,
    );
    if (datum == null || !mounted) return;
    final zeit = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_erlebtAm),
    );
    if (zeit == null || !mounted) return;
    setState(() {
      _erlebtAm = DateTime(datum.year, datum.month, datum.day, zeit.hour, zeit.minute);
    });
  }

  Future<void> _speichern() async {
    final preisUngueltig = !_istPositiveZahlOderLeer(_preis.text);
    final mengeUngueltig = !_istPositiveZahlOderLeer(_menge.text);
    if (_produkt == null || preisUngueltig || mengeUngueltig) {
      setState(() {
        _produktFehlt = _produkt == null;
        _preisUngueltig = preisUngueltig;
        _mengeUngueltig = mengeUngueltig;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Eingaben prüfen.')),
      );
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final fehlerContext = _fehlerKey.currentContext;
      if (fehlerContext != null) await Scrollable.ensureVisible(fehlerContext);
      if (!mounted) return;
      if (_produktFehlt) {
        _produktFokus.requestFocus();
      } else if (_preisUngueltig) {
        _preisFokus.requestFocus();
      } else {
        _mengeFokus.requestFocus();
      }
      return;
    }
    setState(() => _speichert = true);
    final vorher = widget.erlebnis;
    final jetzt = DateTime.now().toUtc();
    final erlebnis = Erlebnis(
      id: vorher?.id ?? widget.idGenerator.neueId(),
      produktId: _produkt!.id,
      herkunftProfilId: widget.profil.id,
      kaufortId: _kaufort?.id,
      konsumortId: _konsumort?.id,
      erlebtAm: _erlebtAm.toUtc(),
      erstelltAm: vorher?.erstelltAm ?? jetzt,
      geaendertAm: jetzt,
      preis: _zahl(_preis.text),
      menge: _zahl(_menge.text),
      gebinde: _wert(_gebinde.text),
      notiz: _wert(_notiz.text),
    );
    try {
      await widget.repository.speichereErlebnis(erlebnis);
      if (mounted) Navigator.of(context).pop(erlebnis);
    } catch (_) {
      if (!mounted) return;
      setState(() => _speichert = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Der Entwurf konnte nicht gespeichert werden.')),
      );
    }
  }

  double? _zahl(String text) => double.tryParse(text.trim().replaceAll(',', '.'));
  bool _istPositiveZahlOderLeer(String text) {
    if (text.trim().isEmpty) return true;
    final zahl = _zahl(text);
    return zahl != null && zahl > 0;
  }
  String? _wert(String text) => text.trim().isEmpty ? null : text.trim();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Getränk in Gaststätte')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 104),
            children: [
              if (_produktFehlt || _preisUngueltig || _mengeUngueltig)
                Semantics(
                  key: _fehlerKey,
                  liveRegion: true,
                  container: true,
                  child: Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: const Text('Bitte Eingaben prüfen'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_produktFehlt)
                            TextButton(
                              onPressed: _produktFokus.requestFocus,
                              child: const Text('Ein Produkt ist erforderlich.'),
                            ),
                          if (_preisUngueltig)
                            TextButton(
                              onPressed: _preisFokus.requestFocus,
                              child: const Text('Preis muss größer als null sein.'),
                            ),
                          if (_mengeUngueltig)
                            TextButton(
                              onPressed: _mengeFokus.requestFocus,
                              child: const Text('Menge muss größer als null sein.'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              TextButton.icon(
                focusNode: _produktFokus,
                onPressed: _produktWaehlen,
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(_produkt?.anzeigetitel ?? 'Produkt auswählen *'),
              ),
              TextButton.icon(
                onPressed: _zeitWaehlen,
                icon: const Icon(Icons.schedule),
                label: Text(
                  '${MaterialLocalizations.of(context).formatFullDate(_erlebtAm)}, '
                  '${MaterialLocalizations.of(context).formatTimeOfDay(
                    TimeOfDay.fromDateTime(_erlebtAm),
                  )}',
                ),
              ),
              TextButton.icon(
                onPressed: () => _ortWaehlen(false),
                icon: const Icon(Icons.restaurant_outlined),
                label: Text(_konsumort?.name ?? 'Konsumort auswählen (optional)'),
              ),
              TextButton.icon(
                onPressed: () => _ortWaehlen(true),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(_kaufort?.name ?? 'Kaufort auswählen (optional)'),
              ),
              TextField(
                controller: _preis,
                focusNode: _preisFokus,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                maxLength: 12,
                decoration: InputDecoration(
                  labelText: 'Preis (optional)',
                  errorText: _preisUngueltig
                      ? 'Bitte eine Zahl größer als null eingeben.'
                      : null,
                ),
              ),
              TextField(
                controller: _menge,
                focusNode: _mengeFokus,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                maxLength: 12,
                decoration: InputDecoration(
                  labelText: 'Menge (optional)',
                  errorText: _mengeUngueltig
                      ? 'Bitte eine Zahl größer als null eingeben.'
                      : null,
                ),
              ),
              TextField(
                controller: _gebinde,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Gebinde (optional)'),
              ),
              TextField(
                controller: _notiz,
                maxLength: 1000,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Notiz (optional)'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _speichert ? null : _speichern,
            icon: _speichert
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_speichert ? 'Entwurf wird gespeichert' : 'Entwurf speichern'),
          ),
        ),
      );
}
