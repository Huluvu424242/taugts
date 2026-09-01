import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/presentation/formular_fehler.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/presentation/gaststaettenbewertung_abschnitt.dart';
import 'package:taugts/features/bewertungen/presentation/getraenkebewertung_screen.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/erlebnisse/presentation/erlebnisposition_formular.dart';
import 'package:taugts/features/orte/presentation/orte_screen.dart';
import 'package:taugts/features/profil/models/profil.dart';

class ErlebnisScreen extends StatefulWidget {
  const ErlebnisScreen({
    required this.repository,
    required this.idGenerator,
    required this.profil,
    this.erlebnistyp,
    this.erlebnis,
    super.key,
  }) : assert(erlebnis != null || erlebnistyp != null);

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Profil profil;
  final Erlebnistyp? erlebnistyp;
  final Erlebnis? erlebnis;

  @override
  State<ErlebnisScreen> createState() => _ErlebnisScreenState();
}

class _ErlebnisScreenState extends State<ErlebnisScreen> {
  final _fehlerKey = GlobalKey();
  final _fehlerFokus = FocusNode();
  final _dauerFokus = FocusNode();
  final _beginnFokus = FocusNode();
  final _endeFokus = FocusNode();
  final _dauer = TextEditingController();
  final _notiz = TextEditingController();
  final _positionenInBearbeitung = <String>{};
  late final String _id;
  late final DateTime _erstelltAm;
  late final Erlebnistyp _typ;
  Erlebnis? _gespeichertesErlebnis;
  Ort? _ort;
  DateTime? _geplanterTag;
  int? _geplanteMinute;
  DateTime? _tatsaechlicherBeginn;
  DateTime? _tatsaechlichesEnde;
  var _speichert = false;
  var _zeitfehler = <String>[];
  late Future<List<ErlebnispositionMitProdukt>> _positionen;

  @override
  void initState() {
    super.initState();
    final erlebnis = widget.erlebnis;
    _gespeichertesErlebnis = erlebnis;
    _id = erlebnis?.id ?? widget.idGenerator.neueId();
    _erstelltAm = erlebnis?.erstelltAm ?? DateTime.now().toUtc();
    _typ = erlebnis?.typ ?? widget.erlebnistyp!;
    _geplanterTag = erlebnis?.geplanterTag?.toLocal();
    _geplanteMinute = erlebnis?.geplanteMinute;
    _tatsaechlicherBeginn = erlebnis?.tatsaechlicherBeginn?.toLocal();
    _tatsaechlichesEnde = erlebnis?.tatsaechlichesEnde?.toLocal();
    _dauer.text = erlebnis?.geplanteDauerMinuten?.toString() ?? '';
    _notiz.text = erlebnis?.notiz ?? '';
    _positionen = widget.repository.ladeErlebnispositionen(_id);
    _ladeOrt();
  }

  Future<void> _ladeOrt() async {
    final ortId = widget.erlebnis?.wirksamerOrtId;
    if (ortId == null) return;
    final ort = await widget.repository.ladeOrt(ortId);
    if (!mounted) return;
    setState(() => _ort = ort);
  }

  @override
  void dispose() {
    _dauer.dispose();
    _notiz.dispose();
    _fehlerFokus.dispose();
    _dauerFokus.dispose();
    _beginnFokus.dispose();
    _endeFokus.dispose();
    super.dispose();
  }

  bool get _istRestaurant => _typ == Erlebnistyp.restaurantbesuch;
  bool get _istEinkauf => _typ == Erlebnistyp.einkauf;

  String get _typLabel => switch (_typ) {
        Erlebnistyp.restaurantbesuch => 'Restaurantbesuch',
        Erlebnistyp.einkauf => 'Einkauf',
      };

  String _statusLabel(Erlebnisstatus status) => switch (status) {
        Erlebnisstatus.geplant => 'Geplant',
        Erlebnisstatus.aktiv => 'Aktiv',
        Erlebnisstatus.beendet => 'Beendet',
      };

  Erlebnisstatus get _aktuellerStatus =>
      _gespeichertesErlebnis?.status ?? Erlebnisstatus.geplant;

