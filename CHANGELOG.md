# Changelog

Alle wesentlichen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.1.0/), und das Projekt verwendet [Semantic Versioning](https://semver.org/lang/de/).

## [Unreleased]

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

[Unreleased]: https://github.com/Huluvu424242/taugts/compare/v0.1.0+4...HEAD
[0.1.0+4]: https://github.com/Huluvu424242/taugts/compare/v0.1.0+3...v0.1.0+4
[0.1.0+3]: https://github.com/Huluvu424242/taugts/compare/v0.1.0+2...v0.1.0+3
[0.1.0+2]: https://github.com/Huluvu424242/taugts/compare/v0.1.0+1...v0.1.0+2
[0.1.0+1]: https://github.com/Huluvu424242/taugts/releases/tag/v0.1.0+1
