import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:taugts/app/taugts_app.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/core/theme/app_theme.dart';
import 'package:taugts/features/auswertungen/services/sqlite_auswertungs_service.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/bewertungen/services/datenbank_factory.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/datenaustausch/services/export_service.dart';
import 'package:taugts/features/datenaustausch/services/export_ziel_service.dart';
import 'package:taugts/features/kategorien/services/kategorie_repository.dart';
import 'package:taugts/features/kategorien/services/kriterienset_repository.dart';
import 'package:taugts/features/kategorien/services/sqlite_kategorie_repository.dart';
import 'package:taugts/features/kategorien/services/sqlite_klassifikations_repository.dart';
import 'package:taugts/features/kategorien/services/sqlite_kriterienset_repository.dart';
import 'package:taugts/features/profil/models/profil.dart';
import 'package:taugts/features/profil/services/profil_repository.dart';
import 'package:taugts/features/profil/services/sqlite_profil_repository.dart';
import 'package:taugts/features/suche/services/sqlite_suche_service.dart';
import 'package:taugts/features/suche/services/suche_service.dart';

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<_StartDaten> _start = _initialisieren();

  Future<_StartDaten> _initialisieren() async {
    final datenbank = await oeffneLokaleDatenbank();
    final paket = await PackageInfo.fromPlatform();
    const idGenerator = UuidGenerator();
    final profilRepository = SqliteProfilRepository(
      datenbank,
      idGenerator: idGenerator,
    );
    final kategorieRepository = SqliteKategorieRepository(datenbank);
    SqliteKlassifikationsRepository(datenbank);
    final kriteriensetRepository = SqliteKriteriensetRepository(datenbank);
    final bewertungsRepository = SqliteBewertungsRepository(datenbank);
    return _StartDaten(
      profil: await profilRepository.ladeOderErstelleProfil(),
      profilRepository: profilRepository,
      bewertungsRepository: bewertungsRepository,
      kategorieRepository: kategorieRepository,
      kriteriensetRepository: kriteriensetRepository,
      sucheService: SqliteSucheService(datenbank),
      auswertungsService: SqliteAuswertungsService(datenbank),
      exportService: ExportService(
        datenbank,
        appVersion: '${paket.version}+${paket.buildNumber}',
      ),
      exportZielService: SystemExportZielService(),
      idGenerator: idGenerator,
    );
  }

  void _erneutVersuchen() {
    setState(() => _start = _initialisieren());
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_StartDaten>(
        future: _start,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final daten = snapshot.data!;
            return TaugtsApp(
              profil: daten.profil,
              profilRepository: daten.profilRepository,
              bewertungsRepository: daten.bewertungsRepository,
              kategorieRepository: daten.kategorieRepository,
              kriteriensetRepository: daten.kriteriensetRepository,
              sucheService: daten.sucheService,
              auswertungsService: daten.auswertungsService,
              exportService: daten.exportService,
              exportZielService: daten.exportZielService,
              idGenerator: daten.idGenerator,
            );
          }
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            title: 'Taugt’s?',
            home: Scaffold(
              appBar: AppBar(
                actions: const [
                  AppSupportMenu(contextName: SupportKontexte.appStart),
                ],
              ),
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Semantics(
                      image: true,
                      label: 'Logo von Taugt’s?',
                      child: Image.asset(
                        'assets/icons/app_icon_source.png',
                        width: 128,
                        height: 128,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (snapshot.hasError) ...[
                      const Text(
                        'Die lokalen Daten konnten nicht geladen werden.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: FilledButton.icon(
                          onPressed: _erneutVersuchen,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Erneut versuchen'),
                        ),
                      ),
                    ] else
                      Center(
                        child: Semantics(
                          label: 'Taugt’s? wird vorbereitet',
                          child: const CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

class _StartDaten {
  const _StartDaten({
    required this.profil,
    required this.profilRepository,
    required this.bewertungsRepository,
    required this.kategorieRepository,
    required this.kriteriensetRepository,
    required this.sucheService,
    required this.auswertungsService,
    required this.exportService,
    required this.exportZielService,
    required this.idGenerator,
  });

  final Profil profil;
  final ProfilRepository profilRepository;
  final BewertungsRepository bewertungsRepository;
  final KategorieRepository kategorieRepository;
  final KriteriensetRepository kriteriensetRepository;
  final SucheService sucheService;
  final SqliteAuswertungsService auswertungsService;
  final ExportService exportService;
  final ExportZielService exportZielService;
  final IdGenerator idGenerator;
}
