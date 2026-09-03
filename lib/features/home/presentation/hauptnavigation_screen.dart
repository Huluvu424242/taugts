import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/datenaustausch/services/export_service.dart';
import 'package:taugts/features/datenaustausch/services/export_ziel_service.dart';
import 'package:taugts/features/home/presentation/home_screen.dart';
import 'package:taugts/features/kategorien/presentation/kriteriensets_screen.dart';
import 'package:taugts/features/kategorien/services/kategorie_repository.dart';
import 'package:taugts/features/kategorien/services/kriterienset_repository.dart';
import 'package:taugts/features/profil/models/profil.dart';
import 'package:taugts/features/profil/services/profil_repository.dart';

class HauptnavigationScreen extends StatefulWidget {
  const HauptnavigationScreen({
    required this.profil,
    required this.profilRepository,
    required this.bewertungsRepository,
    required this.exportService,
    required this.exportZielService,
    required this.idGenerator,
    required this.kategorieRepository,
    required this.kriteriensetRepository,
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

  @override
  State<HauptnavigationScreen> createState() => _HauptnavigationScreenState();
}

class _HauptnavigationScreenState extends State<HauptnavigationScreen> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final bewertungen = widget.bewertungsRepository;
    final kategorien = widget.kategorieRepository;
    final kriteriensets = widget.kriteriensetRepository;
    final kannSets =
        bewertungen != null && kategorien != null && kriteriensets != null;
    final screens = <Widget>[
      HomeScreen(
        profil: widget.profil,
        profilRepository: widget.profilRepository,
        bewertungsRepository: bewertungen,
        exportService: widget.exportService,
        exportZielService: widget.exportZielService,
        idGenerator: widget.idGenerator,
      ),
      if (kannSets)
        KriteriensetsScreen(
          kategorien: kategorien,
          kriteriensets: kriteriensets,
          bewertungen: bewertungen,
        )
      else
        const _NichtVerfuegbar(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Start',
          ),
          NavigationDestination(
            icon: Icon(Icons.rule_outlined),
            selectedIcon: Icon(Icons.rule),
            label: 'Kriterien-Sets',
          ),
        ],
      ),
    );
  }
}

class _NichtVerfuegbar extends StatelessWidget {
  const _NichtVerfuegbar();

  @override
  Widget build(BuildContext context) => const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Kategorie-Kriteriensets sind nicht verfügbar.'),
          ),
        ),
      );
}
