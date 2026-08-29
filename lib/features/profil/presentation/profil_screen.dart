import 'package:flutter/material.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/support_kontexte.dart';
import 'package:taugts/features/profil/models/profil.dart';
import 'package:taugts/features/profil/services/profil_repository.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({
    required this.profil,
    required this.repository,
    super.key,
  });

  final Profil profil;
  final ProfilRepository repository;

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  late final TextEditingController _anzeigenameController;
  var _speichert = false;

  @override
  void initState() {
    super.initState();
    _anzeigenameController = TextEditingController(
      text: widget.profil.anzeigename,
    );
  }

  @override
  void dispose() {
    _anzeigenameController.dispose();
    super.dispose();
  }

  Future<void> _speichern() async {
    setState(() => _speichert = true);
    final name = _anzeigenameController.text.trim();
    final profil = widget.profil.mitAnzeigename(
      name.isEmpty ? null : name,
      DateTime.now().toUtc(),
    );
    try {
      await widget.repository.speichereProfil(profil);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(profil);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _speichert = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Das Profil konnte nicht gespeichert werden.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Mein Profil'),
          actions: const [
            AppSupportMenu(contextName: SupportKontexte.profil),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: _anzeigenameController,
                decoration: const InputDecoration(
                  labelText: 'Anzeigename (optional)',
                  helperText:
                      'Bleibt leer, wenn du keinen Namen angeben möchtest.',
                ),
                maxLength: 80,
                textInputAction: TextInputAction.done,
                onSubmitted: _speichert ? null : (_) => _speichern(),
              ),
              const SizedBox(height: 16),
              SelectableText(
                'Profil-ID: ${widget.profil.id}',
                semanticsLabel: 'Stabile Profil-ID: ${widget.profil.id}',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _speichert ? null : _speichern,
                child: Text(_speichert ? 'Speichert …' : 'Profil speichern'),
              ),
            ],
          ),
        ),
      );
}
