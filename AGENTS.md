# Arbeitsregeln für KI-Assistenten

Diese Regeln gelten verbindlich für alle Arbeiten am Projekt **Taugt’s?** und sind auf eine offline-first Flutter-App ohne notwendige Serveranbindung zugeschnitten.

## Verbindliche Regelstruktur

Diese `AGENTS.md` ist der verbindliche Einstiegspunkt. Die Arbeitsregeln sind auf mehrere Dateien verteilt. **Vor jeder Repository-Arbeit müssen diese `AGENTS.md` und alle nachfolgend aufgeführten Regeldateien vollständig gelesen werden.** Die verlinkten Dateien sind keine ergänzende oder optionale Dokumentation, sondern verbindlicher Bestandteil der AGENTS-Regeln:

1. [Workflow und Zusammenarbeit](agent-rules/01-workflow.md)
2. [Projektaufsetzung und Grundgerüst](agent-rules/02-project-bootstrap.md)
3. [Architektur und Implementierung](agent-rules/03-architecture.md)
4. [UX und Barrierefreiheit](agent-rules/04-ux-accessibility.md)
5. [Sicherheit und Werkzeugketten](agent-rules/05-security-tooling.md)
6. [Qualität und Dokumentation](agent-rules/06-quality-documentation.md)
7. [Releasevorbereitung](agent-rules/07-release.md)

Eine Repository-Arbeit darf nicht begonnen werden, bevor alle genannten Regeldateien gelesen wurden.

## Vor jeder Repository-Arbeit

1. Diese `AGENTS.md` und alle unter „Verbindliche Regelstruktur“ aufgeführten Dateien vollständig lesen.
2. Repository, aktuellen Branch, Arbeitsbaum und relevante Dokumentation prüfen.
3. Für GitHub-Inhalte und -Änderungen bevorzugt den verbundenen GitHub-Connector verwenden.
4. Fremde oder nicht zum Auftrag gehörende Änderungen erhalten.

## Neue Projekte und App-Grundgerüste

Beim Aufsetzen eines neuen Projekts oder eines neuen App-Grundgerüsts ist [Projektaufsetzung und Grundgerüst](agent-rules/02-project-bootstrap.md) vollständig und verbindlich anzuwenden. Diese Regeln gelten zusätzlich zu den übrigen Workflow-, Architektur-, Sicherheits-, Qualitäts- und UX-Regeln und dürfen nicht auf spätere Stories verschoben werden.

## Regelpriorität

Bei Widersprüchen zwischen den Regeldateien gilt:

1. Sicherheitsregeln haben Vorrang.
2. Spezifische Regeln haben Vorrang vor allgemeinen Regeln.
3. Kann ein Widerspruch dadurch nicht eindeutig aufgelöst werden, wird nicht geraten, sondern der menschliche Entwickler informiert.
