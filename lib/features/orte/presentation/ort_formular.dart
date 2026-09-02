import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/presentation/formular_fehler.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/orte/presentation/ort_karte_screen.dart';
import 'package:taugts/features/orte/services/geocoding_service.dart';
import 'package:taugts/features/orte/services/standort_service.dart';

typedef OrtKarteOeffnen = Future<LatLng?> Function(
  BuildContext context,
  LatLng? ausgangsposition,
);

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
    this.standortService = const GeolocatorStandortService(),
    this.geocodingService = const NominatimGeocodingService(),
    this.karteOeffnen,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Ort? ort;
  final StandortService standortService;
  final GeocodingService geocodingService;
  final OrtKarteOeffnen? karteOeffnen;

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
  var _ermitteltStandort = false;
  var _ermitteltAdresse = false;
  String? _standortMeldung;

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

  String? _namePruefen(String? wert) =>
      wert == null || wert.trim().isEmpty ? 'Der Name ist erforderlich.' : null;

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
    if (eingabe.isEmpty && gegenstueck.trim().isEmpty) return null;
    if (eingabe.isEmpty) return 'Beide Koordinaten sind erforderlich.';
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
        const SnackBar(
          content: Text('Bitte Eingaben prüfen.'),
        ),
      );
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final fehlerContext = _fehlerKey.currentContext;
      if (fehlerContext != null && fehlerContext.mounted) {
        await Scrollable.ensureVisible(fehlerContext);
      }
      if (!mounted) return;
      _fehlerFokus.requestFocus();
      return;
    }

    final dubletten = await widget.repository.findeAehnlicheOrte(
      name: _name.text,
      adresse: _wert(_adresse),
      ausgenommenId: widget.ort?.id,
    );
    if (!mounted) return;
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
      if (fortfahren != true || !mounted) return;
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
      if (mounted) Navigator.of(context).pop(ort);
    } catch (_) {
      if (!mounted) return;
      setState(() => _speichert = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Der Ort konnte nicht gespeichert werden.'),
        ),
      );
    }
  }

  List<_Ortsfehler> _validierungsfehler() {
    final fehler = <_Ortsfehler>[];
    final nameFehler = _namePruefen(_name.text);
    if (nameFehler != null) fehler.add(_Ortsfehler(nameFehler, _nameFokus));
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

  Future<void> _standortUebernehmen() async {
    setState(() {
      _ermitteltStandort = true;
      _standortMeldung = null;
    });
    try {
      final standort =
          await widget.standortService.aktuellenStandortErmitteln();
      if (!mounted) return;
      final genauigkeit = standort.genauigkeitMeter == null
          ? 'nicht verfügbar'
          : '${standort.genauigkeitMeter!.round()} m';
      final bestaetigt = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Standort übernehmen?'),
          content: Text(
            'Breitengrad: ${standort.breitengrad.toStringAsFixed(6)}\n'
            'Längengrad: ${standort.laengengrad.toStringAsFixed(6)}\n'
            'Genauigkeit: $genauigkeit\n\n'
            'Die Koordinaten können danach korrigiert oder entfernt werden.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Nicht übernehmen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Koordinaten übernehmen'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (bestaetigt == true) {
        setState(() {
          _breitengrad.text = standort.breitengrad.toStringAsFixed(6);
          _laengengrad.text = standort.laengengrad.toStringAsFixed(6);
          _standortMeldung =
              'Standort übernommen. Koordinaten sind bearbeitbar.';
        });
      }
    } catch (fehler) {
      if (!mounted) return;
      setState(
        () => _standortMeldung = fehler is StandortAusnahme
            ? fehler.nachricht
            : 'Der aktuelle Standort konnte nicht ermittelt werden.',
      );
    } finally {
      if (mounted) setState(() => _ermitteltStandort = false);
    }
  }

  Future<void> _adresseVorschlagen() async {
    final breite = _kommazahl(_breitengrad.text);
    final laenge = _kommazahl(_laengengrad.text);
    if (breite == null ||
        laenge == null ||
        breite < -90 ||
        breite > 90 ||
        laenge < -180 ||
        laenge > 180) {
      setState(() => _standortMeldung =
          'Für einen Adressvorschlag sind gültige Koordinaten erforderlich.');
      return;
    }
    if (_typ == Ortstyp.privat) {
      setState(() => _standortMeldung =
          'Für private Orte werden exakte Koordinaten nicht an den Adressdienst übertragen.');
      return;
    }
    setState(() {
      _ermitteltAdresse = true;
      _standortMeldung = null;
    });
    try {
      final vorschlag = await widget.geocodingService.adresseVorschlagen(
        breitengrad: breite,
        laengengrad: laenge,
      );
      if (!mounted) return;
      if (vorschlag == null) {
        setState(() => _standortMeldung =
            'Zu diesen Koordinaten wurde kein Adressvorschlag gefunden.');
        return;
      }
      final nameVorschlag = vorschlag.name;
      final bestaetigt = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Adressvorschlag übernehmen?'),
          content: Text(
            '${nameVorschlag == null ? '' : 'Name: $nameVorschlag\n'}'
            'Adresse: ${vorschlag.adresse}\n\n'
            'Der Vorschlag stammt aus OpenStreetMap/Nominatim. '
            'Bitte vor dem Speichern prüfen und bei Bedarf korrigieren.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Nicht übernehmen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Vorschlag übernehmen'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (bestaetigt == true) {
        setState(() {
          _adresse.text = vorschlag.adresse;
          if (_name.text.trim().isEmpty && nameVorschlag != null) {
            _name.text = nameVorschlag;
          }
          _standortMeldung =
              'Adressvorschlag übernommen. Bitte Angaben vor dem Speichern prüfen.';
        });
      }
    } catch (fehler) {
      if (!mounted) return;
      setState(() => _standortMeldung = fehler is GeocodingAusnahme
          ? fehler.nachricht
          : 'Der Adressvorschlag konnte nicht ermittelt werden. Der Ort kann trotzdem gespeichert werden.');
    } finally {
      if (mounted) setState(() => _ermitteltAdresse = false);
    }
  }

  Future<void> _karteOeffnen() async {
    final breite = _kommazahl(_breitengrad.text);
    final laenge = _kommazahl(_laengengrad.text);
    final ausgangsposition =
        breite == null || laenge == null ? null : LatLng(breite, laenge);
    final position = await (widget.karteOeffnen?.call(
          context,
          ausgangsposition,
        ) ??
        Navigator.of(context).push<LatLng>(
          MaterialPageRoute(
            builder: (_) => OrtKarteScreen(ausgangsposition: ausgangsposition),
          ),
        ));
    if (position == null || !mounted) return;
    setState(() {
      _breitengrad.text = position.latitude.toStringAsFixed(6);
      _laengengrad.text = position.longitude.toStringAsFixed(6);
      _standortMeldung = 'Kartenposition übernommen und weiter bearbeitbar.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.ort == null ? 'Ort anlegen' : 'Ort bearbeiten'),
          actions: [
            AppSupportMenu(
              contextName: SupportKontexte.ortFormular(
                bearbeiten: widget.ort != null,
              ),
            ),
          ],
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
                        child: Text('Gastronomie')),
                    DropdownMenuItem(
                        value: Ortstyp.geschaeft, child: Text('Geschäft')),
                    DropdownMenuItem(
                        value: Ortstyp.privat, child: Text('Privater Ort')),
                    DropdownMenuItem(
                        value: Ortstyp.sonstiger, child: Text('Sonstiger Ort')),
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
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _ermitteltStandort ? null : _standortUebernehmen,
                  icon: const Icon(Icons.my_location),
                  label: Text(_ermitteltStandort
                      ? 'Standort wird ermittelt …'
                      : 'Aktuellen Standort verwenden'),
                ),
                if (_standortMeldung != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(_standortMeldung!),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _karteOeffnen,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Position auf OpenStreetMap auswählen'),
                ),
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
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _ermitteltAdresse ? null : _adresseVorschlagen,
                  icon: const Icon(Icons.location_on_outlined),
                  label: Text(_ermitteltAdresse
                      ? 'Adressvorschlag wird ermittelt …'
                      : 'Adresse aus Koordinaten vorschlagen'),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Online-Anreicherung über OpenStreetMap/Nominatim. Nur nach Betätigung werden die eingegebenen Koordinaten übertragen.',
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
  }) =>
      Padding(
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