  Future<void> _ortWaehlen() async {
    final ort = await Navigator.of(context).push<Ort>(
      MaterialPageRoute(
        builder: (_) => OrteScreen(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
          zurAuswahl: true,
        ),
      ),
    );
    if (ort != null && mounted) setState(() => _ort = ort);
  }

  Future<void> _geplantenTagWaehlen() async {
    final heute = DateTime.now();
    final datum = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _geplanterTag ?? heute,
      helpText: 'Geplantes Datum wählen',
    );
    if (datum != null && mounted) setState(() => _geplanterTag = datum);
  }

  Future<void> _geplanteZeitWaehlen() async {
    final minute = _geplanteMinute;
    final zeit = await showTimePicker(
      context: context,
      initialTime: minute == null
          ? TimeOfDay.now()
          : TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
      helpText: 'Geplante Uhrzeit wählen',
    );
    if (zeit != null && mounted) {
      setState(() => _geplanteMinute = zeit.hour * 60 + zeit.minute);
    }
  }

  Future<void> _tatsaechlicheZeitWaehlen({required bool beginn}) async {
    final aktuell = beginn ? _tatsaechlicherBeginn : _tatsaechlichesEnde;
    final jetzt = DateTime.now();
    final datum = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: aktuell ?? jetzt,
      helpText:
          beginn ? 'Tatsächlichen Beginn wählen' : 'Tatsächliches Ende wählen',
    );
    if (datum == null || !mounted) return;
    final zeit = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(aktuell ?? jetzt),
    );
    if (zeit == null || !mounted) return;
    final wert = DateTime(
      datum.year,
      datum.month,
      datum.day,
      zeit.hour,
      zeit.minute,
    );
    setState(() {
      if (beginn) {
        _tatsaechlicherBeginn = wert;
      } else {
        _tatsaechlichesEnde = wert;
      }
    });
  }

  Erlebnis _erlebnisAusEingaben({Erlebnisstatus? status}) {
    final dauer = int.tryParse(_dauer.text.trim());
    final abgeleiteterStatus = status ??
        (_tatsaechlichesEnde != null
            ? Erlebnisstatus.beendet
            : _tatsaechlicherBeginn != null
                ? Erlebnisstatus.aktiv
                : Erlebnisstatus.geplant);
    return Erlebnis(
      id: _id,
      typ: _typ,
      status: abgeleiteterStatus,
      ortId: _ort?.id,
      geplanterTag: _geplanterTag == null
          ? null
          : DateTime.utc(
              _geplanterTag!.year,
              _geplanterTag!.month,
              _geplanterTag!.day,
            ),
      geplanteMinute: _geplanteMinute,
      geplanteDauerMinuten: dauer,
      tatsaechlicherBeginn: _tatsaechlicherBeginn?.toUtc(),
      tatsaechlichesEnde: _tatsaechlichesEnde?.toUtc(),
      herkunftProfilId: widget.profil.id,
      notiz: _notiz.text.trim().isEmpty ? null : _notiz.text.trim(),
      istEntwurf: false,
      erstelltAm: _erstelltAm,
      geaendertAm: DateTime.now().toUtc(),
    );
  }

  Future<bool> _validiere(Erlebnis erlebnis) async {
    final fehler = [...erlebnis.zeitfehler];
    if (_dauer.text.trim().isNotEmpty &&
        int.tryParse(_dauer.text.trim()) == null) {
      fehler.add('Die geplante Dauer muss eine ganze Minutenzahl sein.');
    }
    if (fehler.isEmpty) {
      setState(() => _zeitfehler = []);
      return true;
    }
    setState(() => _zeitfehler = fehler);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bitte Zeitangaben prüfen.')),
    );
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;
    final fehlerContext = _fehlerKey.currentContext;
    if (fehlerContext != null && fehlerContext.mounted) {
      await Scrollable.ensureVisible(fehlerContext);
    }
    if (!mounted) return false;
    _fehlerFokus.requestFocus();
    return false;
  }

  FocusNode _fokusFuerFehler(String fehler) {
    if (fehler.contains('Dauer') || fehler.contains('Minutenzahl')) {
      return _dauerFokus;
    }
    if (fehler.contains('Ende')) return _endeFokus;
    return _beginnFokus;
  }

  Future<void> _persistieren({
    Erlebnisstatus? status,
    required bool schliessen,
  }) async {
    final erlebnis = _erlebnisAusEingaben(status: status);
    if (!await _validiere(erlebnis) || !mounted) return;
    setState(() => _speichert = true);
    try {
      await widget.repository.speichereErlebnis(erlebnis);
      if (!mounted) return;
      if (schliessen) {
        Navigator.of(context).pop(erlebnis);
        return;
      }
      setState(() {
        _gespeichertesErlebnis = erlebnis;
        _speichert = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${_statusLabel(erlebnis.status)} gespeichert.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _speichert = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Das Erlebnis konnte nicht gespeichert werden.'),
        ),
      );
    }
  }

  Future<void> _checkIn() async {
    setState(() {
      _tatsaechlicherBeginn ??= DateTime.now();
      _tatsaechlichesEnde = null;
    });
    await _persistieren(status: Erlebnisstatus.aktiv, schliessen: false);
  }

  Future<void> _checkout() async {
    setState(() => _tatsaechlichesEnde ??= DateTime.now());
    await _persistieren(status: Erlebnisstatus.beendet, schliessen: false);
  }

  void _positionenLaden() {
    setState(() {
      _positionen = widget.repository.ladeErlebnispositionen(_id);
    });
  }

  Future<void> _positionOeffnen([
    ErlebnispositionMitProdukt? vorhanden,
  ]) async {
    final erlebnis = _erlebnisAusEingaben();
    if (!await _validiere(erlebnis) || !mounted) return;
    try {
      await widget.repository.speichereErlebnis(erlebnis);
      if (!mounted) return;
      _gespeichertesErlebnis = erlebnis;
      final gespeichert = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ErlebnispositionFormular(
            repository: widget.repository,
            idGenerator: widget.idGenerator,
            erlebnis: erlebnis,
            vorhanden: vorhanden,
          ),
        ),
      );
      if (gespeichert == true && mounted) _positionenLaden();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Das Erlebnis konnte nicht vorbereitet werden.'),
        ),
      );
    }
  }

  Future<void> _positionLoeschen(ErlebnispositionMitProdukt eintrag) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Position entfernen?'),
        content: Text(
          '${eintrag.produkt.anzeigetitel} wird aus dem Erlebnis entfernt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
    if (bestaetigt != true) return;
    try {
      await widget.repository.loescheErlebnisposition(eintrag.position.id);
      if (!mounted) return;
      _positionenLaden();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Die Position konnte nicht entfernt werden.')),
      );
    }
  }

  Future<void> _anzahlAendern(
    ErlebnispositionMitProdukt eintrag,
    int delta,
  ) async {
    final id = eintrag.position.id;
    if (_positionenInBearbeitung.contains(id)) return;
    final neu = eintrag.position.anzahl + delta;
    if (neu < 1) return;
    setState(() => _positionenInBearbeitung.add(id));
    try {
      await widget.repository.speichereErlebnisposition(
        position: eintrag.position.mitAnzahl(neu, DateTime.now().toUtc()),
        preis: eintrag.preis,
      );
      if (!mounted) return;
      _positionenLaden();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Die Anzahl für ${eintrag.produkt.anzeigetitel} konnte nicht gespeichert werden.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _positionenInBearbeitung.remove(id));
      }
    }
  }

  Future<void> _positionBewerten(ErlebnispositionMitProdukt eintrag) async {
    final erlebnis = _gespeichertesErlebnis ?? _erlebnisAusEingaben();
    await Navigator.of(context).push<Erlebnis>(
      MaterialPageRoute(
        builder: (_) => GetraenkebewertungScreen(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
          profil: widget.profil,
          erlebnis: erlebnis,
          erlebnisposition: eintrag,
        ),
      ),
    );
    if (mounted) _positionenLaden();
  }

  String _datumText(BuildContext context, DateTime? wert) => wert == null
      ? 'Nicht festgelegt'
      : MaterialLocalizations.of(context).formatFullDate(wert);

  String _zeitText(BuildContext context, int? minute) => minute == null
      ? 'Uhrzeit offen'
      : MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
        );

  String _datumZeitText(BuildContext context, DateTime? wert) {
    if (wert == null) return 'Nicht festgelegt';
    final lokal = wert.toLocal();
    final lokalisierung = MaterialLocalizations.of(context);
    final uhrzeit = lokalisierung.formatTimeOfDay(
      TimeOfDay.fromDateTime(lokal),
    );
    return '${lokalisierung.formatFullDate(lokal)}, $uhrzeit';
  }

  String _laufenderStatusText(BuildContext context) {
    if (_aktuellerStatus != Erlebnisstatus.aktiv) return '';
    final beginn = _tatsaechlicherBeginn;
    if (beginn == null) return '';
    final zeit = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(beginn),
    );
    return _istEinkauf ? 'Einkauf läuft seit $zeit' : 'Aktiv seit $zeit';
  }

  Widget _produktposition(ErlebnispositionMitProdukt eintrag) {
    final name = eintrag.produkt.anzeigetitel;
    final preis = eintrag.preis;
    final busy = _positionenInBearbeitung.contains(eintrag.position.id);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              preis == null
                  ? 'Preis nicht erfasst'
                  : '${preis.betrag.dezimalText} ${preis.betrag.waehrung} je Einheit',
            ),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                IconButton(
                  tooltip:
                      '$name Anzahl verringern, aktuell ${eintrag.position.anzahl}',
                  onPressed: busy || eintrag.position.anzahl <= 1
                      ? null
                      : () => _anzahlAendern(eintrag, -1),
                  icon: const Icon(Icons.remove),
                ),
                Semantics(
                  label: '$name, Anzahl ${eintrag.position.anzahl}',
                  child: SizedBox(
                    width: 48,
                    child: Text(
                      '${eintrag.position.anzahl}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  tooltip:
                      '$name Anzahl erhöhen, aktuell ${eintrag.position.anzahl}',
                  onPressed: busy ? null : () => _anzahlAendern(eintrag, 1),
                  icon: const Icon(Icons.add),
                ),
                FutureBuilder<List<Bewertung>>(
                  future: widget.repository.ladeBewertungenFuerErlebnisposition(
                    eintrag.position.id,
                  ),
                  builder: (context, snapshot) {
                    final bewertet =
                        snapshot.hasData && snapshot.data!.isNotEmpty;
                    final status =
                        bewertet ? 'Bewertet' : 'Noch nicht bewertet';
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(status),
                        const SizedBox(width: 4),
                        _ProduktBewertungsButton(
                          produktname: name,
                          bewertet: bewertet,
                          onPressed: () => _positionBewerten(eintrag),
                        ),
                      ],
                    );
                  },
                ),
                IconButton(
                  tooltip: '$name bearbeiten',
                  onPressed: busy ? null : () => _positionOeffnen(eintrag),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: '$name entfernen',
                  onPressed: busy ? null : () => _positionLoeschen(eintrag),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _positionsZusammenfassung(
    List<ErlebnispositionMitProdukt> eintraege,
  ) =>
      eintraege
          .map((e) => '${e.position.anzahl} × ${e.produkt.anzeigetitel}')
          .join(' · ');

  Widget _einkaufssumme(List<ErlebnispositionMitProdukt> eintraege) {
    final mitPreis = eintraege.where((e) => e.preis != null).toList();
    final ohnePreis = eintraege.length - mitPreis.length;
    final waehrungen = mitPreis.map((e) => e.preis!.betrag.waehrung).toSet();
    if (mitPreis.isEmpty) {
      return const Text(
          'Summe nicht verfügbar · für alle Positionen fehlt ein Preis.');
    }
    if (waehrungen.length != 1) {
      return Text(
        'Summe nicht verfügbar · mehrere Währungen erfasst'
        '${ohnePreis == 0 ? '.' : ' · $ohnePreis Position(en) ohne Preis.'}',
      );
    }
    final summeMinor = mitPreis.fold<int>(
      0,
      (summe, eintrag) =>
          summe +
          eintrag.preis!.betrag.minorEinheiten * eintrag.position.anzahl,
    );
    final betrag = Geldbetrag(
      minorEinheiten: summeMinor,
      waehrung: waehrungen.single,
    );
    final fehlend = ohnePreis == 0
        ? 'Alle Positionen mit Preis.'
        : '$ohnePreis Position(en) ohne Preis; nicht als 0 eingerechnet.';
    return Semantics(
      label:
          'Summe aus erfassten Preisen ${betrag.dezimalText} ${betrag.waehrung}. $fehlend',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summe aus erfassten Preisen',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            '${betrag.dezimalText} ${betrag.waehrung}',
            key: const ValueKey('einkaufssumme'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(fehlend),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(_typLabel),
          actions: [
            AppSupportMenu(
              contextName: SupportKontexte.erlebnisGrunddaten(
                typ: _typLabel,
                bearbeiten: widget.erlebnis != null,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            children: [
              if (_zeitfehler.isNotEmpty)
                FormularFehlersammler(
                  key: _fehlerKey,
                  focusNode: _fehlerFokus,
                  fehler: [
                    for (final fehler in _zeitfehler)
                      (fehler, _fokusFuerFehler(fehler)),
                  ],
                ),
              Semantics(
                header: true,
                child: Text(
                  'Status: ${_statusLabel(_aktuellerStatus)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (_laufenderStatusText(context).isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(_laufenderStatusText(context)),
              ],
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _ortWaehlen,
                icon: Icon(
                  _istRestaurant
                      ? Icons.restaurant_outlined
                      : Icons.shopping_bag_outlined,
                ),
                label: Text(
                  _ort?.name ??
                      (_istEinkauf
                          ? 'Geschäft auswählen (optional)'
                          : 'Ort auswählen (optional)'),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  'Planung',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Geplanter Tag (optional)'),
                subtitle: Text(_datumText(context, _geplanterTag)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _geplantenTagWaehlen,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed:
                          _geplanterTag == null ? null : _geplanteZeitWaehlen,
                      icon: const Icon(Icons.schedule),
                      label: Text(_zeitText(context, _geplanteMinute)),
                    ),
                  ),
                  if (_geplanterTag != null)
                    IconButton(
                      tooltip: 'Planung entfernen',
                      onPressed: () => setState(() {
                        _geplanterTag = null;
                        _geplanteMinute = null;
                      }),
                      icon: const Icon(Icons.clear),
                    ),
                ],
              ),
              TextField(
                controller: _dauer,
                focusNode: _dauerFokus,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Geplante Dauer in Minuten (optional)',
                  errorText: _zeitfehler.any(
                    (fehler) =>
                        fehler.contains('Dauer') ||
                        fehler.contains('Minutenzahl'),
                  )
                      ? 'Bitte eine positive ganze Zahl eingeben.'
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  'Tatsächliche Zeiten',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ListTile(
                key: const ValueKey('tatsaechlicher-beginn'),
                contentPadding: EdgeInsets.zero,
                focusNode: _beginnFokus,
                title: const Text('Tatsächlicher Beginn (optional)'),
                subtitle: Text(_datumZeitText(context, _tatsaechlicherBeginn)),
                trailing: const Icon(Icons.login),
                onTap: () => _tatsaechlicheZeitWaehlen(beginn: true),
              ),
              ListTile(
                key: const ValueKey('tatsaechliches-ende'),
                contentPadding: EdgeInsets.zero,
                focusNode: _endeFokus,
                title: const Text('Tatsächliches Ende (optional)'),
                subtitle: Text(_datumZeitText(context, _tatsaechlichesEnde)),
                trailing: const Icon(Icons.logout),
                onTap: () => _tatsaechlicheZeitWaehlen(beginn: false),
              ),
              TextField(
                controller: _notiz,
                maxLength: 1000,
                maxLines: 4,
                decoration:
                    const InputDecoration(labelText: 'Notiz (optional)'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        _istEinkauf ? 'Einkaufsliste' : 'Bestellung',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _speichert ? null : _positionOeffnen,
                    icon: const Icon(Icons.add),
                    label: const Text('Produkt hinzufügen'),
                  ),
                ],
              ),
              FutureBuilder<List<ErlebnispositionMitProdukt>>(
                future: _positionen,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Semantics(
                      liveRegion: true,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _istEinkauf
                                  ? 'Die Einkaufsliste konnte nicht geladen werden.'
                                  : 'Die Bestellung konnte nicht geladen werden.',
                            ),
                          ),
                          TextButton(
                            onPressed: _positionenLaden,
                            child: const Text('Erneut versuchen'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Semantics(
                      label: _istEinkauf
                          ? 'Einkaufsliste wird geladen'
                          : 'Bestellung wird geladen',
                      child: const LinearProgressIndicator(),
                    );
                  }
                  final eintraege = snapshot.data!;
                  if (eintraege.isEmpty) {
                    return Text(
                      _istEinkauf
                          ? 'Die Einkaufsliste ist leer. Produkte können auch ohne Termin vorab hinzugefügt werden.'
                          : 'Noch keine Produkte bestellt. Produkt hinzufügen, um die Bestellung zu beginnen.',
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final eintrag in eintraege)
                        _produktposition(eintrag),
                      const SizedBox(height: 8),
                      Text(
                        _positionsZusammenfassung(eintraege),
                        key: ValueKey(
                          _istEinkauf
                              ? 'einkaufslisten-zusammenfassung'
                              : 'bestellungs-zusammenfassung',
                        ),
                      ),
                      if (_istEinkauf) ...[
                        const SizedBox(height: 16),
                        _einkaufssumme(eintraege),
                      ],
                    ],
                  );
                },
              ),
              if (_istRestaurant || _istEinkauf) ...[
                const SizedBox(height: 24),
                GaststaettenbewertungAbschnitt(
                  key: ValueKey('ortsbewertung-$_id-${_ort?.id}'),
                  repository: widget.repository,
                  idGenerator: widget.idGenerator,
                  erlebnis: _erlebnisAusEingaben(),
                  ort: _ort,
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.all(16),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed:
                    _speichert ? null : () => _persistieren(schliessen: true),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Speichern'),
              ),
              if (_aktuellerStatus == Erlebnisstatus.geplant)
                FilledButton.icon(
                  onPressed: _speichert ? null : _checkIn,
                  icon: const Icon(Icons.login),
                  label: Text(_istEinkauf ? 'Einkauf beginnen' : 'Check-in'),
                )
              else if (_aktuellerStatus == Erlebnisstatus.aktiv)
                FilledButton.icon(
                  onPressed: _speichert ? null : _checkout,
                  icon: const Icon(Icons.logout),
                  label: Text(_istEinkauf ? 'Einkauf beenden' : 'Checkout'),
                )
              else
                FilledButton.icon(
                  onPressed:
                      _speichert ? null : () => _persistieren(schliessen: true),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Bearbeiten speichern'),
                ),
            ],
          ),
        ),
      );
}

class _ProduktBewertungsButton extends StatelessWidget {
  const _ProduktBewertungsButton({
    required this.produktname,
    required this.bewertet,
    required this.onPressed,
  });

  final String produktname;
  final bool bewertet;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final beschriftung = '$produktname bewerten';
    return Semantics(
      button: true,
      label: beschriftung,
      value: bewertet ? 'Bewertet' : 'Noch nicht bewertet',
      child: Tooltip(
        message: beschriftung,
        child: InkResponse(
          onTap: onPressed,
          radius: 28,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: const [
                Positioned(
                  left: 7,
                  bottom: 7,
                  child: Icon(Icons.thumb_down_alt_outlined, size: 22),
                ),
                Positioned(
                  right: 7,
                  top: 7,
                  child: Icon(Icons.thumb_up_alt_outlined, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
