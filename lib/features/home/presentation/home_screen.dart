import 'package:flutter/material.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/services/bewertungs_repository.dart';
import 'package:taugts/features/profil/models/profil.dart';
import 'package:taugts/features/profil/presentation/profil_screen.dart';
import 'package:taugts/features/profil/services/profil_repository.dart';
import 'package:taugts/features/produkte/presentation/produkte_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Profil? _profil = widget.profil;

  Future<void> _profilOeffnen() async {
    final profil = _profil;
    final repository = widget.profilRepository;
    if (profil == null || repository == null) return;
    final geaendert = await Navigator.of(context).push<Profil>(
      MaterialPageRoute(
        builder: (_) => ProfilScreen(
          profil: profil,
          repository: repository,
        ),
      ),
    );
    if (geaendert != null && mounted) {
      setState(() => _profil = geaendert);
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profil = _profil;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taugt’s?'),
        actions: [
          if (profil != null && widget.profilRepository != null)
            IconButton(
              onPressed: _profilOeffnen,
              icon: const Icon(Icons.person_outline),
              tooltip: 'Mein Profil bearbeiten',
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    profil?.anzeigename == null
                        ? 'Was taugt’s?'
                        : 'Was taugt’s, ${profil!.anzeigename}?',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.bewertungsRepository != null &&
                    widget.idGenerator != null) ...[
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _produkteOeffnen,
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Produkte verwalten'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
