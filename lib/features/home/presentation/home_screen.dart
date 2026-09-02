import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/presentation/kriterien_screen.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/datenaustausch/presentation/datenaustausch_screen.dart';
import 'package:taugts/features/datenaustausch/services/export_service.dart';
import 'package:taugts/features/datenaustausch/services/export_ziel_service.dart';
import 'package:taugts/features/erlebnisse/presentation/entwuerfe_screen.dart';
import 'package:taugts/features/erlebnisse/presentation/erlebnis_screen.dart';
import 'package:taugts/features/orte/presentation/orte_screen.dart';
import 'package:taugts/features/produkte/presentation/produkte_screen.dart';
import 'package:taugts/features/profil/models/profil.dart';
import 'package:taugts/features/profil/presentation/profil_screen.dart';
import 'package:taugts/features/profil/services/profil_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    this.profil,
    this.profilRepository,
    this.bewertungsRepository,
    this.exportService,
    this.exportZielService,
    this.idGenerator,
    super.key,
  });

  final Profil? profil;
  final ProfilRepository? profilRepository;
  final BewertungsRepository? bewertungsRepository;
  final ExportService? exportService;
  final ExportZielService? exportZielService;
  final IdGenerator? idGenerator;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Profil? _profil = widget.profil;
  Future<List<Erlebnis>>? _erlebnisse;

  @override
  void initState() {
    super.initState();
    _erlebnisseNeuLaden();
  }

  void _erlebnisseNeuLaden() {
    final repository = widget.bewertungsRepository;
    _erlebnisse = repository?.ladeErlebnisse();
  }

  Future<void> _profilOeffnen() async {
    final profil = _profil;
    final repository = widget.profilRepository;
    if (profil == null || repository == null) return;
    final geaendert = await Navigator.of(context).push<Profil>(
      MaterialPageRoute(
        builder: (_) => ProfilScreen(profil: profil, repository: repository),
      ),
    );
    if (geaendert != null && mounted) {
      setState(() => _profil = geaendert);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil gespeichert.')),
      );
    }
  }

  Future<void> _produkteOeffnen() async {
    final repository = widget.bewertungsRepository;
    final idGenerator = widget.idGenerator;
    if (repository == null || idGenerator == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProdukteScreen(
          repository: repository,
          idGenerator: idGenerator,
          eigenesProfilId: _profil?.id,
        ),
      ),
    );
  }

  Future<void> _orteOeffnen() async {
    final repository = widget.bewertungsRepository;
    final idGenerator = widget.idGenerator;
    if (repository == null || idGenerator == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OrteScreen(
          repository: repository,
          idGenerator: idGenerator,
          eigenesProfilId: _profil?.id,
        ),
      ),
    );
  }

  Future<void> _kriterienOeffnen() async {
    final repository = widget.bewertungsRepository;
    final idGenerator = widget.idGenerator;
    if (repository == null || idGenerator == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => KriterienScreen(
          repository: repository,
          idGenerator: idGenerator,
        ),
      ),
    );
  }

  Future<void> _datenaustauschOeffnen() async {
    final exportService = widget.exportService;
    final exportZielService = widget.exportZielService;
    if (exportService == null || exportZielService == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DatenaustauschScreen(
          exportService: exportService,
          exportZielService: exportZielService,
        ),
      ),
    );
  }

  Future<void> _erlebnisseOeffnen() async {
    final repository = widget.bewertungsRepository;
    final idGenerator = widget.idGenerator;
    final profil = _profil;
    if (repository == null || idGenerator == null || profil == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EntwuerfeScreen(
          repository: repository,
          idGenerator: idGenerator,
          profil: profil,
        ),
      ),
    );
    if (!mounted) return;
    setState(_erlebnisseNeuLaden);
  }

  Future<void> _aktivesErlebnisOeffnen(Erlebnis erlebnis) async {
    final repository = widget.bewertungsRepository;
    final idGenerator = widget.idGenerator;
    final profil = _profil;
    if (repository == null || idGenerator == null || profil == null) return;
    await Navigator.of(context).push<Erlebnis>(
      MaterialPageRoute(
        builder: (_) => ErlebnisScreen(
          repository: repository,
          idGenerator: idGenerator,
          profil: profil,
          erlebnis: erlebnis,
        ),
      ),
    );
    if (!mounted) return;
    setState(_erlebnisseNeuLaden);
  }

  Future<void> _infoOeffnen(String titel, String beschreibung) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => _NochNichtVerfuegbarScreen(
            titel: titel,
            beschreibung: beschreibung,
          ),
        ),
      );

  Widget _navigationsKachel({
    required double width,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) =>
      SizedBox(
        width: width,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(label, textAlign: TextAlign.center),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final profil = _profil;
    final repositoryVerfuegbar = widget.bewertungsRepository != null &&
        widget.idGenerator != null &&
        profil != null;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: Text('Taugt’s?', overflow: TextOverflow.ellipsis),
            ),
            SizedBox(width: 4),
            AppLogo(key: Key('hauptmenue-logo'), size: 32),
          ],
        ),
        actions: [
          if (profil != null && widget.profilRepository != null)
            IconButton(
              onPressed: _profilOeffnen,
              icon: const Icon(Icons.person_outline),
              tooltip: 'Mein Profil bearbeiten',
            ),
          const AppSupportMenu(contextName: SupportKontexte.startseite),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          children: [
            Center(
              child: Semantics(
                image: true,
                label: 'Logo von Taugt’s?',
                child: Image.asset(
                  'assets/icons/app_icon_source.png',
                  width: 96,
                  height: 96,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                profil?.anzeigename == null
                    ? 'Was taugt’s?'
                    : 'Was taugt’s, ${profil!.anzeigename}?',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: repositoryVerfuegbar ? _erlebnisseOeffnen : null,
              icon: const Icon(Icons.thumb_up_alt_outlined),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Jetzt bewerten'),
              ),
            ),
            if (_erlebnisse != null) ...[
              const SizedBox(height: 20),
              FutureBuilder<List<Erlebnis>>(
                future: _erlebnisse,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Semantics(
                      liveRegion: true,
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                                'Aktive Erlebnisse konnten nicht geladen werden.'),
                          ),
                          TextButton(
                            onPressed: () => setState(_erlebnisseNeuLaden),
                            child: const Text('Erneut versuchen'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Semantics(
                      label: 'Aktive Erlebnisse werden geladen',
                      child: const LinearProgressIndicator(),
                    );
                  }
                  final aktive = snapshot.data!
                      .where((e) => e.status == Erlebnisstatus.aktiv)
                      .toList(growable: false);
                  if (aktive.isEmpty) return const SizedBox.shrink();
                  final genauEins = aktive.length == 1;
                  final erlebnis = genauEins ? aktive.single : null;
                  final label = erlebnis?.typ == Erlebnistyp.restaurantbesuch
                      ? 'Bestellung öffnen'
                      : erlebnis?.typ == Erlebnistyp.einkauf
                          ? 'Einkauf öffnen'
                          : 'Aktive Erlebnisse auswählen';
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              genauEins
                                  ? 'Aktives Erlebnis'
                                  : '${aktive.length} aktive Erlebnisse',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            genauEins
                                ? erlebnis!.typ == Erlebnistyp.restaurantbesuch
                                    ? 'Restaurantbesuch'
                                    : 'Einkauf'
                                : 'Wähle aus, welches Erlebnis du fortsetzen möchtest.',
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: genauEins
                                ? () => _aktivesErlebnisOeffnen(erlebnis!)
                                : _erlebnisseOeffnen,
                            child: Text(label),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                'Bereiche',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final zweispaltig = constraints.maxWidth >= 560;
                final breite = zweispaltig
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _navigationsKachel(
                      width: breite,
                      icon: Icons.inventory_2_outlined,
                      label: 'Dinge',
                      onPressed: widget.bewertungsRepository != null &&
                              widget.idGenerator != null
                          ? _produkteOeffnen
                          : null,
                    ),
                    _navigationsKachel(
                      width: breite,
                      icon: Icons.place_outlined,
                      label: 'Orte',
                      onPressed: widget.bewertungsRepository != null &&
                              widget.idGenerator != null
                          ? _orteOeffnen
                          : null,
                    ),
                    _navigationsKachel(
                      width: breite,
                      icon: Icons.star_outline,
                      label: 'Bewertungen',
                      onPressed: () => _infoOeffnen(
                        'Bewertungen',
                        'Eine übergreifende Bewertungsliste wird in einer späteren Story ergänzt. Bereits vorhandene Verläufe bleiben über Dinge und Orte erreichbar.',
                      ),
                    ),
                    _navigationsKachel(
                      width: breite,
                      icon: Icons.search,
                      label: 'Suche',
                      onPressed: () => _infoOeffnen(
                        'Suche',
                        'Die globale Suche ist noch nicht verfügbar. Dinge und Orte können bereits in ihren jeweiligen Bereichen gesucht werden.',
                      ),
                    ),
                    _navigationsKachel(
                      width: breite,
                      icon: Icons.import_export,
                      label: 'Import/Export',
                      onPressed: widget.exportService != null &&
                              widget.exportZielService != null
                          ? _datenaustauschOeffnen
                          : null,
                    ),
                    _navigationsKachel(
                      width: breite,
                      icon: Icons.settings_outlined,
                      label: 'Einstellungen',
                      onPressed: widget.bewertungsRepository != null &&
                              widget.idGenerator != null
                          ? _kriterienOeffnen
                          : () => _infoOeffnen(
                                'Einstellungen',
                                'Einstellungen stehen nach vollständigem App-Start zur Verfügung.',
                              ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: repositoryVerfuegbar ? _erlebnisseOeffnen : null,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Erlebnis registrieren'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: repositoryVerfuegbar ? _erlebnisseOeffnen : null,
              icon: const Icon(Icons.history),
              label: const Text('Alle Erlebnisse'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NochNichtVerfuegbarScreen extends StatelessWidget {
  const _NochNichtVerfuegbarScreen({
    required this.titel,
    required this.beschreibung,
  });

  final String titel;
  final String beschreibung;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(titel)),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 48),
                    const SizedBox(height: 16),
                    Semantics(
                      header: true,
                      child: Text(
                        '$titel noch nicht verfügbar',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(beschreibung, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Zurück'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
