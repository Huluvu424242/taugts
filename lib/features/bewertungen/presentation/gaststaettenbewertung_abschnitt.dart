import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/presentation/formular_fehler.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';

class GaststaettenbewertungAbschnitt extends StatefulWidget {
  const GaststaettenbewertungAbschnitt({
    required this.repository,
    required this.idGenerator,
    required this.erlebnis,
    required this.ort,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Erlebnis erlebnis;
  final Ort? ort;

  @override
  State<GaststaettenbewertungAbschnitt> createState() =>
      _GaststaettenbewertungAbschnittState();
}

class _GaststaettenbewertungAbschnittState
    extends State<GaststaettenbewertungAbschnitt> {
  final _fehlerFokus = FocusNode();
  final _ersterWertFokus = FocusNode();
  final _notizFokus = FocusNode();
  late Future<_Daten> _laden;
  var _lokalGespeichert = false;

  @override
  void initState() {
    super.initState();
    _laden = _ladeDaten();
  }

  Future<_Daten> _ladeDaten() async {
    final werte = await Future.wait([
      widget.repository.ladeAktiveKriterienFuerObjektart(
        KriteriumObjektart.gastronomie,
      ),
      widget.repository.ladeOrtsbewertungFuerErlebnis(widget.erlebnis.id),
    ]);
    return _Daten(
      kriterien: werte[0] as List<Bewertungskriterium>,
      vorhanden: werte[1] as OrtsbewertungMitWerten?,
    );
  }

  @override
  void dispose() {
    _fehlerFokus.dispose();
    _ersterWertFokus.dispose();
    _notizFokus.dispose();
    super.dispose();
  }

  void _neuLaden() => setState(() {
        _lokalGespeichert = false;
        _laden = _ladeDaten();
      });

  @override
  Widget build(BuildContext context) {
    final ort = widget.ort;
    return ExpansionTile(
      maintainState: true,
      title: const Text('Gaststätte bewerten'),
      subtitle: ort == null
          ? const Text('Bitte zuerst eine Gaststätte auswählen.')
          : FutureBuilder<_Daten>(
              future: _laden,
              builder: (context, snapshot) {
                final text = _lokalGespeichert || snapshot.data?.vorhanden != null
                    ? 'Für diesen Besuch liegt eine Bewertung vor.'
                    : snapshot.hasError
                        ? 'Der Bewertungsstatus konnte nicht geladen werden.'
                        : snapshot.hasData
                            ? 'Noch keine Bewertung für diesen Besuch.'
                            : 'Bewertungsstatus wird geladen.';
                return Text(text);
              },
            ),
      children: [
        if (ort == null)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('Bestellung und Produktbewertungen bleiben ohne Gaststättenbewertung nutzbar.'),
          )
        else
          FutureBuilder<_Daten>(
            future: _laden,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: const Text(
                          'Die Gaststättenbewertung konnte nicht geladen werden.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _neuLaden,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Bewertung erneut laden'),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Semantics(
                    label: 'Gaststättenbewertung wird geladen',
                    child: const LinearProgressIndicator(),
                  ),
                );
              }
              return _Formular(
                repository: widget.repository,
                idGenerator: widget.idGenerator,
                erlebnis: widget.erlebnis,
                ort: ort,
                daten: snapshot.data!,
                fehlerFokus: _fehlerFokus,
                ersterWertFokus: _ersterWertFokus,
                notizFokus: _notizFokus,
                onGespeichert: () => setState(() => _lokalGespeichert = true),
              );
            },
          ),
      ],
    );
  }
}

