import 'package:flutter/material.dart';

Future<void> fokussiereFormularfeld(FocusNode fokus) async {
  final feldContext = fokus.context;
  if (feldContext != null && feldContext.mounted) {
    await Scrollable.ensureVisible(
      feldContext,
      alignment: 0.2,
      duration: const Duration(milliseconds: 250),
    );
  }
  if (fokus.context?.mounted ?? false) {
    fokus.requestFocus();
  }
}

class FormularFehlersammler extends StatelessWidget {
  const FormularFehlersammler({
    required this.focusNode,
    required this.fehler,
    super.key,
  });

  final FocusNode focusNode;
  final List<(String, FocusNode)> fehler;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        container: true,
        label: '${fehler.length} Validierungsfehler',
        child: Focus(
          focusNode: focusNode,
          child: Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bitte Eingaben prüfen'),
                  for (final eintrag in fehler)
                    TextButton(
                      onPressed: () => fokussiereFormularfeld(eintrag.$2),
                      child: Text(eintrag.$1),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}
