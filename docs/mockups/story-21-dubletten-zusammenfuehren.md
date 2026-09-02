# Story #21 – Fachliche Dubletten kontrolliert zusammenführen

```text
┌─────────────────────────────────────────────┐
│ Mögliche fachliche Dublette                 │
│ objekte · Import import-p · lokal lokal-p   │
│                                             │
│ Unterschiede                                │
│ name: lokal „Pils“ · Import „Pilsener“      │
│ barcode: lokal „4001“ · Import „4001“       │
│                                             │
│ Entscheidung: [Zusammenführen          ▾]  │
│                                             │
│ Stammdaten für das kanonische Objekt        │
│ name:    [Lokal: Pils                  ▾]   │
│ barcode: [Lokal: 4001                  ▾]   │
│                                             │
│ Merge geplant: import-p bleibt Alias für    │
│ lokal-p.                                    │
└─────────────────────────────────────────────┘
```

## Zustände

- **Nicht ausgewählt:** Die vorhandene Konfliktkarte zeigt weiterhin nur Unterschiede und Konfliktentscheidung.
- **Zusammenführen:** Für widersprüchliche Stammdaten erscheint je Feld eine Auswahl zwischen lokalem und importiertem Wert. Die lokale UUID bleibt fest kanonisch.
- **Alias:** Sobald der Merge planbar ist, wird sichtbar bestätigt, welche Import-ID als Alias welcher lokalen ID zugeordnet wird.
- **Historie:** Historische Werte werden nicht als auswählbare Stammdaten behandelt. Referenzen werden nur im Merge-Plan umgeschrieben; Zeitpunkte, Preise, Bewertungen und Kriterien bleiben unverändert.
- **Nicht unterstützte Dublette:** „Zusammenführen“ wird nur für Produkte und Orte angeboten. Andere Konfliktentscheidungen bleiben verfügbar.
- **Zurück:** Der Nutzer kann jederzeit zur Importvorschau zurückkehren; lokale Daten werden nicht verändert.
