import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/theme/app_theme.dart';
import 'package:taugts/features/auswertungen/services/auswertungs_service.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/datenaustausch/services/export_service.dart';
import 'package:taugts/features/datenaustausch/services/export_ziel_service.dart';
import 'package:taugts/features/home/presentation/hauptnavigation_screen.dart';
import 'package:taugts/features/kategorien/services/kategorie_repository.dart';
import 'package:taugts/features/kategorien/services/kriterienset_repository.dart';
import 'package:taugts/features/profil/models/profil.dart';
import 'package:taugts/features/profil/services/profil_repository.dart';
import 'package:taugts/features/suche/services/suche_service.dart';

class TaugtsApp extends StatelessWidget {
  const TaugtsApp({
    this.profil,
    this.profilRepository,
    this.bewertungsRepository,
    this.exportService,
    this.exportZielService,
    this.idGenerator,
    this.kategorieRepository,
    this.kriteriensetRepository,
    this.sucheService,
    this.auswertungsService,
    super.key,
  });

  final Profil? profil;
  final ProfilRepository? profilRepository;
  final BewertungsRepository? bewertungsRepository;
  final ExportService? exportService;
  final ExportZielService? exportZielService;
  final IdGenerator? idGenerator;
  final KategorieRepository? kategorieRepository;
  final KriteriensetRepository? kriteriensetRepository;
  final SucheService? sucheService;
  final AuswertungsService? auswertungsService;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HauptnavigationScreen(
          profil: profil,
          profilRepository: profilRepository,
          bewertungsRepository: bewertungsRepository,
          exportService: exportService,
          exportZielService: exportZielService,
          idGenerator: idGenerator,
          kategorieRepository: kategorieRepository,
          kriteriensetRepository: kriteriensetRepository,
          sucheService: sucheService,
          auswertungsService: auswertungsService,
        ),
        theme: AppTheme.light,
        title: 'Taugt’s?',
      );
}
