import 'package:flutter/material.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';
import 'package:taugts/features/auswertungen/services/auswertungs_service.dart';

class AuswertungenScreen extends StatefulWidget {
  const AuswertungenScreen({required this.service, super.key});

  final AuswertungsService service;

  @override
  State<AuswertungenScreen> createState() => _AuswertungenScreenState();
}

class _AuswertungenScreenState extends State<AuswertungenScreen> {
  late Future<AuswertungsUebersicht> _daten =
      widget.service.berechne(const AuswertungsFilter());

  void _neuLaden() => setState(() {
        _daten = widget.service.berechne(const AuswertungsFilter());
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Auswertungen'),
          actions: const [
            AppSupportMenu(contextName: SupportKontexte.auswertungen),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<AuswertungsUebersicht>(
            future: _daten,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: FilledButton.icon(
                    onPressed: _neuLaden,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Auswertungen erneut laden'),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return Semantics(
                  label: 'Auswertungen werden berechnet',
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              final daten = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  const Text(
                    'Alle Berechnungen erfolgen lokal. Mittelwerte werden nur für Qualitätswertungen derselben Kriterienversion gebildet; fehlende Werte werden ausgelassen.',
                  ),
                  const SizedBox(height: 16),
                  _Karte(
                    titel: 'Bewertungen',
                    zeilen: ['${daten.bewertungsanzahl} gespeicherte Kriterienwerte'],
                  ),
                  _Karte(
                    titel: 'Vergleichbare Durchschnittswerte',
                    zeilen: [
                      for (final wert in daten.durchschnitte)
                        '${wert.kriterium} · Version ${wert.kriteriumVersion}: ${wert.durchschnitt.toStringAsFixed(2)} aus ${wert.anzahl} Werten',
                    ],
                  ),
                  _Karte(
                    titel: 'Preisentwicklung nach Ort',
                    zeilen: [
                      for (final wert in daten.preisverlauf)
                        '${wert.zeitpunkt.toLocal()}: ${wert.wert.toStringAsFixed(2)} · ${wert.beschreibung}',
                    ],
                  ),
                  _Karte(
                    titel: 'Qualitätsverlauf von Produkten',
                    zeilen: [
                      for (final wert in daten.qualitaetsverlauf)
                        '${wert.zeitpunkt.toLocal()}: ${wert.wert} · ${wert.beschreibung}',
                    ],
                  ),
                  _Karte(
                    titel: 'Ortsbewertungen im Zeitverlauf',
                    zeilen: [
                      for (final wert in daten.ortsverlauf)
                        '${wert.zeitpunkt.toLocal()}: ${wert.wert} · ${wert.beschreibung}',
                    ],
                  ),
                  _Karte(
                    titel: 'Erlebnisse nach Typ, Wochentag und Tageszeit',
                    zeilen: [
                      for (final gruppe in daten.erlebnisgruppen)
                        '${gruppe.schluessel}: ${gruppe.anzahl} Erlebnisse, ${gruppe.gesamtdauerMinuten} Minuten Gesamtdauer',
                    ],
                  ),
                  _Karte(
                    titel: 'Andrang / Auslastung',
                    zeilen: [
                      for (final wert in daten.andrangBeobachtungen)
                        '${wert.zeitpunkt.toLocal()}: ${wert.wert} · ${wert.beschreibung}',
                    ],
                  ),
                  const Text(
                    'Zeitliche Zusammenhänge werden als Beobachtung dargestellt. Aus Uhrzeit oder Wochentag wird kein Andrang abgeleitet und keine Ursache behauptet.',
                  ),
                ],
              );
            },
          ),
        ),
      );
}

class _Karte extends StatelessWidget {
  const _Karte({required this.titel, required this.zeilen});

  final String titel;
  final List<String> zeilen;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(titel, style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              if (zeilen.isEmpty)
                const Text('Noch keine passenden Daten vorhanden.')
              else
                for (final zeile in zeilen)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(zeile),
                  ),
            ],
          ),
        ),
      );
}
