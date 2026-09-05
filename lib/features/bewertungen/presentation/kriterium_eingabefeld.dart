import 'package:flutter/material.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';

class KriteriumEingabewert {
  const KriteriumEingabewert({this.zahl, this.text, this.fehler});

  factory KriteriumEingabewert.ausBewertung(Bewertung? bewertung) =>
      KriteriumEingabewert(
        zahl: bewertung?.wert,
        text: bewertung?.textWert,
      );

  final double? zahl;
  final String? text;
  final String? fehler;

  bool get hatWert => zahl != null || (text?.trim().isNotEmpty ?? false);
}

class KriteriumEingabefeld extends StatefulWidget {
  const KriteriumEingabefeld({
    required this.kriterium,
    required this.wert,
    required this.onChanged,
    this.focusNode,
    this.errorText,
    this.enabled = true,
    super.key,
  });

  final Bewertungskriterium kriterium;
  final KriteriumEingabewert wert;
  final ValueChanged<KriteriumEingabewert> onChanged;
  final FocusNode? focusNode;
  final String? errorText;
  final bool enabled;

  @override
  State<KriteriumEingabefeld> createState() => _KriteriumEingabefeldState();
}

class _KriteriumEingabefeldState extends State<KriteriumEingabefeld> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _anzeigetext(widget.wert));
  }

  @override
  void didUpdateWidget(covariant KriteriumEingabefeld oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.kriterium.eingabetyp != oldWidget.kriterium.eingabetyp) {
      _textController.text = _anzeigetext(widget.wert);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _anzeigetext(KriteriumEingabewert wert) =>
      widget.kriterium.eingabetyp == KriteriumEingabetyp.zahl
          ? wert.zahl?.toString() ?? ''
          : wert.text ?? '';

  InputDecoration _dekoration({String? helperText}) => InputDecoration(
        labelText: widget.kriterium.name,
        helperText: helperText ?? widget.kriterium.beschreibung,
        errorText: widget.errorText ?? widget.wert.fehler,
      );

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: widget.kriterium.name,
        child: switch (widget.kriterium.eingabetyp) {
          KriteriumEingabetyp.wertung => _skala(false),
          KriteriumEingabetyp.intensitaet => _skala(true),
          KriteriumEingabetyp.jaNein => _jaNein(),
          KriteriumEingabetyp.zahl => _zahl(),
          KriteriumEingabetyp.auswahl => _auswahl(),
          KriteriumEingabetyp.freitext => _freitext(),
        },
      );

  Widget _skala(bool intensitaet) => DropdownButtonFormField<double?>(
        key: ValueKey('kriterium-${widget.kriterium.id}'),
        initialValue: widget.wert.zahl,
        focusNode: widget.focusNode,
        isExpanded: true,
        decoration: _dekoration(),
        items: [
          const DropdownMenuItem<double?>(
            value: null,
            child: Text('Nicht bewertet'),
          ),
          for (var wert = 1; wert <= 5; wert++)
            DropdownMenuItem<double?>(
              value: wert.toDouble(),
              child: Text(_skalaLabel(wert, intensitaet)),
            ),
        ],
        onChanged: widget.enabled
            ? (wert) => widget.onChanged(KriteriumEingabewert(zahl: wert))
            : null,
      );

  String _skalaLabel(int wert, bool intensitaet) {
    if (intensitaet) {
      return switch (wert) {
        1 => '1 – sehr gering',
        2 => '2 – gering',
        3 => '3 – mittel',
        4 => '4 – stark',
        _ => '5 – sehr stark',
      };
    }
    return switch (wert) {
      1 => '1 – taugt gar nicht',
      2 => '2 – taugt eher nicht',
      3 => '3 – teils, teils',
      4 => '4 – taugt eher',
      _ => '5 – taugt sehr',
    };
  }

  Widget _jaNein() => DropdownButtonFormField<double?>(
        key: ValueKey('kriterium-${widget.kriterium.id}'),
        initialValue: widget.wert.zahl,
        focusNode: widget.focusNode,
        isExpanded: true,
        decoration: _dekoration(),
        items: const [
          DropdownMenuItem<double?>(
            value: null,
            child: Text('Nicht bewertet'),
          ),
          DropdownMenuItem<double?>(value: 1, child: Text('Ja')),
          DropdownMenuItem<double?>(value: 0, child: Text('Nein')),
        ],
        onChanged: widget.enabled
            ? (wert) => widget.onChanged(KriteriumEingabewert(zahl: wert))
            : null,
      );

  Widget _zahl() => TextField(
        key: ValueKey('kriterium-${widget.kriterium.id}'),
        controller: _textController,
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        maxLength: 32,
        decoration: _dekoration(
          helperText: widget.kriterium.beschreibung ??
              'Freie Zahl; Dezimaltrennzeichen Komma oder Punkt.',
        ),
        onChanged: (text) {
          final getrimmt = text.trim();
          if (getrimmt.isEmpty) {
            widget.onChanged(const KriteriumEingabewert());
            return;
          }
          final zahl = double.tryParse(getrimmt.replaceAll(',', '.'));
          widget.onChanged(
            zahl == null
                ? const KriteriumEingabewert(
                    fehler: 'Bitte eine gültige Zahl eingeben.',
                  )
                : KriteriumEingabewert(zahl: zahl),
          );
        },
      );

  Widget _auswahl() {
    final auswahlwerte = widget.kriterium.auswahlwerte;
    final hatAuswahl = auswahlwerte.isNotEmpty;
    return DropdownButtonFormField<String?>(
      key: ValueKey('kriterium-${widget.kriterium.id}'),
      initialValue: widget.wert.text,
      focusNode: widget.focusNode,
      isExpanded: true,
      decoration: _dekoration(
        helperText: hatAuswahl
            ? widget.kriterium.beschreibung
            : 'Für dieses Kriterium sind keine Auswahlwerte hinterlegt.',
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Nicht bewertet'),
        ),
        for (final wert in auswahlwerte)
          DropdownMenuItem<String?>(value: wert, child: Text(wert)),
      ],
      onChanged: widget.enabled && hatAuswahl
          ? (wert) => widget.onChanged(KriteriumEingabewert(text: wert))
          : null,
    );
  }

  Widget _freitext() => TextField(
        key: ValueKey('kriterium-${widget.kriterium.id}'),
        controller: _textController,
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        maxLength: 500,
        maxLines: 3,
        decoration: _dekoration(),
        onChanged: (text) {
          final getrimmt = text.trim();
          widget.onChanged(
            getrimmt.isEmpty
                ? const KriteriumEingabewert()
                : KriteriumEingabewert(text: getrimmt),
          );
        },
      );
}
