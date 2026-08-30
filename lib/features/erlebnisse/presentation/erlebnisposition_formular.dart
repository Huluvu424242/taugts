import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/presentation/formular_fehler.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/produkte/presentation/produkte_screen.dart';

class ErlebnispositionFormular extends StatefulWidget {
  const ErlebnispositionFormular({
    required this.repository,
    required this.idGenerator,
    required this.erlebnis,
    this.vorhanden,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Erlebnis erlebnis;
  final ErlebnispositionMitProdukt? vorhanden;

  @override
  State<ErlebnispositionFormular> createState() =>
      _ErlebnispositionFormularState();
}

class _ErlebnispositionFormularState extends State<ErlebnispositionFormular> {
  final _fehlerFokus = FocusNode();
  final _produktFokus = FocusNode();
  final _anzahlFokus = FocusNode();
  final _preisFokus = FocusNode();
  final _anzahl = TextEditingController();
  final _preis = TextEditingController();
  Produkt? _produkt;
  String _waehrung = 'EUR';
  Preisbeobachtung? _letzterPreis;
  var _fehler = <(String, FocusNode)>[];
  var _speichert = false;

  @override
  void initState() {
    super.initState();
    final vorhanden = widget.vorhanden;
    _produkt = vorhanden?.produkt;
    _anzahl.text = (vorhanden?.position.anzahl ?? 1).toString();
    _waehrung = vorhanden?.preis?.betrag.waehrung ?? 'EUR';
    _preis.text = vorhanden?.preis?.betrag.dezimalText ?? '';
    if (_produkt != null) _ladeLetztenPreis();
  }

  @override
  void dispose() {
    _fehlerFokus.dispose();
    _produktFokus.dispose();
    _anzahlFokus.dispose();
    _preisFokus.dispose();
    _anzahl.dispose();
    _preis.dispose();
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
    if (produkt == null || !mounted) return;
    setState(() => _produkt = produkt);
    await _ladeLetztenPreis();
  }

  Future<void> _ladeLetztenPreis() async {
    final produkt = _produkt;
    if (produkt == null) return;
    final preis = await widget.repository.ladeLetztenPreis(
      produktId: produkt.id,
      waehrung: _waehrung,
    );
    if (mounted) setState(() => _letzterPreis = preis);
  }

  void _anzahlAendern(int differenz) {
    final aktuell = int.tryParse(_anzahl.text) ?? 1;
    _anzahl.text = (aktuell + differenz).clamp(1, 999).toString();
  }

  Future<void> _speichern() async {
    final produkt = _produkt;
    final anzahl = int.tryParse(_anzahl.text.trim());
    final preisText = _preis.text.trim();
    final betrag =
        preisText.isEmpty ? null : Geldbetrag.ausEingabe(preisText, _waehrung);
    final fehler = <(String, FocusNode)>[
      if (produkt == null) ('Ein Produkt ist erforderlich.', _produktFokus),
      if (anzahl == null || anzahl < 1)
        ('Die Anzahl muss mindestens 1 sein.', _anzahlFokus),
      if (preisText.isNotEmpty && betrag == null)
        ('Der Preis muss höchstens zwei Nachkommastellen haben.', _preisFokus),
    ];
    if (fehler.isNotEmpty) {
      setState(() => _fehler = fehler);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) _fehlerFokus.requestFocus();
      return;
    }
    setState(() {
      _fehler = [];
      _speichert = true;
    });
    final jetzt = DateTime.now().toUtc();
    final vorher = widget.vorhanden;
    final positionId = vorher?.position.id ?? widget.idGenerator.neueId();
    final position = ErlebnisPosition(
      id: positionId,
      erlebnisId: widget.erlebnis.id,
      produktId: produkt!.id,
      anzahl: anzahl!,
      erstelltAm: vorher?.position.erstelltAm ?? jetzt,
      geaendertAm: jetzt,
    );
    final preis = betrag == null
        ? null
        : Preisbeobachtung(
            id: vorher?.preis?.id ?? widget.idGenerator.neueId(),
            erlebnisId: widget.erlebnis.id,
            erlebnisPositionId: positionId,
            produktId: produkt.id,
            ortId: widget.erlebnis.wirksamerOrtId,
            beobachtetAm: widget.erlebnis.erlebtAm,
            betrag: betrag,
            erstelltAm: vorher?.preis?.erstelltAm ?? jetzt,
            geaendertAm: jetzt,
          );
    try {
      await widget.repository.speichereErlebnisposition(
        position: position,
        preis: preis,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _speichert = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Die Position konnte nicht gespeichert werden.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.vorhanden == null
              ? 'Erlebnisposition hinzufügen'
              : 'Erlebnisposition bearbeiten'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_fehler.isNotEmpty)
                FormularFehlersammler(
                  focusNode: _fehlerFokus,
                  fehler: _fehler,
                ),
              Focus(
                focusNode: _produktFokus,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Produkt'),
                  subtitle: Text(_produkt?.anzeigetitel ?? 'Produkt auswählen'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _produktWaehlen,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Anzahl verringern',
                    onPressed: () => _anzahlAendern(-1),
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('positions-anzahl'),
                      controller: _anzahl,
                      focusNode: _anzahlFokus,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Anzahl'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Anzahl erhöhen',
                    onPressed: () => _anzahlAendern(1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _preis,
                      focusNode: _preisFokus,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Preis (optional)',
                        hintText: '0,00',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _waehrung,
                    items: const [
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                    ],
                    onChanged: (wert) {
                      if (wert == null) return;
                      setState(() => _waehrung = wert);
                      _ladeLetztenPreis();
                    },
                  ),
                ],
              ),
              if (_letzterPreis != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Zuletzt erfasst: ${_letzterPreis!.betrag.dezimalText} '
                    '${_letzterPreis!.betrag.waehrung} – nur zur Orientierung',
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _speichert ? null : _speichern,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Position speichern'),
              ),
            ],
          ),
        ),
      );
}
