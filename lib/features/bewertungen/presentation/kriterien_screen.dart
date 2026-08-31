import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/presentation/formular_fehler.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';

class KriterienScreen extends StatefulWidget {
  const KriterienScreen({
    required this.repository,
    required this.idGenerator,
    super.key,
  });

  final BewertungsRepository repository;
  final IdGenerator idGenerator;

  @override
  State<KriterienScreen> createState() => _KriterienScreenState();
}

class _KriterienScreenState extends State<KriterienScreen> {
  late Future<List<Bewertungskriterium>> _laden = widget.repository.ladeKriterien();

  void _neuLaden() => setState(() => _laden = widget.repository.ladeKriterien());

  Future<void> _bearbeiten([Bewertungskriterium? kriterium]) async {
    final gespeichert = await showDialog<bool>(
      context: context,
      builder: (_) => _KriteriumDialog(
        repository: widget.repository,
        idGenerator: widget.idGenerator,
        kriterium: kriterium,
      ),
    );
    if (gespeichert == true && mounted) _neuLaden();
  }

  Future<void> _verschieben(
    List<Bewertungskriterium> kriterien,
    int index,
    int richtung,
  ) async {
    final ziel = index + richtung;
    if (ziel < 0 || ziel >= kriterien.length) return;
    final jetzt = DateTime.now().toUtc();
    final aktuell = kriterien[index];
    final tausch = kriterien[ziel];
    await widget.repository.speichereKriterium(_kopiere(
      aktuell,
      reihenfolge: tausch.reihenfolge,
      geaendertAm: jetzt,
    ));
    await widget.repository.speichereKriterium(_kopiere(
      tausch,
      reihenfolge: aktuell.reihenfolge,
      geaendertAm: jetzt,
    ));
    if (mounted) _neuLaden();
  }

