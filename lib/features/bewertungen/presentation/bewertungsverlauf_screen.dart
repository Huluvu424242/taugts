import 'package:flutter/material.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';

class BewertungsverlaufScreen extends StatefulWidget {
  BewertungsverlaufScreen.fuerProdukt({
    required this.repository,
    required Produkt produkt,
    this.eigenesProfilId,
    super.key,
  })  : objektId = produkt.id,
        objektName = produkt.anzeigetitel,
        istOrt = false;

  BewertungsverlaufScreen.fuerOrt({
    required this.repository,
    required Ort ort,
    this.eigenesProfilId,
    super.key,
  })  : objektId = ort.id,
        objektName = ort.name,
        istOrt = true;

  final BewertungsRepository repository;
  final String objektId;
  final String objektName;
  final String? eigenesProfilId;
  final bool istOrt;

  @override
  State<BewertungsverlaufScreen> createState() =>
      _BewertungsverlaufScreenState();
}

class _BewertungsverlaufScreenState extends State<BewertungsverlaufScreen> {
  late Future<List<BewertungsverlaufEintrag>> _laden = _ladeVerlauf();

  Future<List<BewertungsverlaufEintrag>> _ladeVerlauf() => widget.istOrt
      ? widget.repository.ladeOrtsverlauf(widget.objektId)
      : widget.repository.ladeProduktverlauf(widget.objektId);

  void _neuLaden() => setState(() => _laden = _ladeVerlauf());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Bewertungsverlauf'),
          actions: const [
            AppSupportMenu(contextName: SupportKontexte.bewertungsverlauf),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<BewertungsverlaufEintrag>>(
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
                            'Der Bewertungsverlauf konnte nicht geladen werden.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _neuLaden,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Verlauf erneut laden'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return Center(
                  child: Semantics(
                    label: 'Bewertungsverlauf wird geladen',
                    child: const CircularProgressIndicator(),
                  ),
                );
              }
              final eintraege = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                children: [
                  Semantics(
                    header: true,
                    child: Text(widget.objektName, style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  const SizedBox(height: 4),
                  const Text('Stammdaten bleiben von den folgenden historischen Beobachtungen getrennt.'),
                  const SizedBox(height: 20),
                  if (eintraege.isEmpty)
                    const Text('Für dieses Objekt liegen noch keine historischen Bewertungen oder Preise vor.')
                  else
                    for (final eintrag in eintraege) _Verlaufskarte(
                      eintrag: eintrag,
                      istEigen: widget.eigenesProfilId == null ||
                          eintrag.herkunftProfilId == widget.eigenesProfilId,
                    ),
                ],
              );
            },
          ),
        ),
      );
}

class _Verlaufskarte extends StatelessWidget {
  const _Verlaufskarte({required this.eintrag, required this.istEigen});

  final BewertungsverlaufEintrag eintrag;
  final bool istEigen;

  @override
  Widget build(BuildContext context) {
    final lokal = eintrag.erlebnis.erlebtAm.toLocal();
    final datum = MaterialLocalizations.of(context).formatFullDate(lokal);
    final ort = eintrag.ort?.name ?? 'Ort nicht erfasst';
    final preis = eintrag.preis;
    final preisText = preis == null
        ? _historischerPreisText(eintrag.historischerPreis)
        : '${preis.betrag.dezimalText} ${preis.betrag.waehrung}';
    final gesamtwertung = _gesamtwertung(eintrag.bewertungen);
    return Card(
      child: ExpansionTile(
        maintainState: true,
        title: Text('$datum · $ort'),
        subtitle: Text([
          _erlebnistyp(eintrag.erlebnis.typ),
          if (gesamtwertung != null)
            'Gesamtwertung: ${_wertText(gesamtwertung)}',
          if (eintrag.position != null) '${eintrag.position!.anzahl} ×',
          if (preisText != null) preisText,
          if (eintrag.historischeMenge != null)
            '${eintrag.historischeMenge} ${eintrag.historischesGebinde ?? ''}'
                .trim(),
          istEigen ? 'Eigene Bewertung' : 'Importierte Bewertung',
        ].join(' · ')),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_zeitraum(context, eintrag.erlebnis)),
                if (eintrag.bewertungen.isEmpty && eintrag.notiz == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Keine Einzelwerte erfasst.'),
                  ),
                for (final bewertung in eintrag.bewertungen)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(bewertung.kriteriumName ?? 'Historisches Kriterium'),
                    subtitle: Text('Kriterienversion ${bewertung.kriteriumVersion ?? 1}'),
                    trailing: Text(_wertText(bewertung)),
                  ),
                if (eintrag.notiz != null) Text('Notiz: ${eintrag.notiz}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _zeitraum(BuildContext context, Erlebnis erlebnis) {
    final lokalisierung = MaterialLocalizations.of(context);
    String zeit(DateTime wert) => lokalisierung.formatTimeOfDay(
          TimeOfDay.fromDateTime(wert.toLocal()),
        );
    if (erlebnis.tatsaechlicherBeginn == null) {
      return 'Zeitpunkt nicht vollständig erfasst';
    }
    if (erlebnis.tatsaechlichesEnde == null) {
      return 'Beginn: ${zeit(erlebnis.tatsaechlicherBeginn!)}';
    }
    return 'Zeitraum: ${zeit(erlebnis.tatsaechlicherBeginn!)}–${zeit(erlebnis.tatsaechlichesEnde!)}';
  }

  String _wertText(Bewertung bewertung) => switch (bewertung.kriteriumEingabetyp) {
        KriteriumEingabetyp.jaNein => bewertung.wert == 0 ? 'Nein' : 'Ja',
        KriteriumEingabetyp.zahl => bewertung.wert.toString(),
        _ => '${bewertung.wert.toStringAsFixed(0)} / 5',
      };

  Bewertung? _gesamtwertung(List<Bewertung> bewertungen) {
    for (final bewertung in bewertungen) {
      if (bewertung.kriteriumName == 'Gesamturteil') {
        return bewertung;
      }
    }
    return null;
  }

  String? _historischerPreisText(double? preis) => preis == null
      ? null
      : '${preis.toStringAsFixed(2).replaceAll('.', ',')} EUR';

  String _erlebnistyp(Erlebnistyp typ) => switch (typ) {
        Erlebnistyp.restaurantbesuch => 'Restaurantbesuch',
        Erlebnistyp.einkauf => 'Einkauf',
      };
}
