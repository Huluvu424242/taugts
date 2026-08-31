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
  late Future<List<Bewertungskriterium>> _laden =
      widget.repository.ladeKriterien();
  String? _meldung;

  void _neuLaden() => setState(() {
        _laden = widget.repository.ladeKriterien();
      });

  Future<void> _bearbeiten([Bewertungskriterium? kriterium]) async {
    final gespeichert = await showDialog<bool>(
      context: context,
      builder: (_) => _KriteriumDialog(
        repository: widget.repository,
        idGenerator: widget.idGenerator,
        kriterium: kriterium,
      ),
    );
    if (gespeichert == true && mounted) {
      setState(() {
        _meldung = kriterium == null
            ? 'Kriterium wurde angelegt.'
            : 'Kriterium wurde aktualisiert.';
        _laden = widget.repository.ladeKriterien();
      });
    }
  }

  Future<void> _verschieben(
    List<Bewertungskriterium> kriterien,
    int index,
    int richtung,
  ) async {
    final ziel = index + richtung;
    if (ziel < 0 || ziel >= kriterien.length) {
      return;
    }
    final sortiert = [...kriterien];
    final aktuell = sortiert.removeAt(index);
    sortiert.insert(ziel, aktuell);
    try {
      await widget.repository.sortiereKriterien(
        sortiert.map((wert) => wert.id).toList(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _meldung = 'Sortierreihenfolge wurde gespeichert.';
        _laden = widget.repository.ladeKriterien();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Die Sortierreihenfolge konnte nicht gespeichert werden.'),
        ),
      );
    }
  }

  Future<void> _entfernen(Bewertungskriterium kriterium) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kriterium entfernen?'),
        content: Text(
          '„${kriterium.name}“ wird gelöscht, wenn es noch nicht verwendet '
          'wurde. Verwendete Kriterien werden nur deaktiviert, damit alte '
          'Bewertungen lesbar bleiben.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
    if (bestaetigt != true || !mounted) {
      return;
    }
    try {
      final deaktiviert =
          await widget.repository.entferneKriterium(kriterium.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _meldung = deaktiviert
            ? 'Das verwendete Kriterium wurde deaktiviert.'
            : 'Das unbenutzte Kriterium wurde gelöscht.';
        _laden = widget.repository.ladeKriterien();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Das Kriterium konnte nicht entfernt werden.'),
        ),
      );
    }
  }

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
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: const Text(
                            'Die Bewertungskriterien konnten nicht geladen werden.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _neuLaden,
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
                    label: 'Bewertungskriterien werden geladen',
                    child: const CircularProgressIndicator(),
                  ),
                );
              }
              final alle = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  const Text(
                    'Deaktivierte oder geänderte Kriterien bleiben in alten Bewertungen in ihrer damaligen Bedeutung erhalten.',
                  ),
                  if (_meldung != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(_meldung!),
                    ),
                  ],
                  for (final art in KriteriumObjektart.values) ...[
                    const SizedBox(height: 20),
                    Semantics(
                      header: true,
                      child: Text(_objektartLabel(art),
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    if (!alle.any((wert) => wert.wirksameObjektart == art))
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Keine Kriterien für diese Objektart.'),
                      ),
                    for (final eintrag in alle
                        .where((wert) => wert.wirksameObjektart == art)
                        .toList()
                        .asMap()
                        .entries)
                      ListTile(
                        title: Text(eintrag.value.name),
                        subtitle: Text(
                            '${_eingabetypLabel(eintrag.value.eingabetyp)} · Version ${eintrag.value.version}${eintrag.value.aktiv ? '' : ' · deaktiviert'}'),
                        onTap: () => _bearbeiten(eintrag.value),
                        trailing: PopupMenuButton<_KriterienAktion>(
                          tooltip: '${eintrag.value.name} – Aktionen',
                          onSelected: (aktion) {
                            final gruppe = alle
                                .where(
                                  (wert) => wert.wirksameObjektart == art,
                                )
                                .toList();
                            switch (aktion) {
                              case _KriterienAktion.nachOben:
                                _verschieben(gruppe, eintrag.key, -1);
                                break;
                              case _KriterienAktion.nachUnten:
                                _verschieben(gruppe, eintrag.key, 1);
                                break;
                              case _KriterienAktion.entfernen:
                                _entfernen(eintrag.value);
                                break;
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: _KriterienAktion.nachOben,
                              enabled: eintrag.key > 0,
                              child: const Text('Nach oben'),
                            ),
                            PopupMenuItem(
                              value: _KriterienAktion.nachUnten,
                              enabled: eintrag.key <
                                  alle
                                          .where(
                                            (wert) =>
                                                wert.wirksameObjektart == art,
                                          )
                                          .length -
                                      1,
                              child: const Text('Nach unten'),
                            ),
                            const PopupMenuItem(
                              value: _KriterienAktion.entfernen,
                              child: Text('Entfernen'),
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

enum _KriterienAktion { nachOben, nachUnten, entfernen }

class _KriteriumDialog extends StatefulWidget {
  const _KriteriumDialog(
      {required this.repository, required this.idGenerator, this.kriterium});

  final BewertungsRepository repository;
  final IdGenerator idGenerator;
  final Bewertungskriterium? kriterium;

  @override
  State<_KriteriumDialog> createState() => _KriteriumDialogState();
}

class _KriteriumDialogState extends State<_KriteriumDialog> {
  final _fehlerFokus = FocusNode();
  final _nameFokus = FocusNode();
  final _auswahlwerteFokus = FocusNode();
  late final TextEditingController _name;
  late final TextEditingController _beschreibung;
  late final TextEditingController _auswahlwerte;
  late KriteriumEingabetyp _eingabetyp;
  late KriteriumObjektart _objektart;
  late bool _aktiv;
  var _nameFehlt = false;
  var _auswahlwerteFehlen = false;
  var _speichert = false;

  @override
  void initState() {
    super.initState();
    final kriterium = widget.kriterium;
    _name = TextEditingController(text: kriterium?.name ?? '');
    _beschreibung = TextEditingController(text: kriterium?.beschreibung ?? '');
    _auswahlwerte =
        TextEditingController(text: kriterium?.auswahlwerte.join('\n') ?? '');
    _eingabetyp = kriterium?.eingabetyp ?? KriteriumEingabetyp.wertung;
    _objektart = kriterium?.wirksameObjektart ?? KriteriumObjektart.getraenk;
    _aktiv = kriterium?.aktiv ?? true;
  }

  @override
  void dispose() {
    _fehlerFokus.dispose();
    _nameFokus.dispose();
    _auswahlwerteFokus.dispose();
    _name.dispose();
    _beschreibung.dispose();
    _auswahlwerte.dispose();
    super.dispose();
  }

  Future<void> _speichern() async {
    final nameFehlt = _name.text.trim().isEmpty;
    final auswahlwerteFehlen = _eingabetyp == KriteriumEingabetyp.auswahl &&
        _auswahlwerte.text.split('\n').every((wert) => wert.trim().isEmpty);
    if (nameFehlt || auswahlwerteFehlen) {
      setState(() {
        _nameFehlt = nameFehlt;
        _auswahlwerteFehlen = auswahlwerteFehlen;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Eingaben prüfen.')),
      );
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
        beschreibung: _beschreibung.text.trim().isEmpty
            ? null
            : _beschreibung.text.trim(),
        eingabetyp: _eingabetyp,
        reihenfolge: vorhanden?.reihenfolge ?? 1000,
        aktiv: _aktiv,
        objektart: _objektart,
        version: vorhanden?.version ?? 1,
        auswahlwerte: _auswahlwerte.text
            .split('\n')
            .map((wert) => wert.trim())
            .where((wert) => wert.isNotEmpty)
            .toList(),
        erstelltAm: vorhanden?.erstelltAm ?? jetzt,
        geaendertAm: jetzt,
      ));
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _speichert = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Das Kriterium konnte nicht gespeichert werden.')));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.kriterium == null
                    ? 'Kriterium anlegen'
                    : 'Kriterium bearbeiten',
              ),
            ),
            AppSupportMenu(
              contextName: SupportKontexte.kriterium(
                bearbeiten: widget.kriterium != null,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_nameFehlt || _auswahlwerteFehlen)
                  FormularFehlersammler(
                    focusNode: _fehlerFokus,
                    fehler: [
                      if (_nameFehlt) ('Name ist erforderlich.', _nameFokus),
                      if (_auswahlwerteFehlen)
                        (
                          'Mindestens ein Auswahlwert ist erforderlich.',
                          _auswahlwerteFokus,
                        ),
                    ],
                  ),
                TextField(
                    controller: _name,
                    focusNode: _nameFokus,
                    maxLength: 100,
                    decoration: InputDecoration(
                        labelText: 'Name (Pflichtfeld)',
                        errorText:
                            _nameFehlt ? 'Name ist erforderlich.' : null)),
                TextField(
                    controller: _beschreibung,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Beschreibung (optional)')),
                DropdownButtonFormField<KriteriumObjektart>(
                  initialValue: _objektart,
                  decoration: const InputDecoration(labelText: 'Objektart'),
                  items: [
                    for (final wert in KriteriumObjektart.values)
                      DropdownMenuItem(
                          value: wert, child: Text(_objektartLabel(wert)))
                  ],
                  onChanged: (wert) {
                    if (wert != null) setState(() => _objektart = wert);
                  },
                ),
                DropdownButtonFormField<KriteriumEingabetyp>(
                  initialValue: _eingabetyp,
                  decoration: const InputDecoration(labelText: 'Eingabetyp'),
                  items: [
                    for (final wert in KriteriumEingabetyp.values)
                      DropdownMenuItem(
                          value: wert, child: Text(_eingabetypLabel(wert)))
                  ],
                  onChanged: (wert) {
                    if (wert != null) setState(() => _eingabetyp = wert);
                  },
                ),
                if (_eingabetyp == KriteriumEingabetyp.auswahl)
                  TextField(
                    controller: _auswahlwerte,
                    focusNode: _auswahlwerteFokus,
                    maxLength: 1000,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Auswahlwerte (eine Zeile je Wert)',
                      errorText: _auswahlwerteFehlen
                          ? 'Mindestens ein Auswahlwert ist erforderlich.'
                          : null,
                    ),
                  ),
                SwitchListTile(
                    value: _aktiv,
                    onChanged: (wert) => setState(() => _aktiv = wert),
                    title: const Text('Aktiv')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed:
                  _speichert ? null : () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: _speichert ? null : _speichern,
              child: const Text('Speichern')),
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
