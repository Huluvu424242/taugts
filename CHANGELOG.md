# Changelog

Alle wesentlichen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.1.0/), und das Projekt verwendet [Semantic Versioning](https://semver.org/lang/de/).

## [Unreleased]

### Added

- Die Importvorschau bietet die Strategien „Bestand ersetzen“, „Import bevorzugen“ und „Lokalen Bestand bevorzugen“ und berechnet deren Auswirkungen ohne lokale Daten zu verändern.
- „Bestand ersetzen“ warnt vor Datenverlust und bietet unmittelbar einen Sicherungsexport an; historische Beobachtungen mit verschiedenen stabilen IDs bleiben bei ergänzenden Strategien eigenständige Datensätze, während widersprüchliche historische Kontexte derselben ID als Identitätskonflikt sichtbar werden.
- Importdateien werden vor jeder späteren Übernahme vollständig und ohne Datenbankänderung auf JSON-Syntax, Formatkennung, Schemaversion, Pflichtfelder, Datentypen, fachliche Regeln und referenzielle Konsistenz geprüft; Größen-, Tiefen- und Knotengrenzen schützen zusätzlich vor unangemessenen Eingaben.
- Eine getestete Vorwärtsmigration übernimmt die unterstützte Vorab-Schemaversion 0 in Version 1; unbekannte neuere Schemaversionen werden ausdrücklich abgewiesen.
- Ein versioniertes, datenbankunabhängiges JSON-Austauschformat `taugts-export` mit JSON Schema sowie gültigen und ungültigen Fixtures bildet Profile, Objekte, Orte, Erlebnisse, historische Preise und Bewertungen, Kriterien und Kategorien stabil über UUID-Beziehungen ab.

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
