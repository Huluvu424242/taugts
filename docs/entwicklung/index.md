# Entwicklerdokumentation

Dieser Bereich bündelt technische Informationen für Entwicklung und Wartung von Taugt’s?.

## Einstieg

- [Dokumentationswerkzeugkette](dokumentationswerkzeugkette.md)
- [Versioniertes JSON-Austauschformat](austauschformat.md)
- [Sichere Importvalidierung](importvalidierung.md)
- [Android-Release](../android-release.md)
- [OpenStreetMap](../openstreetmap.md)
- [Fachliche Anforderungen](../fachliche_anforderungen.md)
- [Architekturdokumentation](../architecture/README.md)

Die verbindlichen Arbeitsregeln für Änderungen am Repository stehen in der [`AGENTS.md`](https://github.com/Huluvu424242/taugts/blob/master/AGENTS.md).

## Dokumentation pflegen

Alle fachlich gepflegten Dokumentationsinhalte bleiben Markdown-Dateien unter `docs/`. Die GitHub-Pages-Website ist ein daraus erzeugtes Artefakt und wird nicht separat bearbeitet.

Für einen lokalen Dokumentationsbuild:

```bash
python -m pip install -r requirements-docs.txt
mkdocs build --strict
```

Für eine lokale Vorschau kann anschließend `mkdocs serve` verwendet werden.