class _Formular extends StatefulWidget {
  const _Formular({
    required this.repository,
    required this.idGenerator,
    required this.erlebnis,
    required this.ort,
    required this.daten,
    required this.fehlerFokus,
    required this.ersterWertFokus,
    required this.notizFokus,
    required this.onGespeichert,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Erlebnis erlebnis;
  final Ort ort;
  final _Daten daten;
  final FocusNode fehlerFokus;
  final FocusNode ersterWertFokus;
  final FocusNode notizFokus;
  final VoidCallback onGespeichert;

  @override
  State<_Formular> createState() => _FormularState();
}

class _FormularState extends State<_Formular> {
  late final TextEditingController _notiz;
  late final Map<String, double?> _werte;
  var _eingabeFehlt = false;
  var _speichert = false;
  var _gespeichert = false;

  @override
  void initState() {
    super.initState();
    final vorhanden = {
      for (final wert in widget.daten.vorhanden?.werte ?? <Bewertung>[])
        wert.kriteriumId: wert.wert,
    };
    _werte = {
      for (final kriterium in widget.daten.kriterien)
        kriterium.id: vorhanden[kriterium.id],
    };
    _notiz = TextEditingController(
      text: widget.daten.vorhanden?.ortsbewertung.notiz ?? '',
    );
  }

  @override
  void dispose() {
    _notiz.dispose();
    super.dispose();
  }

  Future<void> _speichern() async {
    if (_werte.values.every((wert) => wert == null) &&
        _notiz.text.trim().isEmpty) {
      setState(() => _eingabeFehlt = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Gaststättenbewertung prüfen.')),
      );
      widget.fehlerFokus.requestFocus();
      return;
    }
    setState(() => _speichert = true);
    final jetzt = DateTime.now().toUtc();
    final bisher = widget.daten.vorhanden;
    final id = bisher?.ortsbewertung.id ?? widget.idGenerator.neueId();
    final vorhandeneWerte = {
      for (final wert in bisher?.werte ?? <Bewertung>[])
        wert.kriteriumId: wert,
    };
    try {
      await widget.repository.speichereOrtsbewertung(
        erlebnis: widget.erlebnis,
        ort: widget.ort,
        ortsbewertung: Ortsbewertung(
          id: id,
          erlebnisId: widget.erlebnis.id,
          ortId: widget.ort.id,
          herkunftProfilId: widget.erlebnis.herkunftProfilId,
          bewertetAm: widget.erlebnis.tatsaechlicherBeginn ?? widget.erlebnis.erlebtAm,
          notiz: _notiz.text.trim().isEmpty ? null : _notiz.text.trim(),
          erstelltAm: bisher?.ortsbewertung.erstelltAm ?? jetzt,
          geaendertAm: jetzt,
        ),
        bewertungen: [
          for (final wert in bisher?.werte ?? <Bewertung>[])
            if (!_werte.containsKey(wert.kriteriumId)) wert,
          for (final eintrag in _werte.entries)
            if (eintrag.value != null)
              Bewertung(
                id: vorhandeneWerte[eintrag.key]?.id ?? widget.idGenerator.neueId(),
                erlebnisId: widget.erlebnis.id,
                ortId: widget.ort.id,
                ortsbewertungId: id,
                kriteriumId: eintrag.key,
                herkunftProfilId: widget.erlebnis.herkunftProfilId,
                wert: eintrag.value!,
                erstelltAm: vorhandeneWerte[eintrag.key]?.erstelltAm ?? jetzt,
                geaendertAm: jetzt,
              ),
        ],
      );
      if (!mounted) return;
      setState(() {
        _speichert = false;
        _gespeichert = true;
        _eingabeFehlt = false;
      });
      widget.onGespeichert();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gaststättenbewertung gespeichert.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _speichert = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Die Gaststättenbewertung konnte nicht gespeichert werden.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_eingabeFehlt)
              FormularFehlersammler(
                focusNode: widget.fehlerFokus,
                fehler: [
                  (
                    'Mindestens eine Wertung oder Notiz ist erforderlich.',
                    widget.daten.kriterien.isEmpty
                        ? widget.notizFokus
                        : widget.ersterWertFokus,
                  ),
                ],
              ),
            if (widget.daten.kriterien.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Keine aktiven Gaststättenkriterien. Eine Notiz kann dennoch gespeichert werden.',
                ),
              ),
            for (var index = 0; index < widget.daten.kriterien.length; index++)
              DropdownButtonFormField<double?>(
                focusNode: index == 0 ? widget.ersterWertFokus : null,
                initialValue: _werte[widget.daten.kriterien[index].id],
                decoration: InputDecoration(
                  labelText: widget.daten.kriterien[index].name,
                  helperText: widget.daten.kriterien[index].beschreibung,
                ),
                items: const [
                  DropdownMenuItem<double?>(value: null, child: Text('Nicht bewertet')),
                  DropdownMenuItem(value: 1, child: Text('1 – taugt gar nicht')),
                  DropdownMenuItem(value: 2, child: Text('2 – taugt eher nicht')),
                  DropdownMenuItem(value: 3, child: Text('3 – teils, teils')),
                  DropdownMenuItem(value: 4, child: Text('4 – taugt eher')),
                  DropdownMenuItem(value: 5, child: Text('5 – taugt sehr')),
                ],
                onChanged: _speichert
                    ? null
                    : (wert) => setState(() {
                          _werte[widget.daten.kriterien[index].id] = wert;
                          _eingabeFehlt = false;
                          _gespeichert = false;
                        }),
              ),
            TextField(
              controller: _notiz,
              focusNode: widget.notizFokus,
              maxLength: 1000,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notiz (optional)'),
              onChanged: (_) => setState(() {
                _eingabeFehlt = false;
                _gespeichert = false;
              }),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _speichert ? null : _speichern,
              icon: const Icon(Icons.save_outlined),
              label: Text(_gespeichert ? 'Bewertung gespeichert' : 'Bewertung speichern'),
            ),
          ],
        ),
      );
}

class _Daten {
  const _Daten({required this.kriterien, required this.vorhanden});

  final List<Bewertungskriterium> kriterien;
  final OrtsbewertungMitWerten? vorhanden;
}
