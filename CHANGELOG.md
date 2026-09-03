# Changelog

Alle wesentlichen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.1.0/), und das Projekt verwendet [Semantic Versioning](https://semver.org/lang/de/).

## [Unreleased]

### Added

- In der Produkterfassung kann die EAN direkt am Feld **EAN / Barcode** über den vorhandenen lokalen Barcode-Scanner übernommen werden; Scan-Abbruch und bestehende Formulardaten bleiben dabei unverändert.
- Die Produktionsdatenbank stellt nun den vollständigen aktuellen Tabellenstand einschließlich Kategorien, Klassifikation, Kategorie-Kriteriensets und Import-Hilfstabellen deterministisch beim Öffnen bereit; die Architektur dokumentiert Schema, Migrationshistorie, Integritätsregeln, fachliche Abweichungen und ER-Diagramme ausführlich.
- Grundlegende lokale Auswertungen zeigen vergleichbare Kriterienwerte, Preis- und Bewertungsverläufe sowie Erlebnis- und ausdrücklich erfasste Andrangsdaten nachvollziehbar und ohne implizite Kausalaussagen.
- Die vollständig lokale Suche findet Produkte, Orte, Erlebnisse, Bewertungen und Preisbeobachtungen über kombinierbare strukturierte und freie Filter und führt historische Treffer in ihren Erlebniskontext.
- Kategorie-Kriteriensets können zentrale Kriterien geordnet erweitern oder ersetzen, aus Elternkategorien erben und zeigen Standard-, geerbte und explizite Quellen nachvollziehbar an.
- Strukturierte Kategorien, Herkunft, Hersteller und Eigenschaften bleiben fachlich von freien Tags getrennt; Tags werden lokal normalisiert gespeichert und können entfernt werden, ohne historische Bewertungen zu verändern.

### Changed

- Die Über-Seite zeigt direkt unter ihrer Überschrift die installierte Releaseversion, bietet danach einen Hilfe-Link zum Einstieg der Benutzerdokumentation und weist als letzte Inhaltszeile `🄯  created by Huluvu424242` aus.

### Fixed

- Die globale Suche durchsucht standardmäßig Produkte, Orte, Erlebnisse sowie Bewertungen und Preise gemeinsam; Suchbegriffe werden jetzt auch auf historische Datensätze angewendet.
- Das Importergebnis trennt Produktbewertungswerte, Ortsbewertungen und deren einzelne Kriterienwerte fachlich korrekt, statt Ortswerte als Produktbewertungen zu zählen.

## [0.1.0+5] - 2026-09-02

### Added

- Ortsformulare können nach ausdrücklicher Nutzeraktion aus vorhandenen Koordinaten über OpenStreetMap/Nominatim einen bearbeitbaren Vorschlag für Name und Adresse ermitteln; private Orte übertragen dabei keine exakten Koordinaten und fehlendes Netz oder Providerfehler blockieren die manuelle Erfassung nicht.
- Geprüfte Importe können nach Vorschau und Konfliktentscheidung ausdrücklich atomar ausgeführt werden; Erfolg und Rollback werden lokal datensparsam protokolliert, Wiederholungsimporte bewahren stabile Historien-IDs ohne technische Dubletten und das Ergebnis weist Erlebnisse, Positionen, Preisbeobachtungen sowie Produkt- und Ortsbewertungen getrennt aus.
- Fachliche Produkt- und Ortsdubletten können kontrolliert zusammengeführt werden: Die lokale UUID bleibt kanonisch, widersprüchliche Stammdaten werden feldweise ausgewählt, alle betroffenen Importreferenzen werden auf die kanonische ID umgebogen und die frühere Import-UUID wird persistent als Alias gespeichert und bei späteren Importen vor der Konfliktanalyse wiedererkannt, ohne historische Preise oder Bewertungen zu verändern.
- Importkonflikte können einzeln mit Gegenüberstellung der abweichenden Felder entschieden werden; Entscheidungen lassen sich auf weitere Konflikte derselben Art und Sammlung anwenden, während unzulässige Aktionen wie „Beide behalten“ bei Identitätswidersprüchen nicht angeboten werden.
- Die Importvorschau bietet die Strategien „Bestand ersetzen“, „Import bevorzugen“ und „Lokalen Bestand bevorzugen“ und berechnet deren Auswirkungen ohne lokale Daten zu verändern.
- „Bestand ersetzen“ warnt vor Datenverlust und bietet unmittelbar einen Sicherungsexport an; historische Beobachtungen mit verschiedenen stabilen IDs bleiben bei ergänzenden Strategien eigenständige Datensätze, während widersprüchliche historische Kontexte derselben ID als Identitätskonflikt sichtbar werden.
- Importdateien werden vor jeder späteren Übernahme vollständig und ohne Datenbankänderung auf JSON-Syntax, Formatkennung, Schemaversion, Pflichtfelder, Datentypen, fachliche Regeln und referenzielle Konsistenz geprüft; Größen-, Tiefen- und Knotengrenzen schützen zusätzlich vor unangemessenen Eingaben.
- Eine getestete Vorwärtsmigration übernimmt die unterstützte Vorab-Schemaversion 0 in Version 1; unbekannte neuere Schemaversionen werden ausdrücklich abgewiesen.
- Ein versioniertes, datenbankunabhängiges JSON-Austauschformat `taugts-export` mit JSON Schema sowie gültigen und ungültigen Fixtures bildet Profile, Objekte, Orte, Erlebnisse, historische Preise und Bewertungen, Kriterien und Kategorien stabil über UUID-Beziehungen ab.
- Der vollständige lokale Datenbestand kann als versionierte JSON-Datei exportiert, über den Systemdialog gespeichert und unter Android über den System-Teilen-Dialog weitergegeben werden.

### Fixed

- Die Importausführung verhindert nun auch auf Service-Ebene eine zweite gleichzeitige beziehungsweise reentrante Ausführung für dieselbe lokale Datenbank und gibt die Sperre nach Erfolg oder Fehler zuverlässig wieder frei.
- Importvorschau und Importausführung verwenden nun konsistent `erlebnisPositionen` und berücksichtigen Ortsbewertungen, sodass dieselben historischen Sammlungen geplant und tatsächlich verarbeitet werden.
- Persistente Aliasreferenzen aus dem Dubletten-Merge werden nun auch nach App-Neustart wiedererkannt und atomar mit dem Import gespeichert beziehungsweise bei Fehlern zurückgerollt.
- Reverse-Geocoding-Widgettests scrollen lazy aufgebaute Formularinhalte korrekt in den Widgetbaum; die betroffenen Dateien entsprechen wieder der erwarteten Dart-Formatierung.

## [0.1.0+4] - 2026-09-01

### Changed

- Das „Powered by KI“-Hinweislogo in der App Bar des Hauptmenüs wird nun mit 32 × 32 Pixeln statt 20 × 20 Pixeln dargestellt, ohne die Standardhöhe der App Bar zu verändern.

### Added

- Ein zusätzliches „Powered by KI“-Hinweislogo kennzeichnet die KI-unterstützte Entwicklung im Hauptmenü direkt hinter dem App-Namen sowie im Über-Dialog unmittelbar links neben „Schließen“, ohne das eigentliche App-Logo oder die bisherigen Höhen beziehungsweise Aktionsabstände zu verändern.
- Der Über-Dialog verlinkt die Projektseite und die veröffentlichte Projektdokumentation direkt über die vorhandene testbare Browser-Abstraktion und zeigt Öffnungsfehler im Dialog an.
- Bekannte Produkte können aus Produktliste, Produktdetails und Bewertungsverlauf erneut bewertet werden; dabei wird ein vorhandenes oder neues Erlebnis gewählt, das Produkt als bestehenden Stammdatensatz wiederverwendet und anschließend der bestehende Positions- und Bewertungsweg genutzt.
- Produkt- und Ortsverläufe nennen den konkreten Erlebniszusammenhang sowie Bewertungs- und Preisbeobachtungszeitpunkte, damalige Anzahl und damaligen Preis ausdrücklich.
- Geschäfte lassen sich innerhalb desselben Einkaufs in einem eigenen ausklappbaren Abschnitt mit Geschäftskriterien getrennt von Einkaufsliste und Produktbewertungen bewerten.
- Die Erlebnisübersicht gruppiert laufende, geplante und vergangene Restaurantbesuche und Einkäufe, zeigt Zeitkontext, Ort und Positionsanzahl und führt zum selben bearbeitbaren Erlebnis zurück.
- Die mobile Startseite bietet eine responsive, semantisch beschriftete Navigation zu Dinge, Orte, Bewertungen, Suche, Import/Export und Einstellungen sowie die zentralen Aktionen „Jetzt bewerten“, „Erlebnis registrieren“ und „Alle Erlebnisse“.
- Genau ein aktives Erlebnis kann direkt von der Startseite fortgesetzt werden; bei mehreren aktiven Erlebnissen wird keine Auswahl vorweggenommen.
- Noch nicht umgesetzte Zielbereiche führen zu verständlichen Informationsseiten statt zu funktionslosen Aktionen.
- Restaurantbesuche führen ihre Produkte als sichtbare Bestellung mit direkter Mengenänderung, Einzelpreis, kompakter Zusammenfassung und eindeutigem Bewertungsstatus.
- Produktbewertungen sind in der Bestellung über eine barrierefrei beschriftete kombinierte Downlike-/Uplike-Aktion erreichbar; der Zustand „Bewertet“ beziehungsweise „Noch nicht bewertet“ bleibt zusätzlich textlich sichtbar.
- Einkäufe verwenden denselben Erlebnis- und Positionsweg als „Einkaufsliste“ und können ohne Termin geplant, mit „Einkauf beginnen“ gestartet, mit „Einkauf beenden“ abgeschlossen und danach weiter bearbeitet werden.
- Die Einkaufssumme berücksichtigt ausschließlich Positionen mit erfasstem Preis und weist fehlende Preise ausdrücklich aus; Mengen und Produktbewertungen bleiben direkt in der Liste änderbar beziehungsweise erreichbar.

## [0.1.0+3] - 2026-08-31

### Added

- EAN-/GTIN-Barcodes können bewusst gestartet und vollständig lokal gescannt,
  bestätigt und vorhandenen oder neuen Produkten zugeordnet werden.
- Der aktuelle Standort kann auf ausdrückliche Nutzeraktion ermittelt, mit
  Genauigkeit geprüft und erst nach Bestätigung als bearbeitbare Koordinate
  übernommen werden; Hintergrund-Tracking findet nicht statt.
- Ortskoordinaten können auf einer optionalen OpenStreetMap-Karte angezeigt,
  durch Antippen korrigiert und erst nach Bestätigung übernommen werden.
- Bewertungskriterien lassen sich nach Produkt- und Ortsart konfigurieren,
  atomar sortieren, deaktivieren und sicher entfernen; sechs Eingabetypen sowie
  historisch erhaltene Kriterienversionen, Beschreibungen und Auswahlskalen
  bereiten Produkt-, Gastronomie- und Geschäftsbewertungen gemeinsam vor.
- Gaststätten lassen sich innerhalb desselben Restaurantbesuchs in einem
  separaten optionalen Formular bewerten; wiederholte Besuche erzeugen eigene
  historische Ortsbewertungen und verändern weder Bestellung noch
  Produktbewertungen.
- Produkt- und Ortsverläufe stellen Bewertungen, Einzelwerte, Preise, Mengen,
  Orte, Erlebniszeiten und Herkunft chronologisch dar, ohne historische
  Beobachtungen mit aktuellen Stammdaten zu vermischen.

## [0.1.0+2] - 2026-08-30

### Added

- Restaurantbesuche und Einkäufe lassen sich als geplante, aktive oder
  beendete Erlebnisse mit getrennten Planungs-, Beginn- und Endezeiten lokal
  erfassen, einchecken, auschecken und später bearbeiten.
- Produkte lassen sich einem Erlebnis als Position mit ganzzahliger Anzahl und
  optionalem, korrekturfähigem Preis in EUR, USD oder GBP zuordnen. Frühere
  Preise werden ausschließlich als Orientierung angezeigt.
- Der Bewertungsweg wählt Kriterien stabil nach Produktart: Getränke behalten
  ihr Set, Speisen erhalten eigene Kriterien und sonstige Produkte einen
  sicheren Fallback aus Gesamturteil und optionaler Notiz.

## [0.1.0+1] - 2026-08-30

### Added

- Manueller GitHub-Actions-Workflow für geprüfte, stabil signierte Android-APKs mit GitHub Release und SHA-256-Prüfsumme.
- Barrierefreier Getränkebewertungsbogen mit geordneten Qualitäts- und
  Intensitätskriterien, unabhängigem Gesamturteil, optionaler Notiz und
  historisch getrennten Bewertungen je Erlebnis.
- Offline-Barrierefreiheitserklärung, app-weites Support-Menü und kontextbezogene Bug-Meldung mit installierter Releaseversion.
- Durchsuchbare Produktliste, wiederverwendbarer zugänglicher Fehlersammler und
  sichtbare Verwendung des Taugt’s?-Logos in App und Android-Launcher.
- Verständliche Lade-, Fehler-, Wiederholungs- und Erfolgszustände für die
  bereits vorhandenen Profil-, Produkt-, Orts- und Entwurfsabläufe.
- Lokale Bewertungsentwürfe mit vorbelegtem Erlebniszeitpunkt, Produkt- und
  Ortsauswahl sowie Preis-, Mengen-, Gebinde- und Notizangaben; Entwürfe können
  gespeichert, fortgesetzt und nach Bestätigung verworfen werden.
- Vollständig lokale Ortsverwaltung mit Ortstyp, optionaler Adresse,
  Koordinaten, OSM-Referenz und Notiz sowie Suche, Auswahlmodus und
  nicht blockierender Dublettenwarnung.
- Offline-Produktverwaltung für Bier und andere Produkte mit optionalen
  Stammdaten, barrierefreier Validierung und Kennzeichnung unvollständiger
  Einträge.
- Lokales, stabiles Profil mit optionalem Anzeigenamen und Herkunftskennung für
  neue Erlebnisse und Bewertungen.
- Lokales Fach- und SQLite-Persistenzmodell für Produkte, Orte, Erlebnisse,
  Bewertungen und Bewertungskriterien einschließlich Schemaversion und Migration.
- Flutter-Projektgrundgerüst für Android mit vorbereiteter Windows- und Linux-Unterstützung.
- Featureorientierte Ausgangsstruktur, Startscreen und Widget-Test.

[Unreleased]: https://github.com/Huluvu424242/taugts/compare/v0.1.0+5...HEAD
[0.1.0+5]: https://github.com/Huluvu424242/taugts/compare/v0.1.0+4...v0.1.0+5
[0.1.0+4]: https://github.com/Huluvu424242/taugts/compare/v0.1.0+3...v0.1.0+4
[0.1.0+3]: https://github.com/Huluvu424242/taugts/compare/v0.1.0+2...v0.1.0+3
[0.1.0+2]: https://github.com/Huluvu424242/taugts/compare/v0.1.0+1...v0.1.0+2
[0.1.0+1]: https://github.com/Huluvu424242/taugts/releases/tag/v0.1.0+1