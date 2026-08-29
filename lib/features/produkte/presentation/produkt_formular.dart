import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/presentation/formular_fehler.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';

class _Validierungsfehler {
  const _Validierungsfehler(this.text, this.fokus);

  final String text;
  final FocusNode fokus;
}

class ProduktFormular extends StatefulWidget {
  const ProduktFormular({
    required this.repository,
    required this.idGenerator,
    this.produkt,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Produkt? produkt;

  @override
  State<ProduktFormular> createState() => _ProduktFormularState();
}

class _ProduktFormularState extends State<ProduktFormular> {
  final _formularKey = GlobalKey<FormState>();
  final _fehlerKey = GlobalKey();
  final _fehlerFokus = FocusNode();
  final _nameFokus = FocusNode();
  final _barcodeFokus = FocusNode();
  final _alkoholFokus = FocusNode();
  final _fuellmengeFokus = FocusNode();
  final _name = TextEditingController();
  final _marke = TextEditingController();
  final _brauerei = TextEditingController();
  final _sorte = TextEditingController();
  final _alkohol = TextEditingController();
  final _herkunft = TextEditingController();
  final _gebinde = TextEditingController();
  final _fuellmenge = TextEditingController();
  final _barcode = TextEditingController();
  final _notiz = TextEditingController();
  late Produktart _produktart;
  var _zeigtFehler = false;
  var _speichert = false;
  var _fehler = <_Validierungsfehler>[];

  @override
  void initState() {
    super.initState();
    final produkt = widget.produkt;
    _produktart = produkt?.produktart ?? Produktart.bier;
    _name.text = produkt?.name ?? '';
    _marke.text = produkt?.marke ?? '';
    _brauerei.text = produkt?.brauerei ?? '';
    _sorte.text = produkt?.sorte ?? '';
    _alkohol.text = produkt?.alkoholgehalt?.toString() ?? '';
    _herkunft.text = produkt?.herkunft ?? '';
    _gebinde.text = produkt?.gebinde ?? '';
    _fuellmenge.text = produkt?.fuellmengeMl?.toString() ?? '';
    _barcode.text = produkt?.barcode ?? '';
    _notiz.text = produkt?.notiz ?? '';
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _marke,
      _brauerei,
      _sorte,
      _alkohol,
      _herkunft,
      _gebinde,
      _fuellmenge,
      _barcode,
      _notiz,
    ]) {
      controller.dispose();
    }
    for (final fokus in [
      _nameFokus,
      _barcodeFokus,
      _alkoholFokus,
      _fuellmengeFokus,
      _fehlerFokus,
    ]) {
      fokus.dispose();
    }
    super.dispose();
  }

  String? _minimalangabePruefen(String? _) {
    if (_name.text.trim().isEmpty && _barcode.text.trim().isEmpty) {
      return 'Name oder Barcode ist erforderlich.';
    }
    return null;
  }

  String? _alkoholPruefen(String? wert) {
    final eingabe = wert?.trim() ?? '';
    if (eingabe.isEmpty) return null;
    final zahl = double.tryParse(eingabe.replaceAll(',', '.'));
    if (zahl == null || zahl < 0 || zahl > 100) {
      return 'Bitte einen Wert zwischen 0 und 100 eingeben.';
    }
    return null;
  }

  String? _fuellmengePruefen(String? wert) {
    final eingabe = wert?.trim() ?? '';
    if (eingabe.isEmpty) return null;
    final zahl = int.tryParse(eingabe);
    if (zahl == null || zahl <= 0) {
      return 'Bitte eine positive Füllmenge eingeben.';
    }
    return null;
  }

