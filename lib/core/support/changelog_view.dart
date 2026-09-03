import 'package:flutter/material.dart';

class ChangelogDarstellung extends StatelessWidget {
  const ChangelogDarstellung({required this.markdown, super.key});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final eintraege = _parse(markdown);
    if (eintraege.isEmpty) {
      return const Text('Für diese Version ist noch keine Änderungshistorie verfügbar.');
    }

    return ListView.separated(
      key: const Key('aenderungshistorie-inhalt'),
      shrinkWrap: true,
      itemCount: eintraege.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _Versionskarte(eintrag: eintraege[index]),
    );
  }
}

class _Versionskarte extends StatelessWidget {
  const _Versionskarte({required this.eintrag});

  final _Versionseintrag eintrag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Row(
                children: [
                  Icon(
                    eintrag.istUnveroeffentlicht
                        ? Icons.auto_awesome_outlined
                        : Icons.new_releases_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      eintrag.titel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (eintrag.datum != null) ...[
              const SizedBox(height: 2),
              Text(eintrag.datum!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            for (final abschnitt in eintrag.abschnitte) ...[
              _Abschnitt(abschnitt: abschnitt),
              if (abschnitt != eintrag.abschnitte.last)
                const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _Abschnitt extends StatelessWidget {
  const _Abschnitt({required this.abschnitt});

  final _ChangelogAbschnitt abschnitt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(abschnitt.icon, size: 18),
            const SizedBox(width: 6),
            Text(
              abschnitt.titel,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final text in abschnitt.eintraege)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Icon(Icons.circle, size: 5),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(text)),
              ],
            ),
          ),
      ],
    );
  }
}

List<_Versionseintrag> _parse(String markdown) {
  final versionen = <_Versionseintrag>[];
  _Versionseintrag? version;
  _ChangelogAbschnitt? abschnitt;

  for (final roheZeile in markdown.split('\n')) {
    final zeile = roheZeile.trim();
    if (zeile.startsWith('## ')) {
      if (version != null) {
        versionen.add(version);
      }
      final kopf = zeile.substring(3).trim();
      final istUnveroeffentlicht = kopf == '[Unreleased]';
      final match = RegExp(r'^\[([^\]]+)\](?:\s+-\s+(.+))?$').firstMatch(kopf);
      version = _Versionseintrag(
        titel: istUnveroeffentlicht
            ? 'In Entwicklung'
            : 'Version ${match?.group(1) ?? _bereinige(kopf)}',
        datum: match?.group(2),
        istUnveroeffentlicht: istUnveroeffentlicht,
        abschnitte: [],
      );
      abschnitt = null;
      continue;
    }

    if (zeile.startsWith('### ') && version != null) {
      final schluessel = zeile.substring(4).trim();
      abschnitt = _ChangelogAbschnitt(
        titel: switch (schluessel) {
          'Added' => 'Neu',
          'Changed' => 'Geändert',
          'Fixed' => 'Behoben',
          'Removed' => 'Entfernt',
          'Deprecated' => 'Veraltet',
          'Security' => 'Sicherheit',
          _ => schluessel,
        },
        icon: switch (schluessel) {
          'Added' => Icons.add_circle_outline,
          'Changed' => Icons.tune,
          'Fixed' => Icons.build_circle_outlined,
          'Removed' => Icons.remove_circle_outline,
          'Security' => Icons.security_outlined,
          _ => Icons.notes_outlined,
        },
        eintraege: [],
      );
      version.abschnitte.add(abschnitt);
      continue;
    }

    if (zeile.startsWith('- ') && abschnitt != null) {
      abschnitt.eintraege.add(_bereinige(zeile.substring(2)));
    }
  }

  if (version != null) {
    versionen.add(version);
  }
  versionen.removeWhere(
    (eintrag) => eintrag.abschnitte.every((abschnitt) => abschnitt.eintraege.isEmpty),
  );
  return versionen;
}

String _bereinige(String text) => text
    .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
    .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
    .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1');

class _Versionseintrag {
  _Versionseintrag({
    required this.titel,
    required this.datum,
    required this.istUnveroeffentlicht,
    required this.abschnitte,
  });

  final String titel;
  final String? datum;
  final bool istUnveroeffentlicht;
  final List<_ChangelogAbschnitt> abschnitte;
}

class _ChangelogAbschnitt {
  _ChangelogAbschnitt({
    required this.titel,
    required this.icon,
    required this.eintraege,
  });

  final String titel;
  final IconData icon;
  final List<String> eintraege;
}