  Bewertungskriterium _kopiere(
    Bewertungskriterium wert, {
    int? reihenfolge,
    DateTime? geaendertAm,
  }) =>
      Bewertungskriterium(
        id: wert.id,
        name: wert.name,
        beschreibung: wert.beschreibung,
        eingabetyp: wert.eingabetyp,
        reihenfolge: reihenfolge ?? wert.reihenfolge,
        aktiv: wert.aktiv,
        produktart: wert.produktart,
        objektart: wert.wirksameObjektart,
        version: wert.version,
        auswahlwerte: wert.auswahlwerte,
        erstelltAm: wert.erstelltAm,
        geaendertAm: geaendertAm ?? wert.geaendertAm,
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Bewertungskriterien'),
          actions: const [
            AppSupportMenu(contextName: SupportKontexte.kriterienVerwalten),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<Bewertungskriterium>>(
            future: _laden,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: FilledButton.icon(
                    onPressed: _neuLaden,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Erneut versuchen'),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final alle = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  const Text(
                    'Deaktivierte oder geänderte Kriterien bleiben in alten Bewertungen in ihrer damaligen Bedeutung erhalten.',
                  ),
                  for (final art in KriteriumObjektart.values) ...[
                    const SizedBox(height: 20),
                    Semantics(
                      header: true,
                      child: Text(_objektartLabel(art), style: Theme.of(context).textTheme.titleLarge),
                    ),
                    for (final eintrag in alle.where((wert) => wert.wirksameObjektart == art).toList().asMap().entries)
                      ListTile(
                        title: Text(eintrag.value.name),
                        subtitle: Text('${_eingabetypLabel(eintrag.value.eingabetyp)} · Version ${eintrag.value.version}${eintrag.value.aktiv ? '' : ' · deaktiviert'}'),
                        onTap: () => _bearbeiten(eintrag.value),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              tooltip: '${eintrag.value.name} nach oben',
                              onPressed: eintrag.key == 0 ? null : () => _verschieben(alle.where((wert) => wert.wirksameObjektart == art).toList(), eintrag.key, -1),
                              icon: const Icon(Icons.arrow_upward),
                            ),
                            IconButton(
                              tooltip: '${eintrag.value.name} nach unten',
                              onPressed: eintrag.key == alle.where((wert) => wert.wirksameObjektart == art).length - 1 ? null : () => _verschieben(alle.where((wert) => wert.wirksameObjektart == art).toList(), eintrag.key, 1),
                              icon: const Icon(Icons.arrow_downward),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _bearbeiten,
          icon: const Icon(Icons.add),
          label: const Text('Kriterium anlegen'),
        ),
      );
}

class _KriteriumDialog extends StatefulWidget {
  const _KriteriumDialog({required this.repository, required this.idGenerator, this.kriterium});

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Bewertungskriterium? kriterium;

  @override
  State<_KriteriumDialog> createState() => _KriteriumDialogState();
}

class _KriteriumDialogState extends State<_KriteriumDialog> {
  final _fehlerFokus = FocusNode();
  final _nameFokus = FocusNode();
  late final TextEditingController _name;
  late final TextEditingController _beschreibung;
  late final TextEditingController _auswahlwerte;
  late KriteriumEingabetyp _eingabetyp;
  late KriteriumObjektart _objektart;
  late bool _aktiv;
  var _nameFehlt = false;
  var _speichert = false;

  @override
  void initState() {
    super.initState();
    final kriterium = widget.kriterium;
    _name = TextEditingController(text: kriterium?.name ?? '');
    _beschreibung = TextEditingController(text: kriterium?.beschreibung ?? '');
    _auswahlwerte = TextEditingController(text: kriterium?.auswahlwerte.join('\n') ?? '');
    _eingabetyp = kriterium?.eingabetyp ?? KriteriumEingabetyp.wertung;
    _objektart = kriterium?.wirksameObjektart ?? KriteriumObjektart.getraenk;
    _aktiv = kriterium?.aktiv ?? true;
  }

  @override
  void dispose() {
    _fehlerFokus.dispose();
    _nameFokus.dispose();
    _name.dispose();
    _beschreibung.dispose();
    _auswahlwerte.dispose();
    super.dispose();
  }

  Future<void> _speichern() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _nameFehlt = true);
      _fehlerFokus.requestFocus();
      return;
    }
    setState(() => _speichert = true);
    final jetzt = DateTime.now().toUtc();
    final vorhanden = widget.kriterium;
    try {
      await widget.repository.speichereKriterium(Bewertungskriterium(
        id: vorhanden?.id ?? widget.idGenerator.neueId(),
        name: _name.text.trim(),
        beschreibung: _beschreibung.text.trim().isEmpty ? null : _beschreibung.text.trim(),
        eingabetyp: _eingabetyp,
        reihenfolge: vorhanden?.reihenfolge ?? 1000,
        aktiv: _aktiv,
        objektart: _objektart,
        version: vorhanden?.version ?? 1,
        auswahlwerte: _auswahlwerte.text.split('\n').map((wert) => wert.trim()).where((wert) => wert.isNotEmpty).toList(),
        erstelltAm: vorhanden?.erstelltAm ?? jetzt,
        geaendertAm: jetzt,
      ));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _speichert = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Das Kriterium konnte nicht gespeichert werden.')));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.kriterium == null ? 'Kriterium anlegen' : 'Kriterium bearbeiten'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_nameFehlt) FormularFehlersammler(focusNode: _fehlerFokus, fehler: [('Name ist erforderlich.', _nameFokus)]),
                TextField(controller: _name, focusNode: _nameFokus, maxLength: 100, decoration: InputDecoration(labelText: 'Name (Pflichtfeld)', errorText: _nameFehlt ? 'Name ist erforderlich.' : null)),
                TextField(controller: _beschreibung, maxLength: 500, maxLines: 3, decoration: const InputDecoration(labelText: 'Beschreibung (optional)')),
                DropdownButtonFormField<KriteriumObjektart>(
                  initialValue: _objektart,
                  decoration: const InputDecoration(labelText: 'Objektart'),
                  items: [for (final wert in KriteriumObjektart.values) DropdownMenuItem(value: wert, child: Text(_objektartLabel(wert)))],
                  onChanged: (wert) { if (wert != null) setState(() => _objektart = wert); },
                ),
                DropdownButtonFormField<KriteriumEingabetyp>(
                  initialValue: _eingabetyp,
                  decoration: const InputDecoration(labelText: 'Eingabetyp'),
                  items: [for (final wert in KriteriumEingabetyp.values) DropdownMenuItem(value: wert, child: Text(_eingabetypLabel(wert)))],
                  onChanged: (wert) { if (wert != null) setState(() => _eingabetyp = wert); },
                ),
                if (_eingabetyp == KriteriumEingabetyp.auswahl)
                  TextField(controller: _auswahlwerte, maxLength: 1000, maxLines: 5, decoration: const InputDecoration(labelText: 'Auswahlwerte (eine Zeile je Wert)')),
                SwitchListTile(value: _aktiv, onChanged: (wert) => setState(() => _aktiv = wert), title: const Text('Aktiv')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: _speichert ? null : () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
          FilledButton(onPressed: _speichert ? null : _speichern, child: const Text('Speichern')),
        ],
      );
}

String _objektartLabel(KriteriumObjektart art) => switch (art) {
      KriteriumObjektart.getraenk => 'Getränke',
      KriteriumObjektart.speise => 'Speisen',
      KriteriumObjektart.sonstigesProdukt => 'Sonstige Produkte',
      KriteriumObjektart.gastronomie => 'Gastronomie',
      KriteriumObjektart.geschaeft => 'Geschäfte',
    };

String _eingabetypLabel(KriteriumEingabetyp typ) => switch (typ) {
      KriteriumEingabetyp.wertung => 'Wertung',
      KriteriumEingabetyp.intensitaet => 'Intensität',
      KriteriumEingabetyp.jaNein => 'Ja / Nein',
      KriteriumEingabetyp.zahl => 'Zahl',
      KriteriumEingabetyp.auswahl => 'Auswahl',
      KriteriumEingabetyp.freitext => 'Freitext',
    };
