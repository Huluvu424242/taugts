import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/presentation/formular_fehler.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';

class _Ortsfehler {
  const _Ortsfehler(this.text, this.fokus);

  final String text;
  final FocusNode fokus;
}

class OrtFormular extends StatefulWidget {
  const OrtFormular({
    required this.repository,
    required this.idGenerator,
    this.ort,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Ort? ort;

  @override
  State<OrtFormular> createState() => _OrtFormularState();
}

class _OrtFormularState extends State<OrtFormular> {
  final _formularKey = GlobalKey<FormState>();
  final _fehlerKey = GlobalKey();
  final _fehlerFokus = FocusNode();
  final _nameFokus = FocusNode();
  final _breitengradFokus = FocusNode();
  final _laengengradFokus = FocusNode();
  final _name = TextEditingController();
  final _adresse = TextEditingController();
  final _breitengrad = TextEditingController();
  final _laengengrad = TextEditingController();
  final _osmReferenz = TextEditingController();
  final _notiz = TextEditingController();
  late Ortstyp _typ;
  var _fehler = <_Ortsfehler>[];
  var _speichert = false;

  @override
  void initState() {
    super.initState();
    final ort = widget.ort;
    _typ = ort?.typ ?? Ortstyp.gastronomie;
    _name.text = ort?.name ?? '';
    _adresse.text = ort?.adresse ?? '';
    _breitengrad.text = ort?.breitengrad?.toString() ?? '';
    _laengengrad.text = ort?.laengengrad?.toString() ?? '';
    _osmReferenz.text = ort?.osmReferenz ?? '';
    _notiz.text = ort?.notiz ?? '';
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _adresse,
      _breitengrad,
      _laengengrad,
      _osmReferenz,
      _notiz,
    ]) {
      controller.dispose();
    }
    for (final fokus in [
      _nameFokus,
      _breitengradFokus,
      _laengengradFokus,
      _fehlerFokus,
    ]) {
      fokus.dispose();
    }
    super.dispose();
  }

  String? _namePruefen(String? wert) => wert == null || wert.trim().isEmpty
      ? 'Der Name ist erforderlich.'
      : null;

  String? _breitengradPruefen(String? wert) =>
      _koordinatePruefen(wert, -90, 90, _laengengrad.text);

  String? _laengengradPruefen(String? wert) =>
      _koordinatePruefen(wert, -180, 180, _breitengrad.text);

  String? _koordinatePruefen(
    String? wert,
    double minimum,
    double maximum,
    String gegenstueck,
  ) {
    final eingabe = wert?.trim() ?? '';
    if (eingabe.isEmpty && gegenstueck.trim().isEmpty) {
      return null;
    }
    if (eingabe.isEmpty) {
      return 'Beide Koordinaten sind erforderlich.';
    }
    final zahl = _kommazahl(eingabe);
    if (zahl == null || zahl < minimum || zahl > maximum) {
      return 'Wert muss zwischen $minimum und $maximum liegen.';
    }
    return null;
  }

  Future<void> _speichern() async {
    FocusScope.of(context).unfocus();
    if (!(_formularKey.currentState?.validate() ?? false)) {
      setState(() => _fehler = _validierungsfehler());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Eingaben prüfen.')),
      );
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
      final fehlerContext = _fehlerKey.currentContext;
      if (fehlerContext != null && fehlerContext.mounted) {
        await Scrollable.ensureVisible(fehlerContext);
      }
      if (!mounted) {
        return;
      }
      _fehlerFokus.requestFocus();
      return;
    }

