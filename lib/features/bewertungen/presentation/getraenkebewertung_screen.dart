import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/presentation/formular_fehler.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/presentation/kriterium_eingabefeld.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/profil/models/profil.dart';

class GetraenkebewertungScreen extends StatefulWidget {
  const GetraenkebewertungScreen({
    required this.repository,
    required this.idGenerator,
    required this.profil,
    required this.erlebnis,
    this.erlebnisposition,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Profil profil;
  final Erlebnis erlebnis;
  final ErlebnispositionMitProdukt? erlebnisposition;

  @override
  State<GetraenkebewertungScreen> createState() =>
      _GetraenkebewertungScreenState();
}

class _GetraenkebewertungScreenState extends State<GetraenkebewertungScreen> {
  late Future<_BewertungsDaten> _laden = _datenLaden();

  Future<_BewertungsDaten> _datenLaden() async {
    final produktId = widget.erlebnisposition?.position.produktId ??
        widget.erlebnis.produktId;
    if (produktId == null) {
      throw StateError('Das Erlebnis enthält noch kein Produkt.');
    }
    final ortId = widget.erlebnis.wirksamerOrtId;
    final werte = await Future.wait([
      widget.repository.ladeProdukt(produktId),
      widget.erlebnisposition == null
          ? widget.repository.ladeAktiveGetraenkekriterien()
          : widget.repository.ladeAktiveKriterienFuerProduktart(
              widget.erlebnisposition!.produkt.produktart,
            ),
      widget.erlebnisposition == null
          ? widget.repository.ladeBewertungenFuerErlebnis(widget.erlebnis.id)
          : widget.repository.ladeBewertungenFuerErlebnisposition(
              widget.erlebnisposition!.position.id,
            ),
      ortId == null ? Future<Ort?>.value() : widget.repository.ladeOrt(ortId),
    ]);
    final produkt = werte[0] as Produkt?;
    if (produkt == null) {
      throw StateError('Das Produkt des Erlebnisses wurde nicht gefunden.');
    }
    return _BewertungsDaten(
      produkt: widget.erlebnisposition?.produkt ?? produkt,
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
          title: Text(
            '${widget.erlebnisposition?.produkt.anzeigetitel ?? 'Getränk'} bewerten',
          ),
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
                erlebnisposition: widget.erlebnisposition,
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
    this.erlebnisposition,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Profil profil;
  final Erlebnis erlebnis;
  final _BewertungsDaten daten;
  final ErlebnispositionMitProdukt? erlebnisposition;

  @override
  State<_BewertungsFormular> createState() => _BewertungsFormularState();
}

class _BewertungsFormularState extends State<_BewertungsFormular> {
  final _scrollController = ScrollController();
  final _fehlerKey = GlobalKey();
  final _fehlerFokus = FocusNode();
  final _notizFokus = FocusNode();
  late final TextEditingController _notiz;
  late final Map<String, KriteriumEingabewert> _werte;
  late final Map<String, FocusNode> _kriteriumFokusse;
  var _eingabeFehlt = false;
  var _validierungAngezeigt = false;
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
        kriterium.id:
            KriteriumEingabewert.ausBewertung(vorhandene[kriterium.id]),
    };
    _kriteriumFokusse = {
      for (final kriterium in widget.daten.kriterien) kriterium.id: FocusNode(),
    };
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fehlerFokus.dispose();
    _notizFokus.dispose();
    for (final fokus in _kriteriumFokusse.values) {
      fokus.dispose();
    }
    _notiz.dispose();
    super.dispose();
  }

  bool get _hatKriteriumwert => _werte.values.any((wert) => wert.hatWert);

  List<(String, FocusNode)> get _formularFehler {
    if (!_validierungAngezeigt) return const [];
    final fehler = <(String, FocusNode)>[];
    if (_eingabeFehlt) {
      fehler.add((
        'Mindestens eine Bewertung oder Notiz ist erforderlich.',
        widget.daten.kriterien.isEmpty
            ? _notizFokus
            : _kriteriumFokusse[widget.daten.kriterien.first.id]!,
      ));
    }
    for (final kriterium in widget.daten.kriterien) {
      final eingabe = _werte[kriterium.id];
      if (eingabe?.fehler != null) {
        fehler.add((
          '${kriterium.name}: ${eingabe!.fehler}',
          _kriteriumFokusse[kriterium.id]!,
        ));
      }
    }
    return fehler;
  }

  Future<void> _zuFehlernNavigieren() async {
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
  }

  Future<void> _speichern() async {
    final notiz = _notiz.text.trim();
    final hatWertfehler = _werte.values.any((wert) => wert.fehler != null);
    _eingabeFehlt = !_hatKriteriumwert && notiz.isEmpty;
    if (_eingabeFehlt || hatWertfehler) {
      setState(() => _validierungAngezeigt = true);
      await _zuFehlernNavigieren();
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
        if (eintrag.value.hatWert)
          Bewertung(
            id: vorhandene[eintrag.key]?.id ?? widget.idGenerator.neueId(),
            erlebnisId: widget.erlebnis.id,
            erlebnisPositionId: widget.erlebnisposition?.position.id,
            kriteriumId: eintrag.key,
            herkunftProfilId: widget.profil.id,
            wert: eintrag.value.zahl,
            textWert: eintrag.value.text,
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
      final position = widget.erlebnisposition?.position;
      if (position == null) {
        await widget.repository.speichereGetraenkebewertung(
          erlebnis: erlebnis,
          bewertungen: bewertungen,
        );
      } else {
        await widget.repository.speichereProduktbewertung(
          erlebnis: erlebnis,
          position: position,
          bewertungen: bewertungen,
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final datum = MaterialLocalizations.of(context).formatFullDate(
      widget.erlebnis.erlebtAm.toLocal(),
    );
    final formularFehler = _formularFehler;
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              if (formularFehler.isNotEmpty)
                FormularFehlersammler(
                  key: _fehlerKey,
                  focusNode: _fehlerFokus,
                  fehler: formularFehler,
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
              Text(
                'Produktart: ${_produktartLabel(widget.daten.produkt.produktart)}',
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
                KriteriumEingabefeld(
                  kriterium: widget.daten.kriterien[index],
                  wert: _werte[widget.daten.kriterien[index].id]!,
                  focusNode:
                      _kriteriumFokusse[widget.daten.kriterien[index].id],
                  enabled: !_speichert,
                  errorText: index == 0 && _eingabeFehlt
                      ? 'Bitte eine Bewertung wählen oder eine Notiz eingeben.'
                      : null,
                  onChanged: (wert) {
                    setState(() {
                      _werte[widget.daten.kriterien[index].id] = wert;
                      if (wert.hatWert) _eingabeFehlt = false;
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _notiz,
                focusNode: _notizFokus,
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

  String _produktartLabel(Produktart art) => switch (art) {
        Produktart.bier => 'Bier',
        Produktart.getraenk => 'Getränk',
        Produktart.speise => 'Speise',
        Produktart.sonstiges => 'Sonstiges Produkt',
      };
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
