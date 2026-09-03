import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/presentation/formular_fehler.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';

class GaststaettenbewertungController {
  Object? _owner;
  Future<void> Function(Erlebnis erlebnis)? _speicherAktion;

  Future<void> speichereFallsGeaendert(Erlebnis erlebnis) async {
    final aktion = _speicherAktion;
    if (aktion != null) await aktion(erlebnis);
  }

  void _verbinde(
    Object owner,
    Future<void> Function(Erlebnis erlebnis) speicherAktion,
  ) {
    _owner = owner;
    _speicherAktion = speicherAktion;
  }

  void _trenne(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _speicherAktion = null;
  }
}

class GaststaettenbewertungAbschnitt extends StatefulWidget {
  const GaststaettenbewertungAbschnitt({
    required this.repository,
    required this.idGenerator,
    required this.erlebnis,
    required this.ort,
    this.controller,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Erlebnis erlebnis;
  final Ort? ort;
  final GaststaettenbewertungController? controller;

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

  bool get _istGeschaeft => widget.erlebnis.typ == Erlebnistyp.einkauf;

  String get _bezeichnung => _istGeschaeft ? 'Geschäft' : 'Gaststätte';

  String get _kontext => _istGeschaeft ? 'Einkauf' : 'Besuch';

  KriteriumObjektart get _objektart => _istGeschaeft
      ? KriteriumObjektart.geschaeft
      : KriteriumObjektart.gastronomie;

  @override
  void initState() {
    super.initState();
    _laden = _ladeDaten();
  }

  Future<_Daten> _ladeDaten() async {
    final werte = await Future.wait([
      widget.repository.ladeAktiveKriterienFuerObjektart(_objektart),
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
      title: Text('$_bezeichnung bewerten'),
      subtitle: ort == null
          ? Text(
              'Bitte zuerst ${_istGeschaeft ? 'ein Geschäft' : 'eine Gaststätte'} auswählen.',
            )
          : FutureBuilder<_Daten>(
              future: _laden,
              builder: (context, snapshot) {
                final text = _lokalGespeichert ||
                        snapshot.data?.vorhanden != null
                    ? 'Für diesen $_kontext liegt eine Bewertung vor.'
                    : snapshot.hasError
                        ? 'Der Bewertungsstatus konnte nicht geladen werden.'
                        : snapshot.hasData
                            ? 'Noch keine Bewertung für diesen $_kontext.'
                            : 'Bewertungsstatus wird geladen.';
                return Text(text);
              },
            ),
      children: [
        if (ort == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '${_istGeschaeft ? 'Einkaufsliste' : 'Bestellung'} und Produktbewertungen bleiben ohne ${_istGeschaeft ? 'Geschäftsbewertung' : 'Gaststättenbewertung'} nutzbar.',
            ),
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
                        child: Text(
                          'Die ${_istGeschaeft ? 'Geschäftsbewertung' : 'Gaststättenbewertung'} konnte nicht geladen werden.',
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
                    label:
                        '${_istGeschaeft ? 'Geschäftsbewertung' : 'Gaststättenbewertung'} wird geladen',
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
                istGeschaeft: _istGeschaeft,
                controller: widget.controller,
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
    required this.istGeschaeft,
    required this.fehlerFokus,
    required this.ersterWertFokus,
    required this.notizFokus,
    required this.onGespeichert,
    this.controller,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Erlebnis erlebnis;
  final Ort ort;
  final _Daten daten;
  final bool istGeschaeft;
  final GaststaettenbewertungController? controller;
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
  late OrtsbewertungMitWerten? _bisher;
  var _eingabeFehlt = false;
  var _speichert = false;
  var _gespeichert = false;
  var _geaendert = false;

  String get _bezeichnung =>
      widget.istGeschaeft ? 'Geschäftsbewertung' : 'Gaststättenbewertung';

  bool get _hatEingabe =>
      _werte.values.any((wert) => wert != null) || _notiz.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _bisher = widget.daten.vorhanden;
    final vorhanden = {
      for (final wert in _bisher?.werte ?? <Bewertung>[])
        wert.kriteriumId: wert.wert,
    };
    _werte = {
      for (final kriterium in widget.daten.kriterien)
        kriterium.id: vorhanden[kriterium.id],
    };
    _notiz = TextEditingController(
      text: _bisher?.ortsbewertung.notiz ?? '',
    );
    widget.controller?._verbinde(this, _speichereFallsGeaendert);
  }

  @override
  void didUpdateWidget(covariant _Formular oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller?._trenne(this);
    widget.controller?._verbinde(this, _speichereFallsGeaendert);
  }

  @override
  void dispose() {
    widget.controller?._trenne(this);
    _notiz.dispose();
    super.dispose();
  }

  Future<void> _speichereOrtsbewertung(Erlebnis erlebnis) async {
    final jetzt = DateTime.now().toUtc();
    final id = _bisher?.ortsbewertung.id ?? widget.idGenerator.neueId();
    final vorhandeneWerte = {
      for (final wert in _bisher?.werte ?? <Bewertung>[])
        wert.kriteriumId: wert,
    };
    final ortsbewertung = Ortsbewertung(
      id: id,
      erlebnisId: erlebnis.id,
      ortId: widget.ort.id,
      herkunftProfilId: erlebnis.herkunftProfilId,
      bewertetAm: erlebnis.tatsaechlicherBeginn ?? erlebnis.erlebtAm,
      notiz: _notiz.text.trim().isEmpty ? null : _notiz.text.trim(),
      erstelltAm: _bisher?.ortsbewertung.erstelltAm ?? jetzt,
      geaendertAm: jetzt,
    );
    final bewertungen = <Bewertung>[
      for (final wert in _bisher?.werte ?? <Bewertung>[])
        if (!_werte.containsKey(wert.kriteriumId)) wert,
      for (final eintrag in _werte.entries)
        if (eintrag.value != null)
          Bewertung(
            id: vorhandeneWerte[eintrag.key]?.id ??
                widget.idGenerator.neueId(),
            erlebnisId: erlebnis.id,
            ortId: widget.ort.id,
            ortsbewertungId: id,
            kriteriumId: eintrag.key,
            herkunftProfilId: erlebnis.herkunftProfilId,
            wert: eintrag.value!,
            erstelltAm: vorhandeneWerte[eintrag.key]?.erstelltAm ?? jetzt,
            geaendertAm: jetzt,
          ),
    ];
    await widget.repository.speichereOrtsbewertung(
      erlebnis: erlebnis,
      ort: widget.ort,
      ortsbewertung: ortsbewertung,
      bewertungen: bewertungen,
    );
    _bisher = OrtsbewertungMitWerten(
      ortsbewertung: ortsbewertung,
      werte: bewertungen,
    );
  }

  Future<void> _speichereFallsGeaendert(Erlebnis erlebnis) async {
    if (!_geaendert || !_hatEingabe) return;
    await _speichereOrtsbewertung(erlebnis);
    if (!mounted) return;
    setState(() {
      _gespeichert = true;
      _geaendert = false;
      _eingabeFehlt = false;
    });
    widget.onGespeichert();
  }

  Future<void> _speichern() async {
    if (!_hatEingabe) {
      setState(() => _eingabeFehlt = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bitte $_bezeichnung prüfen.')),
      );
      widget.fehlerFokus.requestFocus();
      return;
    }
    setState(() => _speichert = true);
    try {
      await _speichereOrtsbewertung(widget.erlebnis);
      if (!mounted) return;
      setState(() {
        _speichert = false;
        _gespeichert = true;
        _geaendert = false;
        _eingabeFehlt = false;
      });
      widget.onGespeichert();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_bezeichnung gespeichert.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _speichert = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Die $_bezeichnung konnte nicht gespeichert werden.'),
        ),
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
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Keine aktiven ${widget.istGeschaeft ? 'Geschäfts' : 'Gaststätten'}kriterien. Eine Notiz kann dennoch gespeichert werden.',
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
                  DropdownMenuItem<double?>(
                    value: null,
                    child: Text('Nicht bewertet'),
                  ),
                  DropdownMenuItem(
                    value: 1,
                    child: Text('1 – taugt gar nicht'),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Text('2 – taugt eher nicht'),
                  ),
                  DropdownMenuItem(
                    value: 3,
                    child: Text('3 – teils, teils'),
                  ),
                  DropdownMenuItem(
                    value: 4,
                    child: Text('4 – taugt eher'),
                  ),
                  DropdownMenuItem(
                    value: 5,
                    child: Text('5 – taugt sehr'),
                  ),
                ],
                onChanged: _speichert
                    ? null
                    : (wert) => setState(() {
                          _werte[widget.daten.kriterien[index].id] = wert;
                          _eingabeFehlt = false;
                          _gespeichert = false;
                          _geaendert = true;
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
                _geaendert = true;
              }),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _speichert ? null : _speichern,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                _gespeichert ? 'Bewertung gespeichert' : 'Bewertung speichern',
              ),
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
