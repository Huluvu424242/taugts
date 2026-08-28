import 'package:flutter/material.dart';
import 'package:taugts/features/profil/models/profil.dart';
import 'package:taugts/features/profil/presentation/profil_screen.dart';
import 'package:taugts/features/profil/services/profil_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    this.profil,
    this.profilRepository,
    super.key,
  });

  final Profil? profil;
  final ProfilRepository? profilRepository;

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
            child: Semantics(
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
          ),
        ),
      ),
    );
  }
}
