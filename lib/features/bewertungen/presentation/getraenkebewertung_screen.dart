import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/presentation/formular_fehler.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/profil/models/profil.dart';

class GetraenkebewertungScreen extends StatefulWidget {
  const GetraenkebewertungScreen({
    required this.repository,
    required this.idGenerator,
    required this.profil,
    required this.erlebnis,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Profil profil;
  final Erlebnis erlebnis;

  @override
  State<GetraenkebewertungScreen> createState() =>
      _GetraenkebewertungScreenState();
}

class _GetraenkebewertungScreenState extends State<GetraenkebewertungScreen> {
  late Future<_BewertungsDaten> _laden = _datenLaden();

  Future<_BewertungsDaten> _datenLaden() async {
    final ortId = widget.erlebnis.konsumortId ?? widget.erlebnis.kaufortId;
    final werte = await Future.wait([
      widget.repository.ladeProdukt(widget.erlebnis.produktId),
      widget.repository.ladeAktiveGetraenkekriterien(),
      widget.repository.ladeBewertungenFuerErlebnis(widget.erlebnis.id),
      ortId == null
          ? Future<Ort?>.value()
          : widget.repository.ladeOrt(ortId),
    ]);
    final produkt = werte[0] as Produkt?;
    if (produkt == null) {
      throw StateError('Das Produkt des Erlebnisses wurde nicht gefunden.');
    }
    return _BewertungsDaten(
      produkt: produkt,
      kriterien: werte[1] as List<Bewertungskriterium>,
      bewertungen: werte[2] as List<Bewertung>,
      ort: werte[3] as Ort?,
    );
  }

  void _erneutLaden() {
    setState(() => _laden = _datenLaden());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Getränk bewerten'),
          actions: const [
            AppSupportMenu(
              contextName: SupportKontexte.getraenkBewertung,
            ),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<_BewertungsDaten>(
            future: _laden,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Die Bewertung konnte nicht geladen werden.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _erneutLaden,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Erneut versuchen'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return Center(
                  child: Semantics(
                    label: 'Bewertung wird geladen',
                    child: const CircularProgressIndicator(),
                  ),
                );
              }
              return _BewertungsFormular(
                key: ValueKey(widget.erlebnis.id),
                repository: widget.repository,
                idGenerator: widget.idGenerator,
                profil: widget.profil,
                erlebnis: widget.erlebnis,
                daten: snapshot.data!,
              );
            },
          ),
        ),
      );
}

