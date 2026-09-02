# Importvorschau und Konfliktanalyse

Vor einem späteren schreibenden Import wird eine ausgewählte JSON-Datei zuerst durch die Importvalidierung aus Story #17 geprüft. Nur ein gültiges, gegebenenfalls im Speicher migriertes Dokument gelangt in die Konfliktanalyse.

Die Analyse ist UI- und persistenzunabhängig. Sie vergleicht die stabilen UUIDs der Importdaten mit einem aktuellen lokalen Exportabbild. Für Objekte, Orte, Bewertungen, Bewertungskriterien und Kategorien werden neue, unveränderte und geänderte Datensätze gezählt. Gleiche UUID und gleicher Inhalt bedeutet unverändert; gleiche UUID mit abweichendem Inhalt bedeutet geändert; eine unbekannte UUID bedeutet neu. Eine zusätzliche Bewertung mit eigener UUID bleibt deshalb ein neuer historischer Datensatz und wird nicht allein wegen desselben bewerteten Objekts als Duplikat behandelt.

Mögliche fachliche Dubletten werden zusätzlich und unverbindlich erkannt. Produkte werden über Barcode beziehungsweise ersatzweise normalisierten Namen und Produkttyp verglichen, Orte über normalisierten Namen, Typ und Adresse, Kriterien über Namen und Bewertungsbereich und Kategorien über den Namen. Die Vorschau nennt die Begründung sowie beide UUIDs, entscheidet aber nicht automatisch über eine Zusammenführung.

Die Herkunft wird anhand der Herkunftsprofil-ID der Erlebnisse als eigenes oder fremdes Profil zusammengefasst. Die Vorschau ist rein lesend: Weder Validierung noch Konfliktanalyse schreiben in die lokale Datenbank. Eine tatsächliche Importbestätigung und atomare Persistenz sind Gegenstand nachfolgender Stories.
