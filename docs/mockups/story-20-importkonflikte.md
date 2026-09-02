# Story #20 – Importkonflikte einzeln entscheiden

## Importvorschau

```text
┌────────────────────────────────────────────┐
│ Importvorschau                             │
│ Strategie: [Import bevorzugen         ▾]  │
│                                            │
│ objekte   2 hinzufügen · 1 aktualisieren  │
│ ...                                        │
│                                            │
│ 3 Konflikte benötigen eine Einzelentscheidung│
│ [Konflikte einzeln entscheiden]            │
└────────────────────────────────────────────┘
```

## Konfliktentscheidung

```text
┌────────────────────────────────────────────┐
│ Importkonflikte entscheiden                │
│ Noch keine Daten werden verändert.         │
│ [← Zurück zur Importvorschau]              │
│                                            │
│ Identitätskonflikt                         │
│ bewertungen · Import b1 · lokal b1         │
│ Objekt: p1 · Erlebnis: e1 · Ort: o1        │
│ Zeitpunkt: 2026-09-02T18:00:00Z            │
│                                            │
│ Unterschiede                               │
│ ortId: lokal „o2“ · Import „o1“            │
│ wert: lokal „3“ · Import „4“               │
│                                            │
│ Entscheidung: [Bitte auswählen        ▾]  │
│ ☐ Auf weitere Konflikte dieses Typs anwenden│
└────────────────────────────────────────────┘
```

Bei Identitätswidersprüchen wird **„Beide behalten“ nicht angeboten**. Bei fachlichen Dubletten mit unterschiedlichen stabilen IDs stehen zusätzlich **„Beide behalten“** und **„Zusammenführen“** zur Auswahl. „Zusammenführen“ ist hier nur eine vorgemerkte Entscheidung; die eigentliche Merge-Logik folgt in Story #21 und die atomare Ausführung in Story #22.

## Zustände

- **Leer:** Sind keine Konflikte vorhanden, erscheint keine Konfliktaktion.
- **Unentschieden:** Auswahlfeld zeigt „Bitte auswählen“ und der Fortschritt nennt die noch nicht entschiedenen Konflikte.
- **Entschieden:** Die Auswahl bleibt sichtbar; Entscheidungen können vor der späteren Importausführung geändert werden.
- **Wiederverwendung:** Eine Entscheidung kann auf weitere Konflikte derselben Sammlung und Konfliktart angewendet werden.
- **Zurück:** Der Nutzer kann jederzeit zur Strategie- und Importvorschau zurückkehren.
- **Fehler:** Die bestehende Importvalidierung bleibt vorgeschaltet; fehlerhafte Dateien erreichen die Konfliktansicht nicht.