class _BewertungsFormular extends StatefulWidget {
  const _BewertungsFormular({
    required this.repository,
    required this.idGenerator,
    required this.profil,
    required this.erlebnis,
    required this.daten,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Profil profil;
  final Erlebnis erlebnis;
  final _BewertungsDaten daten;

  @override
  State<_BewertungsFormular> createState() => _BewertungsFormularState();
}

class _BewertungsFormularState extends State<_BewertungsFormular> {
  final _scrollController = ScrollController();
  final _fehlerKey = GlobalKey();
  final _fehlerFokus = FocusNode();
  final _ersterKriteriumFokus = FocusNode();
  late final TextEditingController _notiz;
  late final Map<String, double?> _werte;
  var _eingabeFehlt = false;
  var _speichert = false;

  @override
  void initState() {
    super.initState();
    _notiz = TextEditingController(text: widget.erlebnis.notiz ?? '');
    final vorhandene = {
      for (final bewertung in widget.daten.bewertungen)
        bewertung.kriteriumId: bewertung,
    };
    _werte = {
      for (final kriterium in widget.daten.kriterien)
        kriterium.id: vorhandene[kriterium.id]?.wert,
    };
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fehlerFokus.dispose();
    _ersterKriteriumFokus.dispose();
    _notiz.dispose();
    super.dispose();
  }

  Future<void> _speichern() async {
    final notiz = _notiz.text.trim();
    if (_werte.values.every((wert) => wert == null) && notiz.isEmpty) {
      setState(() => _eingabeFehlt = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Eingaben prüfen.')),
      );
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      _fehlerFokus.requestFocus();
      return;
    }

    setState(() => _speichert = true);
    final jetzt = DateTime.now().toUtc();
    final vorhandene = {
      for (final bewertung in widget.daten.bewertungen)
        bewertung.kriteriumId: bewertung,
    };
    final aktiveIds =
        widget.daten.kriterien.map((kriterium) => kriterium.id).toSet();
    final bewertungen = <Bewertung>[
      for (final bewertung in widget.daten.bewertungen)
        if (!aktiveIds.contains(bewertung.kriteriumId)) bewertung,
      for (final eintrag in _werte.entries)
        if (eintrag.value != null)
          Bewertung(
            id: vorhandene[eintrag.key]?.id ?? widget.idGenerator.neueId(),
            erlebnisId: widget.erlebnis.id,
            kriteriumId: eintrag.key,
            herkunftProfilId: widget.profil.id,
            wert: eintrag.value!,
            erstelltAm: vorhandene[eintrag.key]?.erstelltAm ?? jetzt,
            geaendertAm: jetzt,
          ),
    ];
    final erlebnis = widget.erlebnis.kopiereMit(
      notiz: notiz.isEmpty ? null : notiz,
      istEntwurf: false,
      geaendertAm: jetzt,
    );

    try {
      await widget.repository.speichereGetraenkebewertung(
        erlebnis: erlebnis,
        bewertungen: bewertungen,
      );
      if (!mounted) return;
      Navigator.of(context).pop(erlebnis);
    } catch (_) {
      if (!mounted) return;
      setState(() => _speichert = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Die Bewertung konnte nicht gespeichert werden.'),
        ),
      );
    }
  }

  String _wertLabel(Bewertungskriterium kriterium, int wert) {
    if (kriterium.eingabetyp == KriteriumEingabetyp.intensitaet) {
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

  @override
  Widget build(BuildContext context) {
    final datum = MaterialLocalizations.of(context).formatFullDate(
      widget.erlebnis.erlebtAm.toLocal(),
    );
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              if (_eingabeFehlt)
                FormularFehlersammler(
                  key: _fehlerKey,
                  focusNode: _fehlerFokus,
                  fehler: [
                    (
                      'Mindestens eine Bewertung oder Notiz ist erforderlich.',
                      _ersterKriteriumFokus,
                    ),
                  ],
                ),
              Semantics(
                header: true,
                child: Text(
                  widget.daten.produkt.anzeigetitel,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.daten.ort == null
                    ? 'Erlebnis vom $datum'
                    : '${widget.daten.ort!.name} · $datum',
              ),
              const SizedBox(height: 8),
              const Text(
                'Alle Kriterien sind optional. Das Gesamturteil wird nicht '
                'aus den Einzelwerten berechnet.',
              ),
              const SizedBox(height: 24),
              for (var index = 0;
                  index < widget.daten.kriterien.length;
                  index++) ...[
                _KriteriumAuswahl(
                  kriterium: widget.daten.kriterien[index],
                  wert: _werte[widget.daten.kriterien[index].id],
                  focusNode: index == 0 ? _ersterKriteriumFokus : null,
                  errorText: index == 0 && _eingabeFehlt
                      ? 'Bitte eine Bewertung wählen oder eine Notiz eingeben.'
                      : null,
                  onChanged: (wert) {
                    setState(() {
                      _werte[widget.daten.kriterien[index].id] = wert;
                      _eingabeFehlt = false;
                    });
                  },
                  wertLabel: _wertLabel,
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _notiz,
                maxLength: 1000,
                maxLines: 4,
                onChanged: (_) {
                  if (_eingabeFehlt && _notiz.text.trim().isNotEmpty) {
                    setState(() => _eingabeFehlt = false);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Bewertungsnotiz (optional)',
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _speichert ? null : _speichern,
              icon: _speichert
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _speichert
                    ? 'Bewertung wird gespeichert'
                    : 'Bewertung speichern',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KriteriumAuswahl extends StatelessWidget {
  const _KriteriumAuswahl({
    required this.kriterium,
    required this.wert,
    required this.onChanged,
    required this.wertLabel,
    this.focusNode,
    this.errorText,
  });

  final Bewertungskriterium kriterium;
  final double? wert;
  final ValueChanged<double?> onChanged;
  final String Function(Bewertungskriterium, int) wertLabel;
  final FocusNode? focusNode;
  final String? errorText;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: kriterium.name,
        child: DropdownButtonFormField<double>(
          key: ValueKey('kriterium-${kriterium.id}'),
          initialValue: wert,
          focusNode: focusNode,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: kriterium.name,
            helperText: kriterium.beschreibung,
            errorText: errorText,
          ),
          items: [
            const DropdownMenuItem<double>(
              value: null,
              child: Text('Nicht bewertet'),
            ),
            for (var wert = 1; wert <= 5; wert++)
              DropdownMenuItem<double>(
                value: wert.toDouble(),
                child: Text(wertLabel(kriterium, wert)),
              ),
          ],
          onChanged: onChanged,
        ),
      );
}

class _BewertungsDaten {
  const _BewertungsDaten({
    required this.produkt,
    required this.kriterien,
    required this.bewertungen,
    required this.ort,
  });

  final Produkt produkt;
  final List<Bewertungskriterium> kriterien;
  final List<Bewertung> bewertungen;
  final Ort? ort;
}