    final dubletten = await widget.repository.findeAehnlicheOrte(
      name: _name.text,
      adresse: _wert(_adresse),
      ausgenommenId: widget.ort?.id,
    );
    if (!mounted) {
      return;
    }
    if (dubletten.isNotEmpty) {
      final fortfahren = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Mögliche Dublette'),
          content: Text(
            'Ein ähnlich benannter Ort ist bereits vorhanden: '
            '${dubletten.map((ort) => ort.name).join(', ')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Zurück'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Trotzdem speichern'),
            ),
          ],
        ),
      );
      if (fortfahren != true || !mounted) {
        return;
      }
    }

    setState(() => _speichert = true);
    final vorher = widget.ort;
    final jetzt = DateTime.now().toUtc();
    final ort = Ort(
      id: vorher?.id ?? widget.idGenerator.neueId(),
      name: _name.text.trim(),
      typ: _typ,
      adresse: _wert(_adresse),
      breitengrad: _kommazahl(_breitengrad.text),
      laengengrad: _kommazahl(_laengengrad.text),
      osmReferenz: _wert(_osmReferenz),
      notiz: _wert(_notiz),
      erstelltAm: vorher?.erstelltAm ?? jetzt,
      geaendertAm: jetzt,
    );
    try {
      await widget.repository.speichereOrt(ort);
      if (mounted) {
        Navigator.of(context).pop(ort);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _speichert = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Der Ort konnte nicht gespeichert werden.')),
      );
    }
  }

  List<_Ortsfehler> _validierungsfehler() {
    final fehler = <_Ortsfehler>[];
    final nameFehler = _namePruefen(_name.text);
    if (nameFehler != null) {
      fehler.add(_Ortsfehler(nameFehler, _nameFokus));
    }
    final breiteFehler = _breitengradPruefen(_breitengrad.text);
    if (breiteFehler != null) {
      fehler.add(_Ortsfehler(breiteFehler, _breitengradFokus));
    }
    final laengeFehler = _laengengradPruefen(_laengengrad.text);
    if (laengeFehler != null) {
      fehler.add(_Ortsfehler(laengeFehler, _laengengradFokus));
    }
    return fehler;
  }

  String? _wert(TextEditingController controller) {
    final wert = controller.text.trim();
    return wert.isEmpty ? null : wert;
  }

  double? _kommazahl(String wert) =>
      double.tryParse(wert.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.ort == null ? 'Ort anlegen' : 'Ort bearbeiten'),
        ),
        body: SafeArea(
          child: Form(
            key: _formularKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_fehler.isNotEmpty)
                  FormularFehlersammler(
                    key: _fehlerKey,
                    focusNode: _fehlerFokus,
                    fehler: [
                      for (final fehler in _fehler) (fehler.text, fehler.fokus),
                    ],
                  ),
                DropdownButtonFormField<Ortstyp>(
                  initialValue: _typ,
                  decoration: const InputDecoration(labelText: 'Ortstyp'),
                  items: const [
                    DropdownMenuItem(
                      value: Ortstyp.gastronomie,
                      child: Text('Gastronomie'),
                    ),
                    DropdownMenuItem(
                      value: Ortstyp.geschaeft,
                      child: Text('Geschäft'),
                    ),
                    DropdownMenuItem(
                      value: Ortstyp.privat,
                      child: Text('Privater Ort'),
                    ),
                    DropdownMenuItem(
                      value: Ortstyp.sonstiger,
                      child: Text('Sonstiger Ort'),
                    ),
                  ],
                  onChanged: (wert) => setState(() => _typ = wert!),
                ),
                _textfeld(
                  _name,
                  'Name',
                  maxLength: 120,
                  focusNode: _nameFokus,
                  validator: _namePruefen,
                ),
                _textfeld(_adresse, 'Adresse (optional)', maxLength: 240),
                _textfeld(
                  _breitengrad,
                  'Breitengrad (optional)',
                  maxLength: 16,
                  focusNode: _breitengradFokus,
                  validator: _breitengradPruefen,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
                _textfeld(
                  _laengengrad,
                  'Längengrad (optional)',
                  maxLength: 16,
                  focusNode: _laengengradFokus,
                  validator: _laengengradPruefen,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
                _textfeld(
                  _osmReferenz,
                  'OSM-Referenz (optional)',
                  maxLength: 160,
                ),
                _textfeld(
                  _notiz,
                  'Notiz (optional)',
                  maxLength: 1000,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _speichert ? null : _speichern,
                  child: Text(_speichert ? 'Speichert …' : 'Ort speichern'),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _textfeld(
    TextEditingController controller,
    String label, {
    required int maxLength,
    int maxLines = 1,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: label),
          keyboardType: keyboardType,
          maxLength: maxLength,
          maxLines: maxLines,
          validator: validator,
        ),
      );
}
