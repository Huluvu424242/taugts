import 'package:flutter/material.dart';
import 'package:taugts/app/taugts_app.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/services/datenbank_factory.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/profil/services/sqlite_profil_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final datenbank = await oeffneLokaleDatenbank();
  const idGenerator = UuidGenerator();
  final profilRepository = SqliteProfilRepository(
    datenbank,
    idGenerator: idGenerator,
  );
  final profil = await profilRepository.ladeOderErstelleProfil();
  runApp(
    TaugtsApp(
      profil: profil,
      profilRepository: profilRepository,
      bewertungsRepository: SqliteBewertungsRepository(datenbank),
      idGenerator: idGenerator,
    ),
  );
}
