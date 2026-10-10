# Entwicklerdokumentation

Dieser Bereich bündelt technische Informationen für Entwicklung und Wartung von Taugt’s?.

## Einstieg

- [Dokumentationswerkzeugkette](dokumentationswerkzeugkette.md)
- [Versioniertes JSON-Austauschformat](austauschformat.md)
- [Sichere Importvalidierung](importvalidierung.md)
- [Android-Release](../android-release.md)
- [Android-Test-APK vom aktuellen master](android-test-apk.md)
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


## Erlebnis-Gesamtstand und SQLite-Transaktionen (Story #221)

Die Bildschirm-Erfassung nutzt `ErlebnisEntwurfRepository` als lokale, nur für das aktuell geöffnete Erlebnis gültige Entwurfsschicht. Produktpositionen, Mengen, Preise und zugehörige Bewertungen werden darin im Arbeitsspeicher überschrieben beziehungsweise als zu löschen vorgemerkt. Unterformulare übernehmen Eingaben in diesen Entwurf; das Anlegen und Bearbeiten eigenständiger Produkt-Stammdaten läuft bewusst weiterhin über die reguläre Repository-Schnittstelle.

Erst die zentrale Aktion **Speichern** ruft `uebernehmen(erlebnis)` auf. Das produktive `SqliteBewertungsRepository` implementiert `ErlebnisGesamtstandRepository` und schreibt das Erlebnis, geänderte Positionen, Preise, entfernte Positionen, Produktbewertungen und eine optionale Ortsbewertung innerhalb genau **einer** `LokaleDatenbank.transaktion`. Löst ein Teilbereich eine SQL- oder Validierungsausnahme aus, rollt SQLite den gesamten Schreibvorgang zurück. Der Entwurf wird ausschließlich nach erfolgreichem Commit geleert und bleibt bei einem Fehler für die Korrektur verfügbar. Historische Zuordnungen nicht mehr aktiver Stammdaten werden nicht implizit bereinigt.

**Abgrenzung:** Die In-Memory-Eingaben eines geöffneten Erlebnisformulars sind kein dauerhaft gespeicherter Offline-Entwurf. Nach dem Verlassen ohne das gemeinsame Speichern sind diese Änderungen nicht verfügbar. Stammdatenpflege ist bewusst nicht Teil der Erlebnistransaktion und kann unabhängig gespeichert werden. Das Verhalten wird durch Widget-, Entwurfs-, Persistenz- und Rollbacktests überprüft.
