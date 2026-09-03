import 'package:flutter/material.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/kategorien/models/kategorie.dart';
import 'package:taugts/features/kategorien/models/kriterienset.dart';
import 'package:taugts/features/kategorien/services/kategorie_repository.dart';
import 'package:taugts/features/kategorien/services/kriterienset_repository.dart';
import 'package:taugts/features/kategorien/services/kriterienset_service.dart';

class KriteriensetsScreen extends StatefulWidget {
  const KriteriensetsScreen({
    required this.kategorien,
    required this.kriteriensets,
    required this.bewertungen,
    super.key,
  });

  final KategorieRepository kategorien;
  final KriteriensetRepository kriteriensets;
  final BewertungsRepository bewertungen;

  @override
  State<KriteriensetsScreen> createState() => _KriteriensetsScreenState();
}

class _KriteriensetsScreenState extends State<KriteriensetsScreen> {
  late final List<Kategorie> _kategorien = widget.kategorien.alle();
  Kategorie? _auswahl;
  KriteriumObjektart _fallback = KriteriumObjektart.getraenk;
  KriteriensetModus _modus = KriteriensetModus.erweitern;
  Set<String> _explizit = {};
  late Future<List<Bewertungskriterium>> _kriterien;
  Future<WirksamesKriterienset>? _vorschau;
  String? _meldung;

  @override
  void initState() {
    super.initState();
    _kriterien = widget.bewertungen.ladeKriterien(nurAktive: true);
    if (_kategorien.isNotEmpty) _waehle(_kategorien.first);
  }

  void _waehle(Kategorie kategorie) {
    final regel = widget.kriteriensets.regelFuer(kategorie.id);
    setState(() {
      _auswahl = kategorie;
      _fallback = regel?.fallbackObjektart ?? _standardFallback(kategorie);
      _modus = regel?.modus ?? KriteriensetModus.erweitern;
      _explizit = widget.kriteriensets
          .zuordnungenFuer(kategorie.id)
          .map((wert) => wert.kriteriumId)
          .toSet();
      _meldung = null;
      _ladeVorschau();
    });
  }

  void _ladeVorschau() {
    final kategorie = _auswahl;
    if (kategorie == null) return;
    _vorschau = KriteriensetService(
      kategorien: widget.kategorien,
      kriteriensets: widget.kriteriensets,
      bewertungen: widget.bewertungen,
    ).ermittle(kategorieId: kategorie.id, fallbackObjektart: _fallback);
  }

  void _speichern() {
    final kategorie = _auswahl;
    if (kategorie == null) return;
    widget.kriteriensets.speichereRegel(
      KategorieKriteriensetRegel(
        kategorieId: kategorie.id,
        fallbackObjektart: _fallback,
        modus: _modus,
      ),
    );
    widget.kriteriensets.setzeZuordnungen(kategorie.id, _explizit);
    setState(() {
      _meldung = 'Kriterienset gespeichert.';
      _ladeVorschau();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Kategorie-Kriteriensets'),
          actions: const [
            AppSupportMenu(contextName: SupportKontexte.kriteriensetsVerwalten),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              const Text(
                'Standardkriterien bilden den Fallback. Kategorien können sie erweitern oder ersetzen; geerbte und explizite Quellen bleiben in der Vorschau sichtbar.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Kategorie>(
                initialValue: _auswahl,
                decoration: const InputDecoration(labelText: 'Kategorie'),
                items: [
                  for (final kategorie in _kategorien)
                    DropdownMenuItem(
                      value: kategorie,
                      child: Text(kategorie.name),
                    ),
                ],
                onChanged: (wert) {
                  if (wert != null) _waehle(wert);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<KriteriumObjektart>(
                initialValue: _fallback,
                decoration: const InputDecoration(labelText: 'Standardset'),
                items: [
                  for (final art in KriteriumObjektart.values)
                    DropdownMenuItem(value: art, child: Text(_artLabel(art))),
                ],
                onChanged: (wert) => setState(() {
                  if (wert != null) _fallback = wert;
                }),
              ),
              const SizedBox(height: 12),
              SegmentedButton<KriteriensetModus>(
                segments: const [
                  ButtonSegment(
                    value: KriteriensetModus.erweitern,
                    label: Text('Erweitern'),
                  ),
                  ButtonSegment(
                    value: KriteriensetModus.ersetzen,
                    label: Text('Ersetzen'),
                  ),
                ],
                selected: {_modus},
                onSelectionChanged: (werte) =>
                    setState(() => _modus = werte.single),
              ),
              const SizedBox(height: 20),
              Semantics(
                header: true,
                child: Text(
                  'Explizite Kriterien',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FutureBuilder<List<Bewertungskriterium>>(
                future: _kriterien,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                        'Kriterien konnten nicht geladen werden.');
                  }
                  if (!snapshot.hasData) {
                    return Semantics(
                      label: 'Kriterien werden geladen',
                      child: const LinearProgressIndicator(),
                    );
                  }
                  return Column(
                    children: [
                      for (final kriterium in snapshot.data!)
                        CheckboxListTile(
                          value: _explizit.contains(kriterium.id),
                          title: Text(kriterium.name),
                          subtitle:
                              Text(_artLabel(kriterium.wirksameObjektart)),
                          onChanged: (aktiv) => setState(() {
                            if (aktiv == true) {
                              _explizit.add(kriterium.id);
                            } else {
                              _explizit.remove(kriterium.id);
                            }
                          }),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _auswahl == null ? null : _speichern,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Kriterienset speichern'),
              ),
              if (_meldung != null) ...[
                const SizedBox(height: 12),
                Semantics(liveRegion: true, child: Text(_meldung!)),
              ],
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  'Wirksame Vorschau',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (_vorschau != null)
                FutureBuilder<WirksamesKriterienset>(
                  future: _vorschau,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    final set = snapshot.data!;
                    if (set.eintraege.isEmpty) {
                      return const Text('Das wirksame Set ist leer.');
                    }
                    return Column(
                      children: [
                        for (final eintrag in set.eintraege)
                          ListTile(
                            title: Text(eintrag.kriterium.name),
                            subtitle: Text(
                              '${eintrag.geerbt ? 'Geerbt' : 'Explizit'} · Quelle: ${eintrag.quelle} · Kriterium Version ${eintrag.kriterium.version}',
                            ),
                          ),
                        Text('Set-Version ${set.version}'),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      );

  KriteriumObjektart _standardFallback(Kategorie kategorie) {
    if (kategorie.bereich == KategorieBereich.ort) {
      return kategorie.name == 'Geschäft'
          ? KriteriumObjektart.geschaeft
          : KriteriumObjektart.gastronomie;
    }
    return switch (kategorie.name) {
      'Speise' => KriteriumObjektart.speise,
      'Bier' || 'Getränk' => KriteriumObjektart.getraenk,
      _ => KriteriumObjektart.sonstigesProdukt,
    };
  }

  String _artLabel(KriteriumObjektart art) => switch (art) {
        KriteriumObjektart.getraenk => 'Getränk',
        KriteriumObjektart.speise => 'Speise',
        KriteriumObjektart.sonstigesProdukt => 'Sonstiges Produkt',
        KriteriumObjektart.gastronomie => 'Gastronomie',
        KriteriumObjektart.geschaeft => 'Geschäft',
      };
}
