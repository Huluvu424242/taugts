# Barrierefreiheit und Bug-Meldung

Stand: 1. September 2026 · vorbereitete Version: 0.1.0+3

Taugt’s? stellt die gemeinsamen Grundgerüst-Funktionen für Barrierefreiheit und
Bug-Meldungen vollständig innerhalb der App bereit.

## Erreichbarkeit

Das gemeinsame App-Menü ist am App-Start und auf allen vollständigen fachlichen
Screens verfügbar. Es bietet **Bug melden** und **Über**. Der Über-Dialog zeigt
die tatsächlich installierte Releaseversion einschließlich Buildnummer und
führt zur offline enthaltenen Barrierefreiheitserklärung.

## Barrierefreiheitserklärung

Die Erklärung dokumentiert ihren Stand, den aktuellen Umsetzungsstatus,
bekannte Barrieren und den Meldeweg. Bei relevanten UX- oder
Barrierefreiheitsänderungen werden diese Angaben im selben Pull Request geprüft.

Der Getränkebewertungsbogen bietet geordnete, beschriftete Auswahllisten,
erklärte Intensitätsskalen, einen fokussierbaren Fehlersammler und eine bei
großer Schrift erreichbare Speicheraktion. Kriterien dürfen einzeln
ausgelassen werden; das Gesamturteil bleibt unabhängig.

Die Erlebniserfassung benennt Typ und Status sichtbar und semantisch, verwendet
beschriftete Planungs-, Beginn- und Endeaktionen und sammelt ungültige
Zeitangaben zusätzlich in einem fokussierbaren Fehlersammler. Restaurantbesuch
und Einkauf sind ohne Farbcodierung unterscheidbar.

Die Erlebnisübersicht gruppiert aktive, geplante und vergangene Erlebnisse mit
semantisch erkennbaren Überschriften. Erlebnistyp, Zeitangabe, optionaler Ort
und Positionsanzahl werden als Text ausgegeben; ein fehlender Planungstermin
wird ausdrücklich als „Termin noch offen“ dargestellt. Lade-, Leer- und
Fehlerzustände bleiben wahrnehmbar und bieten eine beschriftete Folgeaktion.

Die Verwaltung der Bewertungskriterien bietet semantisch beschriftete Aktionen,
einen fokussierbaren Fehlersammler, wahrnehmbare Lade-, Leer-, Fehler- und
Erfolgszustände sowie eine platzsparende Aktionsauswahl, die auch bei großer
Systemschrift bedienbar bleibt. Verwendete Kriterien werden beim Entfernen nur
deaktiviert, damit historische Bewertungen lesbar bleiben.

Die getrennte Ortsbewertung verwendet sichtbare Beschriftungen, semantische
Überschriften und Tastaturfokus. Im Restaurant wird sie als „Gaststätte
bewerten“, im Einkauf als „Geschäft bewerten“ bezeichnet und lädt jeweils die
passenden Kriterien. Der ausklappbare Bewertungsabschnitt benennt seinen Zustand
und bewahrt Eingaben beim Ein- und Ausklappen. Fehler werden zusätzlich in einem
fokussierbaren Fehlersammler ausgegeben.

Der chronologische Bewertungsverlauf trennt Stammdaten sichtbar von
historischen Beobachtungen, verwendet beschriftete ausklappbare Einträge und
kennzeichnet eigene sowie importierte Bewertungen nicht nur farblich. Im
aufgeklappten Eintrag werden der konkrete Erlebnisart-Kontext, Beginn und Ende,
Bewertungs- und Preisbeobachtungszeitpunkte sowie damalige Anzahl und Preis als
Text ausgegeben. Einzelwerte und Notizen bleiben getrennt lesbar. Lade-, Leer-
und Fehlerzustände sind auch offline verständlich erreichbar.

Der Barcode-Scan wird bewusst gestartet, zeigt den erkannten Code vor der
Übernahme und bietet bei abgelehnter oder ausgefallener Kamera weiterhin die
manuelle Eingabe. Scanner, Bestätigung und Produktvorschlag besitzen sichtbare
und semantische Beschriftungen.

Die Standortübernahme zeigt Koordinaten und verfügbare Genauigkeit vor der
Bestätigung. Ablehnung, ausgeschaltete Standortdienste und technische Fehler
werden als wahrnehmbare Meldung ausgegeben; die manuelle Ortserfassung bleibt
uneingeschränkt verfügbar.

Die optionale OpenStreetMap-Karte gibt die ausgewählten Koordinaten zusätzlich
als Text aus und bietet eine eindeutig beschriftete Übernahme. Die manuelle
Koordinaten- und Adresseingabe bleibt die vollständig zugängliche Alternative.

Vor einem öffentlichen Release bleiben folgende manuelle Prüfungen offen:

- vollständiger Kernablauf mit TalkBack auf Android,
- große Systemschrift und erhöhte Display-Skalierung,
- kleine Android-Bildschirmgröße,
- Gestennavigation und Erreichbarkeit unterer Aktionen,
- zusammenhängender Ablauf aus Produkt, Ort, Erlebnisentwurf und Bewertung,
- Erlebnisübersicht mit mehreren aktiven, geplanten und vergangenen Einträgen,
  fehlenden Terminen, langen Ortsnamen und großer Schrift,
- Kriterienverwaltung sowie Gaststätten- und Geschäftsbewertung einschließlich
  Ein- und Ausklappen, großer Schrift und Persistenzfehler,
- Produkt- und Ortsverläufe mit mehreren langen historischen Einträgen,
  unterschiedlichen Erlebnisarten und getrennten Bewertungs-/Preiszeitpunkten,
- Bug-Meldung und vollständige Barrierefreiheitserklärung auf einem realen
  Gerät.

Der Getränkebewertungsbogen ist ausdrücklich einzubeziehen. Die gebündelte
Prüfung wird in
[Story #30](https://github.com/Huluvu424242/taugts/issues/30) verfolgt. Solange
diese Punkte offen sind, wird für Version 0.1.0+3 kein vollständig manuell
bestätigter Barrierefreiheitsstatus behauptet. Der konkrete Freigabestand wird
zusätzlich in der
[Release-Checkliste](release-checklist-0.1.0+3.md) dokumentiert.

## Bug-Meldung

Die App erfasst ausschließlich:

- die bewusst ausgewählte Fehlerart,
- den fachlich eindeutigen Aufrufkontext,
- die installierte Release- und Buildversion,
- die freiwillig eingegebene Beschreibung.

Danach öffnet sie einen vorbereiteten GitHub-Bugreport im Browser. Der Nutzer
prüft und sendet ihn erst auf GitHub endgültig ab. Logs, Tokens, Passwörter,
lokale Nutzerdaten, Gerätekennungen und andere Diagnosedaten werden weder
automatisch gelesen noch übertragen.

Die Android-Integration für Versionsermittlung und Browseröffnung liegt hinter
injizierbaren Dart-Schnittstellen und kann in Tests durch Fakes ersetzt werden.

## Repository-Konfiguration

Die Issue-Vorlage liegt unter
`.github/ISSUE_TEMPLATE/app_bug_report.md`. Das Repository benötigt außerdem
ein Label mit dem exakten Namen `bug`. Falls es noch nicht vorhanden ist, wird
es unter **Issues → Labels → New label** mit der Beschreibung
`Fehler in der Anwendung` angelegt. Erst dann kann GitHub das vom App-Link
vorbelegte Label übernehmen.
