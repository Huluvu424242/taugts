# Barrierefreiheit und Bug-Meldung

Letzter inhaltlicher Barrierefreiheits-Prüfstand: 2. September 2026. Dokumentationsabgleich mit dem Entwicklungsstand `master`: 10. Oktober 2026. Der letzte offizielle Release ist vor Freigabe auf GitHub Releases zu prüfen; 0.1.0+10 ist vorbereitet, aber noch nicht veröffentlicht. Die folgenden Aussagen sind **keine** Bestätigung einer abgeschlossenen manuellen Barrierefreiheitsprüfung.

Taugt’s? stellt die gemeinsamen Grundgerüst-Funktionen für Barrierefreiheit und
Bug-Meldungen vollständig innerhalb der App bereit.

## Erreichbarkeit

Das gemeinsame App-Menü ist am App-Start und auf allen vollständigen fachlichen
Screens verfügbar. Es bietet **Bug melden** und **Über**. Der Über-Dialog zeigt
die tatsächlich installierte Releaseversion einschließlich Buildnummer und
führt zur offline enthaltenen Barrierefreiheitserklärung sowie zu Projektseite
und veröffentlichter Dokumentation.

## Barrierefreiheitserklärung

Die Erklärung dokumentiert ihren Stand, den aktuellen Umsetzungsstatus,
bekannte Barrieren und den Meldeweg. Bei relevanten UX- oder
Barrierefreiheitsänderungen werden diese Angaben im selben Pull Request geprüft.

Der Getränkebewertungsbogen bietet geordnete, beschriftete Auswahllisten,
erklärte Intensitätsskalen, einen fokussierbaren Fehlersammler und eine bei
großer Schrift erreichbare Speicheraktion. Kriterien dürfen einzeln
ausgelassen werden; das Gesamturteil bleibt unabhängig.

Die Erlebniserfassung benennt den Typ sichtbar und semantisch. Der aktuelle Entwicklungsstand verwendet einen einzigen bearbeitbaren Beginn und ein Ende statt getrennter Plan-/Ist-Felder und eines gespeicherten Status. Ungültige Zeitangaben werden zusätzlich in einem fokussierbaren Fehlersammler gesammelt. Restaurantbesuch
und Einkauf sind ohne Farbcodierung unterscheidbar.

Die Erlebnisübersicht zeigt die vorhandenen Erlebnisse mit Typ, gemeinsamem Zeitraum, optionalem Ort und Positionsanzahl als Text. Ein fehlender Beginn oder ein fehlendes Ende bleibt erkennbar; eine gesonderte Einteilung in die früheren gespeicherten Status `geplant`, `aktiv` und `beendet` gibt es auf `master` nicht mehr. Lade-, Leer- und
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

Das optionale Reverse Geocoding wird ausschließlich über die sichtbare Aktion
**Adresse aus Koordinaten vorschlagen** gestartet. Vorschlags-, Lade- und
Fehlerzustände ersetzen die manuelle Eingabe nicht; Name und Adresse bleiben vor
dem Speichern bearbeitbar. Für private Orte steht die Übertragung exakter
Koordinaten an den Geocoding-Dienst nicht zur Verfügung.

Der Bereich **Import/Export** verwendet beschriftete Aktionen und verständliche
Status-, Vorschau-, Konflikt-, Erfolgs- und Fehlertexte. Die gewählte
Importstrategie, Auswirkungen sowie Konfliktentscheidungen werden nicht allein
durch Farbe oder Position vermittelt. Während der verbindlichen
Importausführung werden konkurrierende Import- und Exportaktionen gesperrt; ein
Fehler weist ausdrücklich auf den Rollback hin.

Die mobile Startseite verwendet semantisch beschriftete zentrale Aktionen und
eine responsive App Bar. Die sichtbare KI-Kennzeichnung ist vom App-Logo
getrennt; App-Bar-Aktionen bleiben auch auf kleinen Bildschirmbreiten innerhalb
des verfügbaren Bereichs.

Vor einem öffentlichen Release bleiben folgende manuelle Prüfungen offen:

- vollständiger Kernablauf mit TalkBack auf Android,
- große Systemschrift und erhöhte Display-Skalierung,
- kleine Android-Bildschirmgröße einschließlich App Bar,
- Gestennavigation und Erreichbarkeit unterer Aktionen,
- zusammenhängender Ablauf aus Produkt, Ort, Erlebnisentwurf und Bewertung,
- Erlebnisübersicht mit Einträgen mit und ohne Beginn beziehungsweise Ende,
  langen Ortsnamen und großer Schrift,
- Restaurantbestellung und Einkaufsliste mit Mengen-, Preis- und
  Bewertungsaktionen bei großer Schrift,
- erneute Bewertung eines bekannten Produkts aus den vorgesehenen Einstiegen,
- Kriterienverwaltung sowie Gaststätten- und Geschäftsbewertung einschließlich
  Ein- und Ausklappen, großer Schrift und Persistenzfehler,
- Produkt- und Ortsverläufe mit mehreren langen historischen Einträgen,
  unterschiedlichen Erlebnisarten und getrennten Bewertungs-/Preiszeitpunkten,
- Reverse Geocoding mit Erfolg, Fehler und privatem Ort einschließlich großer
  Schrift und Screenreader,
- Import/Export mit langer Vorschau, Konfliktentscheidungen, Dubletten-Merge,
  Ausführung, Erfolg und Rollback einschließlich großer Schrift und TalkBack,
- externe Projekt- und Dokumentationslinks einschließlich Öffnungsfehler,
- Bug-Meldung und vollständige Barrierefreiheitserklärung auf einem realen
  Gerät.

Der Getränkebewertungsbogen ist ausdrücklich einzubeziehen. Die gebündelte
Prüfung wird in
[Story #30](https://github.com/Huluvu424242/taugts/issues/30) verfolgt. Solange
diese Punkte offen sind, wird weder für den bisherigen offiziellen Stand noch für den für 0.1.0+10 vorbereiteten Stand ein vollständig manuell bestätigter Barrierefreiheitsstatus behauptet. Historische Releaseprüfungen stehen in den zugehörigen [Release-Checklisten](release-checklist-0.1.0+8.md).

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
