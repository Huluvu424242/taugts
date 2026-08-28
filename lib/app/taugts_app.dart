import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/core/theme/app_theme.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/home/presentation/home_screen.dart';
import 'package:taugts/features/profil/models/profil.dart';
import 'package:taugts/features/profil/services/profil_repository.dart';

class TaugtsApp extends StatelessWidget {
  const TaugtsApp({
    this.profil,
    this.profilRepository,
    this.bewertungsRepository,
    this.idGenerator,
    super.key,
  });

  final Profil? profil;
  final ProfilRepository? profilRepository;
  final BewertungsRepository? bewertungsRepository;
  final IdGenerator? idGenerator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(
        profil: profil,
        profilRepository: profilRepository,
        bewertungsRepository: bewertungsRepository,
        idGenerator: idGenerator,
      ),
      theme: AppTheme.light,
      title: 'Taugt’s?',
    );
  }
}
