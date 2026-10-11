# Story-Loop-Skill für KI Agenten

Versionierte Quelle für einen wiederverwendbaren, wiederaufnehmbaren GitHub-Story-Arbeitslauf.

## Installation

Dieses Verzeichnis enthält `SKILL.md` sowie vier Markdown-Referenzen. Für die Bereitstellung in ChatGPT eine freigegebene GitHub-Releaseversion dieses Verzeichnisses als Skill-Paket exportieren und in der ChatGPT-Skillverwaltung installieren. **Die Repository-Aktualisierung aktualisiert installierte Skills nicht automatisch.** Installierte Version bewusst auswählen und prüfen. Der konkrete Importweg ist abhängig von den Funktionen der verfügbaren ChatGPT-Skilloberfläche.

## Startauftrag

Siehe [Work-Auftrag](../../work-auftraege/story-loop-taugts.md) für das erste Testprojekt.

## Releaseverfahren

Skilländerungen auf Arbeitsbranch mit PR prüfen und mergen. Versionierte Git-Tags nach Freigabe erstellen, z. B. `story-loop/v1.0.0`; daraus ein unverändertes Paket mit `SKILL.md` und `references/` bereitstellen. Kein automatischer Release und keine automatische Installation.

## Grundregeln

- GitHub ist die maßgebliche Quelle für Fortschritt.
- Projektharness wird im Work-Auftrag ausdrücklich benannt und hat bei Arbeitsregeln Vorrang.
- PRs werden erstellt, niemals im Skill automatisch gemergt.
- Keine Umgehung verweigerter Berechtigungen.
- Ein Work-Lauf hat reale technische Grenzen; ein Neustart rekonstruiert den GitHub-Zustand.