  Future<void> _speichern() async {
    FocusScope.of(context).unfocus();
    final gueltig = _formularKey.currentState?.validate() ?? false;
    if (!gueltig) {
      setState(() {
        _zeigtFehler = true;
        _fehler = _validierungsfehler();
      });
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

    setState(() {
      _zeigtFehler = false;
      _speichert = true;
    });
    final vorher = widget.produkt;
    final jetzt = DateTime.now().toUtc();
    final produkt = Produkt(
      id: vorher?.id ?? widget.idGenerator.neueId(),
      name: _name.text.trim(),
      produktart: _produktart,
      marke: _wert(_marke),
      brauerei: _wert(_brauerei),
      sorte: _wert(_sorte),
      alkoholgehalt: _kommazahl(_alkohol),
      herkunft: _wert(_herkunft),
      gebinde: _wert(_gebinde),
      fuellmengeMl: int.tryParse(_fuellmenge.text.trim()),
      barcode: _wert(_barcode),
      notiz: _wert(_notiz),
      erstelltAm: vorher?.erstelltAm ?? jetzt,
      geaendertAm: jetzt,
    );
    try {
      await widget.repository.speichereProdukt(produkt);
      if (mounted) Navigator.of(context).pop(produkt);
    } catch (_) {
      if (!mounted) return;
      setState(() => _speichert = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Das Produkt konnte nicht gespeichert werden.'),
        ),
      );
    }
  }

  List<_Validierungsfehler> _validierungsfehler() {
    final fehler = <_Validierungsfehler>[];
    if (_name.text.trim().isEmpty && _barcode.text.trim().isEmpty) {
      fehler.add(_Validierungsfehler(
        'Name oder Barcode ist erforderlich.',
        _nameFokus,
      ));
    }
    if (_alkoholPruefen(_alkohol.text) != null) {
      fehler.add(_Validierungsfehler(
        'Alkoholgehalt muss zwischen 0 und 100 liegen.',
        _alkoholFokus,
      ));
    }
    if (_fuellmengePruefen(_fuellmenge.text) != null) {
      fehler.add(_Validierungsfehler(
        'Füllmenge muss eine positive ganze Zahl sein.',
        _fuellmengeFokus,
      ));
    }
    return fehler;
  }

  String? _wert(TextEditingController controller) {
    final wert = controller.text.trim();
    return wert.isEmpty ? null : wert;
  }

  double? _kommazahl(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.produkt == null ? 'Produkt anlegen' : 'Produkt bearbeiten',
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formularKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_zeigtFehler)
                  FormularFehlersammler(
                    key: _fehlerKey,
                    focusNode: _fehlerFokus,
                    fehler: [
                      for (final fehler in _fehler) (fehler.text, fehler.fokus),
                    ],
                  ),
                DropdownButtonFormField<Produktart>(
                  initialValue: _produktart,
                  decoration: const InputDecoration(labelText: 'Produktart'),
                  items: const [
                    DropdownMenuItem(value: Produktart.bier, child: Text('Bier')),
                    DropdownMenuItem(
                      value: Produktart.sonstiges,
                      child: Text('Anderes Produkt'),
                    ),
                  ],
                  onChanged: (wert) => setState(() => _produktart = wert!),
                ),
                const SizedBox(height: 16),
                _textfeld(
                  _name,
                  'Name',
                  maxLength: 120,
                  focusNode: _nameFokus,
                  validator: _minimalangabePruefen,
                ),
                _textfeld(
                  _barcode,
                  'Barcode',
                  maxLength: 80,
                  validator: _minimalangabePruefen,
                  keyboardType: TextInputType.number,
                  focusNode: _barcodeFokus,
                ),
                _textfeld(_marke, 'Marke (optional)', maxLength: 120),
                if (_produktart == Produktart.bier) ...[
                  _textfeld(_brauerei, 'Brauerei (optional)', maxLength: 120),
                  _textfeld(_sorte, 'Sorte (optional)', maxLength: 80),
                  _textfeld(
                    _alkohol,
                    'Alkoholgehalt in % (optional)',
                    maxLength: 5,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _alkoholPruefen,
                    focusNode: _alkoholFokus,
                  ),
                ],
                _textfeld(_herkunft, 'Herkunft (optional)', maxLength: 120),
                _textfeld(_gebinde, 'Gebinde (optional)', maxLength: 80),
                _textfeld(
                  _fuellmenge,
                  'Füllmenge in ml (optional)',
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  validator: _fuellmengePruefen,
                  focusNode: _fuellmengeFokus,
                ),
                _textfeld(_notiz, 'Notiz (optional)', maxLength: 1000, maxLines: 4),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _speichert ? null : _speichern,
                  child: Text(_speichert ? 'Speichert …' : 'Produkt speichern'),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _textfeld(
    TextEditingController controller,
    String label, {
    int maxLength = 120,
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
