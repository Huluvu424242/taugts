# Arbeitsregeln für KI-Assistenten

Diese Regeln gelten verbindlich für alle Arbeiten am Projekt **Taugt’s?** und sind auf eine offline-first Flutter-App ohne notwendige Serveranbindung zugeschnitten.

## Kommunikation

- Die Kommunikation zwischen KI-Agenten und menschlichen Entwicklern erfolgt auf Deutsch. Technische Bezeichner, Code, Kommandos und unveränderte Fehlermeldungen dürfen englisch bleiben.
- Stories, Bugs, PR-Titel und PR-Beschreibungen werden auf Deutsch formuliert.
- Nach jeder Arbeit wird der menschliche Entwickler über Ergebnis, Prüfungen, offene Risiken und den nächsten sinnvollen Schritt informiert. Relevante GitHub-Artefakte werden direkt verlinkt.
- Technische Bezeichner folgen Dart- und Flutter-Konventionen. Englische Frameworkbegriffe und präzise deutschsprachige Fachbegriffe dürfen sinnvoll kombiniert werden; Begriffe werden nicht mechanisch übersetzt.

## Vor jeder Repository-Arbeit

1. Diese `AGENTS.md` vollständig lesen.
2. Repository, aktuellen Branch, Arbeitsbaum und relevante Dokumentation prüfen.
3. Für GitHub-Inhalte und -Änderungen bevorzugt den verbundenen GitHub-Connector verwenden.
4. Fremde oder nicht zum Auftrag gehörende Änderungen erhalten.

## Story-Workflow

Neue Funktionen und funktionale Änderungen werden grundsätzlich zuerst als Story mit dem Label `story` und prüfbaren Akzeptanzkriterien erfasst. Soll auf Wunsch ohne Story gearbeitet werden, ist vor der Implementierung wörtlich zu fragen: `Soll ich zunächst eine Story erstellen?`

Reihenfolge:

1. Bestand und fachlichen Kontext analysieren.
2. Anforderungen in eigenständig nutzbare Stories schneiden und Abhängigkeiten benennen.
3. Passende Milestones wiederverwenden oder bei erkennbarem Bedarf anlegen.
4. Ziel, Nutzen, Beschreibung, Akzeptanzkriterien, Abhängigkeiten und betroffene Bereiche dokumentieren.
5. Bei GUI-Änderungen ein einfaches Wireframe oder Mockup einschließlich wichtiger Leer-, Lade- und Fehlerzustände ergänzen.
6. Stories und empfohlene Reihenfolge verlinken.

## Fehlerbehebung

Ein gemeldeter Defekt wird nicht still repariert. Die Reihenfolge lautet:

**Analyse → Bug-Issue → eigener Branch → Implementierung → Prüfung → Pull Request → Rückmeldung**

Das Bug-Issue beschreibt Fehlerbild, Fehlermeldung, Analyse, vermutete Ursache, betroffene Komponenten und Lösungsansatz. Der PR verknüpft das Issue mit einem Closing-Keyword und nennt Ursache, Lösung, Prüfungen und Restunsicherheiten.

## Implementierung

- Für jede Story oder jeden Bug einen eigenen Branch verwenden und den Umfang eng halten.
- UI, Fachlogik, Persistenz, Import/Export und Plattformintegration klar trennen.
- Screens und Widgets enthalten keine Datenbank-, Dateiformat- oder Plattformdetails.
- Externe Abhängigkeiten werden hinter kleinen, testbaren Schnittstellen gekapselt.
- Lade-, Leer-, Erfolgs- und Fehlerzustände sichtbar behandeln, wenn sie für die Funktion relevant sind.
- Nutzereingaben bei Fehlern erhalten; Fehler nicht still ignorieren; keine leeren `catch`-Blöcke verwenden.
- Nach asynchronen Operationen den Widget-Lebenszyklus beachten und doppelte Seiteneffekte verhindern.

## Architekturleitplanken

### Geschützte Branches

- Der Branch `master` und alle Branches mit dem Präfix `release/` werden auf GitHub stets als geschützte Branches geführt.
- Änderungen an diesen Branches erfolgen ausschließlich über Pull Requests. Direkte Änderungen, Löschungen und Force Pushes sind untersagt.
- Für die Aufnahme einer Änderung ist keine zustimmende Review verpflichtend, da das Repository als Einzelentwickler-Projekt geführt wird und GitHub die Freigabe eigener Pull Requests nicht zulässt. Offene Review-Diskussionen müssen vor dem Merge weiterhin aufgelöst sein.
- Das aktive, über die GitHub-Oberfläche importierbare Repository-Ruleset liegt unter `gh-rulesets/protected-branches.json`.
- Ändern sich die Schutzanforderungen, werden `AGENTS.md`, die Ruleset-Datei und das auf GitHub aktive Ruleset gemeinsam aktualisiert.
- Neu angelegte Branches mit dem Präfix `release/` müssen ohne zusätzliche manuelle Konfiguration durch das Ruleset erfasst werden.

### Offline-first und Datenschutz

- Die Kernfunktion muss ohne Netzwerkverbindung nutzbar sein.
- Nutzerdaten werden ausschließlich lokal gespeichert, solange keine spätere Story ausdrücklich etwas anderes festlegt.
- Es gibt keine versteckte Synchronisation, Telemetrie oder Cloud-Übertragung.
- Datenaustausch erfolgt nur als explizite, vom Nutzer ausgelöste Import- oder Exportaktion.
- Vor Implementierung des Datenaustauschs werden Formatversionierung, Validierung, Konfliktbehandlung, atomare Schreibvorgänge und verständliche Fehlerfälle festgelegt.
- Exportierte Daten enthalten nur fachlich erforderliche Informationen. Potenziell sensible Inhalte werden nicht protokolliert.

### Featureorientierte Struktur

Die Anwendung wird zuerst nach fachlichen Features und erst darin nach technischen Rollen gegliedert:

```text
lib/
  app/
  core/
  features/
    bewertungen/
      models/
      services/
      presentation/
```

- Kleine Features bleiben flach; Unterordner und Abstraktionen entstehen nur bei konkretem Bedarf.
- Projektweit gemeinsame Infrastruktur darf unter `core/` liegen. Feature-lokale Logik bleibt beim Feature.
- Tests spiegeln die fachliche Struktur aus `lib/` soweit sinnvoll.
- Fachmodelle bleiben möglichst unabhängig von Flutter-Widgets, Persistenzpaketen und Import-/Exportformaten.
- Eine fachliche Funktion besitzt einen zentralen Implementierungsweg, den verschiedene Einstiegspunkte wiederverwenden.
- State Management, Navigation und Persistenzbibliothek werden nicht auf Vorrat festgelegt. Neue Packages benötigen einen belegbaren Nutzen sowie Prüfung von Wartungszustand, Plattformunterstützung und Lizenz.

### Plattformen

- Android ist die primäre Zielplattform und Referenz für Bedienung und Releasefähigkeit.
- Gestaltung und Interaktion erfolgen Mobile first für kleine Touch-Geräte.
- Fachlogik bleibt plattformneutral in Dart. Android-, Windows- und Linux-spezifischer Code wird an klaren Rändern isoliert.
- Windows und Linux werden bei Architektur- und Paketentscheidungen mitgeprüft, auch wenn eine Story zunächst nur Android umsetzt.
- Web und iOS gehören ohne eigene Story nicht zum Projektumfang.

### Clean Code und Testbarkeit

- Sprechende Namen, kleine Verantwortungsbereiche, geringe Kopplung und wenige versteckte Seiteneffekte verwenden.
- Keine Architektur auf Vorrat und keine Bibliothek für triviale Funktionalität einführen.
- Strukturierte Daten über klar benannte Modelle statt lose Maps durch mehrere Schichten reichen.
- `const` sinnvoll verwenden, Kontrollstrukturen klammern und Kommentare auf das Warum beschränken.
- Fachlogik unabhängig von Widgets und Plattformdetails testen; technische Abhängigkeiten durch Fakes ersetzen können.

### Flutter-spezifische Analysefehler vermeiden

- `Semantics` und andere Konstruktoren, die in der unterstützten Flutter-Version nicht `const` sind, dürfen nicht durch einen äußeren konstanten Konstruktor-Kontext implizit als konstant ausgewertet werden.
- Vor dem Hinzufügen oder Beibehalten von `const` an einem Widget mit `child` oder `children` ist der **gesamte darunterliegende Widgetbaum** zu prüfen. Enthält er direkt oder indirekt einen nicht konstanten Konstruktor, insbesondere `Semantics`, Builder, zustandsabhängige Widgets oder SDK-abhängig nicht konstante Widgets, darf der äußere Container nicht `const` sein.
- In zusammengesetzten Widgetbäumen gilt verbindlich: **konstante Blätter einzeln markieren, nicht den gemeinsamen Vorfahren pauschal konstant machen**. Beispielsweise bleibt `Center` ohne `const`, wenn sein Kind `Semantics` ist; nur ein darunterliegender nachweislich konstanter `CircularProgressIndicator` erhält `const`.
- Wird ein Widget in einen bereits konstanten Baum eingefügt oder ein vorhandenes Kind durch `Semantics` beziehungsweise ein anderes nicht konstantes Widget umschlossen, muss die Vorfahrenkette bis zum nächsten ohnehin nicht konstanten Widget geprüft und ein dort vorhandenes `const` entfernt werden. Nur das unmittelbar bearbeitete Widget zu prüfen ist unzureichend.
- Vor jedem Commit mit Flutter-UI-Änderungen ist repositoryweit nach vergleichbaren indirekten `const`-Kontexten in den geänderten Widgetbäumen zu suchen. Anschließend ist mindestens die betroffene Datei mit `flutter analyze` zu prüfen; vor Abschluss gelten zusätzlich die vollständigen Prüfanforderungen aus „Codestyle und Prüfungen“.
- Jeder einzelne `await` innerhalb eines `State`-Objekts bildet eine neue asynchrone Lücke. Nach jedem `await` muss vor der anschließenden Verwendung von `context`, `Navigator`, `ScaffoldMessenger`, Fokus, Scrollposition oder `setState` erneut `mounted` geprüft werden.
- Eine `mounted`-Prüfung vor einem weiteren `await` schützt nicht den Code nach diesem `await`.
- Wird nach einem `await` ein zuvor gespeicherter `BuildContext` verwendet, muss dessen eigener Lebenszyklus mit `context.mounted` geprüft werden.
- Redundante Konstruktionen wie `if (!mounted) return; if (mounted) ...` sind zu vermeiden.

## App-Identität: Name und Logo vor Implementierungsbeginn

- Jede neu zu erstellende App erhält vor Beginn der App-Implementierung einen finalen Namen und ein auf diesem Namen sowie der fachlichen Aufgabe beruhendes finales Logo.
- Name und Logo sind fachliche Startvoraussetzungen und keine nachträgliche Verschönerung. Erst mit beiden lässt sich die Identität der App eindeutig festlegen; insbesondere hängen Repositoryname, Paket- und Anzeigenamen, visuelle Wiedererkennbarkeit und weitere Projektartefakte davon ab.
- Das erste lauffähige App-Grundgerüst muss sich bereits durch seinen finalen Namen und sein Logo eindeutig von anderen Apps unterscheiden. Generische Frameworknamen, Standard-Launcher-Icons oder Platzhalterlogos sind nicht als fertiges Grundgerüst zulässig.
- Das Logo wird von Anfang an mindestens als App- beziehungsweise Launcher-Icon der primären Zielplattform integriert. Erforderliche plattformspezifische Varianten und Größen werden aus einer geeigneten hochwertigen Quelldatei reproduzierbar abgeleitet.
- Logoentwurf, Auswahl und Integration werden in den initialen Stories und Akzeptanzkriterien berücksichtigt. Ohne finales Logo darf die fachliche Implementierung nicht beginnen.
- Herkunft, Urheberschaft, Nutzungsrechte, Lizenz und Verwendung des Logos werden spätestens mit seiner Integration in `ATTRIBUTIONS.md` dokumentiert.

## Verbindliche Grundgerüst-Funktionen

Ein App-Grundgerüst ist erst fertig, wenn neben Name und Logo auch eine Barrierefreiheitserklärung und eine Funktion zum Melden von Bugs implementiert, aus der laufenden App erreichbar und getestet sind. Beide Funktionen gehören in die Initial-Story des Grundgerüsts und dürfen weder als spätere Fachstory noch als nachgelagerte Querschnittsarbeit verschoben werden.

Die Implementierung ist vollständig innerhalb des jeweiligen App-Projekts zu dokumentieren und zu pflegen. App-Name, Repository, Issue-Vorlage, Labels, Versionsermittlung, Texte, bekannte Barrieren und fachliche Aufrufkontexte werden projektspezifisch festgelegt. Es darf keine Laufzeit-, Quellcode- oder Dokumentationsabhängigkeit zu einem anderen App-Projekt entstehen.

### Gemeinsamer Zugang und technische Struktur

- Jeder vollständige Screen bietet an einer konsistenten, semantisch beschrifteten Stelle ein gemeinsames App- beziehungsweise Support-Menü mit mindestens `Bug melden` und `Über`.
- Temporäre Dialoge und fachliche Unterabläufe, in denen Fehler eigenständig auftreten können, bieten ebenfalls einen direkt erreichbaren Meldeweg oder übergeben ihren eindeutigen Kontext an die gemeinsame Meldefunktion.
- Der Über-Dialog zeigt App-Name sowie die tatsächlich installierte Releaseversion einschließlich Buildnummer und verlinkt die Barrierefreiheitserklärung. Auch der Über-Dialog und die Barrierefreiheitserklärung bieten unmittelbar `Bug melden`.
- Die Support-Oberfläche, die Ermittlung der installierten App-Version und das Öffnen externer Ziele werden getrennt. Plattformzugriffe liegen hinter kleinen injizierbaren Schnittstellen, damit Widgettests Fakes verwenden und keine realen Browser, Paketinformationen oder Netzverbindungen benötigen.
- Alle asynchronen Übergänge beachten die Lebenszyklusregeln dieser Datei. Fehler beim Laden der Version oder Öffnen des Meldewegs werden verständlich und als Live-Region ausgegeben; der Dialog schließt sich bei einem Fehler nicht und bereits eingegebene Daten bleiben erhalten.

### Barrierefreiheitserklärung

- Die Erklärung ist offline Bestandteil der App, dauerhaft über den Über-Dialog erreichbar und selbst vollständig barrierefrei bedienbar.
- Sie enthält mindestens App-Name, Stand beziehungsweise Prüfdatum, den aktuellen Umsetzungsstand, bekannte Barrieren und Einschränkungen sowie einen konkreten Meldeweg für Barrieren.
- Aussagen werden ausschließlich für die jeweilige App getroffen und dürfen keinen ungeprüften vollständigen Barrierefreiheitsstatus behaupten. Noch ausstehende manuelle Prüfungen und nicht beeinflussbare externe Inhalte werden transparent benannt.
- Der Inhalt liegt in einer scrollbaren, umbruchfähigen Darstellung vor und bleibt bei großer Systemschrift, kleinen Bildschirmen, Screenreader-, Tastatur- und Schalterbedienung lesbar und erreichbar. Überschriften, Fokusreihenfolge, Schließen- und Meldeaktion besitzen verständliche sichtbare und semantische Bezeichnungen.
- Der Meldeweg aus der Erklärung setzt den Aufrufkontext ausdrücklich auf `Barrierefreiheitserklärung`, sodass der Ursprung der Meldung ohne Freitext erkennbar ist.
- Bei jeder relevanten UX- oder Barrierefreiheitsänderung werden Datum, Umsetzungsstand, bekannte Barrieren und Meldeweg der Erklärung im selben Pull Request geprüft und bei Bedarf aktualisiert.

### Bug-Meldung

- Die App öffnet vor dem Wechsel zu einem externen Meldesystem einen eigenen barrierefrei bedienbaren Dialog. Darin sind der eindeutige fachliche Aufrufkontext und die tatsächlich installierte Releaseversion einschließlich Buildnummer sichtbar.
- Die Fehlerart ist ein Pflichtfeld mit mindestens `Barrierefreiheitsfehler`, `Darstellungsfehler`, `Funktionsfehler` und `Sonstiges`. Eine optionale Beschreibung besitzt eine fachlich begründete Maximallänge und den deutlichen Hinweis, keine Zugangsdaten oder personenbezogenen Daten einzutragen.
- Fehlende Pflichtangaben werden am Feld und in einem fokussierbaren Fehlersammler angezeigt. Eine kurze wahrnehmbare Meldung sowie Fokus und Scrollposition führen zum Fehlersammler beziehungsweise zum ersten Fehler.
- Erst nach erfolgreicher lokaler Validierung wird ein vorausgefüllter Bugreport für das projektspezifische Repository geöffnet. Titel und Inhalt enthalten Fehlerart, Aufrufkontext und Releaseversion; die Beschreibung wird nur nach bewusster Eingabe übernommen. Repository, Bug-Label und Issue-Vorlage werden im jeweiligen Projekt konfiguriert und gemeinsam mit der Funktion gepflegt.
- Vor dem Öffnen wird erklärt, dass gegebenenfalls eine Anmeldung beim externen Meldesystem erforderlich ist, der Bericht dort geprüft und erst dort endgültig abgesendet wird. Die Aktion heißt entsprechend `Auf GitHub prüfen` oder bei einem anderen Ziel gleichwertig eindeutig; Abbrechen bleibt jederzeit möglich, solange kein Öffnungsvorgang läuft.
- Logs, Tokens, Passwörter, lokale Nutzerdaten, Gerätekennungen und sonstige Diagnosedaten werden niemals automatisch angehängt oder übertragen. Insbesondere darf die Meldefunktion keine in der App gespeicherten Zugangsdaten lesen.
- Kann die installierte Version nicht ermittelt oder das externe Ziel nicht geöffnet werden, erhält der Nutzer eine verständliche Fehlermeldung. Es darf weder eine unvollständige Meldung still geöffnet noch ein Erfolg vorgetäuscht werden.
- Das Repository enthält die referenzierte Issue-Vorlage und das vorgesehene Bug-Label beziehungsweise dokumentiert deren reproduzierbare Einrichtung. Die Vorlage fordert keine Informationen erneut an, die bereits sicher vorausgefüllt werden.

### Eindeutiger Aufrufkontext

- Jeder Einstieg in die Bug-Meldung übergibt einen stabilen, nutzerverständlichen fachlichen Kontext. Generische Werte wie `Dialog`, `Formular`, ein Klassenname oder derselbe Kontext für mehrere fachlich verschiedene Abläufe sind unzulässig.
- Der Kontext unterscheidet mindestens Screens, Dialoge und Erfassungsarten. Fachliche Varianten werden im Wert benannt, beispielsweise `Produkt erfassen`, `Produkt bearbeiten`, `Über-Dialog` oder `Barrierefreiheitserklärung`.
- Neue Screens, Dialoge und Erfassungsvarianten ergänzen ihren Kontext zusammen mit der jeweiligen Implementierung. Wird eine gemeinsame Komponente in mehreren Varianten genutzt, entsteht der Kontext aus dem fachlichen Modus und nicht allein aus dem Widgetnamen.
- Der Aufrufkontext wird im Dialog angezeigt und unverändert in Titel oder Inhalt des vorbereiteten Bugreports übernommen.

### Verbindliche Prüfungen der Grundgerüst-Funktionen

Mindestens durch Widget- und Unit-Tests nachzuweisen sind:

- Erreichbarkeit von `Bug melden`, `Über` und Barrierefreiheitserklärung über alle vorgesehenen Einstiege,
- Anzeige der installierten Release- und Buildversion sowie verständliche Behandlung eines Ladefehlers,
- Offline-Anzeige, Scrollbarkeit, Semantik und Meldeweg der Barrierefreiheitserklärung,
- unterschiedliche erwartete Aufrufkontexte für sämtliche Screens, Dialoge und fachlichen Varianten,
- Pflichtfeldvalidierung, Fehlersammler, Fokus- und Scrollverhalten sowie Erhalt der Eingaben,
- korrekt kodierter Ziel-Link mit projektspezifischem Repository, Issue-Vorlage, Bug-Label, Fehlerart, Kontext, Version und optionaler Beschreibung,
- Ausschluss von Tokens, Passwörtern, Logs und nicht ausdrücklich eingegebenen Diagnose- oder Nutzerdaten,
- verständlicher Fehlerzustand bei fehlgeschlagener Versionsermittlung oder beim Öffnen des externen Ziels.

Zusätzlich werden die Erklärung und der vollständige Meldeablauf vor dem ersten öffentlichen Release manuell mit großer Systemschrift, TalkBack sowie auf einem kleinen Android-Bildschirm geprüft. Offene manuelle Prüfungen werden wie in der Abschlussdefinition beschrieben ausgewiesen.

## UX und Barrierefreiheit

Barrierefreiheit ist Bestandteil jeder einzelnen GUI-Story und keine ausschließlich nachgelagerte Querschnittsaufgabe. Eine spätere Barrierefreiheitsstory dient der systematischen Gesamtprüfung und Vervollständigung, darf aber nicht als Begründung verwendet werden, um ohne Spezialwerkzeuge umsetzbare Grundlagen zu verschieben.

### In jeder GUI-Story sofort verpflichtend

Die folgenden Anforderungen müssen zusammen mit dem jeweiligen Screen geplant, implementiert und soweit automatisierbar getestet werden. Eine GUI-Story darf ohne sie nicht als fachlich fertig gemeldet oder geschlossen werden:

- Interaktive Elemente erhalten verständliche sichtbare Bezeichnungen oder eindeutige semantische Beschriftungen. Symbolschaltflächen erhalten insbesondere einen verständlichen Tooltip beziehungsweise ein Semantics-Label.
- Touch-Ziele werden ausreichend groß ausgelegt; primäre Aktionen bleiben mit Abstand zu Bildschirmrand, Systemgesten, Bildschirmtastatur und temporären Meldungen erreichbar.
- Layouts verwenden scroll- und umbruchfähige Strukturen. Große Systemschrift und kleine Android-Bildschirme dürfen keine Kerninhalte abschneiden, überlagern oder Aktionen unerreichbar machen.
- Information wird nie ausschließlich über Farbe, Position, Form oder ein unbeschriftetes Symbol vermittelt.
- Lade-, Leer-, Erfolgs- und Fehlerzustände werden verständlich und semantisch wahrnehmbar umgesetzt. Fortschrittsanzeigen erhalten einen zugänglichen Zweck; leere Zustände bieten eine sinnvolle nächste Aktion; behebbare Fehler bieten einen erneuten Versuch.
- Nutzereingaben und Entwürfe bleiben bei Validierungs-, Persistenz- und Navigationsfehlern erhalten.
- Validierungsfehler erscheinen am Feld und zusätzlich in einem fokussierbaren Fehlersammler am Inhaltsanfang. Dessen Einträge führen zum zugehörigen Feld.
- Nach fehlgeschlagener Validierung werden eine kurze wahrnehmbare Meldung sowie Fokus und Scrollposition zum Fehlersammler beziehungsweise ersten Fehler bewegt.
- Erfolgreiche, fehlgeschlagene und noch laufende Aktionen erhalten eine verständliche Rückmeldung; deaktivierte Aktionen bleiben in ihrem Zustand erklärbar.
- Fokusreihenfolge und Tastaturaktivierung werden bereits in der Widgetstruktur sinnvoll angelegt. Offensichtliche Fokusfallen und ausschließlich gestenbasierte Bedienwege sind unzulässig.
- Eingabefelder erhalten fachlich begründete Maximallängen. Zeichenzähler und barrierefreie Grenzrückmeldung werden in der jeweiligen Story konkretisiert.
- In scrollbaren oder lazy aufgebauten Formularen darf die vollständige fachliche Validierung nicht ausschließlich von `FormState.validate()` oder aktuell gemounteten `FormField`-Widgets abhängen. Außerhalb des Viewports liegende Felder können aus dem Widgetbaum entfernt sein. Die Speicherlogik prüft daher alle relevanten Controller- beziehungsweise Modellwerte unabhängig vom Sichtbereich; Feldvalidatoren dienen zusätzlich der lokalen Fehleranzeige. Widgettests lösen die Speicheraktion auch vom Formularende aus und weisen nach, dass Fehler in nicht sichtbaren Feldern erkannt werden.
- Widgettests für lazy aufgebaute Scrollbereiche unterscheiden verbindlich zwischen Sichtbarkeit und Existenz im Widgetbaum: `ensureVisible()` darf nur für bereits gemountete Widgets verwendet werden. Kann das Ziel außerhalb des Viewports noch nicht aufgebaut sein, muss der Test den zugehörigen `Scrollable` mit `scrollUntilVisible()`, kontrollierten Drag-Schritten oder einem gleichwertigen Verfahren scrollen, bis das Ziel erzeugt und sichtbar ist. Erst danach darf der Finder dereferenziert oder das Widget aktiviert werden.
- Wird ein Fehlersammler am Anfang eines lazy aufgebauten Formulars erst nach der Validierung eingefügt, darf die Navigation nicht allein von dessen `BuildContext` oder `GlobalKey.currentContext` abhängen: Das Ziel kann außerhalb des Viewports noch ungemountet sein. Das Formular steuert seinen Scrollbereich über einen `ScrollController` zunächst an den Anfang, wartet den Aufbau des folgenden Frames ab und setzt erst danach den Fokus auf den Fehlersammler.
- Für diese Grundlagen werden passende Widget- und Semantiktests ergänzt, soweit Flutter sie automatisiert prüfen kann.

Fehlendes Flutter-SDK, fehlender Emulator oder fehlendes Testgerät rechtfertigen nicht das Weglassen dieser Implementierungen. Nicht ausführbare Prüfungen werden benannt, die zugrunde liegenden Anforderungen aber trotzdem im Code umgesetzt.

### Gebündelt prüfbare Querschnittsanforderungen

Folgende Prüfungen dürfen in einer eigenen Barrierefreiheitsstory über alle bis dahin vorhandenen Screens gebündelt werden, weil sie reale Plattformen, Assistenztechnik oder eine konsistente Gesamtschau benötigen:

- manuelle Bedienung der vollständigen Kernabläufe mit TalkBack auf Android,
- manuelle Prüfung extremer Systemschriftgrößen und Display-Skalierungen auf repräsentativen Geräten,
- durchgängige Tastatur- und Fokusprüfung unter Windows und Linux,
- systematische Kontrastmessung aller verwendeten Farbkombinationen und Zustände,
- Prüfung der Screenreader-Reihenfolge, Live-Regionen und gesprochenen Rückmeldungen im realen Zusammenspiel,
- Prüfung auf konsistente Navigation und unerwartete Fokusverluste über Screen-Grenzen hinweg,
- dauerhaft erreichbare Barrierefreiheitserklärung und abschließende dokumentierte Prüfliste vor dem ersten öffentlichen Release.

Eine gebündelte Prüfung darf neue Befunde erzeugen und Nachbesserungen verlangen. Sie ersetzt weder die sofortigen Anforderungen noch deren Prüfung innerhalb der jeweiligen GUI-Story.

## Sicherheit

- Nie im Chat nach Anmeldedaten wie Nutzernamen, Passwörtern oder Tokens fragen.
- GitHub-Projekteinstellungen niemals eigenmächtig über den Cloud-Browser in Vertretung des menschlichen Entwicklers ändern.

### Strikter Erlaubnisvorbehalt für GitHub Actions und externe Werkzeugketten

Die folgenden Regeln sind eine verbindliche Sicherheitsgrenze. Sie dürfen weder aus Zweckmäßigkeit noch wegen Zeitdrucks, fehlender lokaler Werkzeuge, technischer Blockaden oder eines vermeintlich geringen Risikos umgangen, abgeschwächt oder durch eine eigene Auslegung ersetzt werden.

- Es gilt ausnahmslos **Default Deny**: KI-Assistenten dürfen GitHub Actions, CI/CD-Pipelines, Bots, Automationen, externe Runner oder vergleichbare Werkzeugketten weder erstellen, ändern, aktivieren, deaktivieren, auslösen, erneut ausführen, abbrechen, planen noch als Ersatz für lokal fehlende Werkzeuge verwenden, solange dafür keine vorherige, ausdrückliche und hinreichend konkrete Erlaubnis vorliegt.
- Als Ausführung gilt auch das **indirekte Auslösen** durch einen Commit, Push, Pull Request, Reopen, Labelwechsel, Kommentar oder eine sonstige Aktion. Vor einem solchen Repository-Schreibvorgang sind die vorhandenen Trigger zu prüfen. Würde dadurch ein nicht freigegebener Workflow starten, muss der KI-Assistent vor dem Schreibvorgang anhalten und die Erlaubnis einholen.
- Ein vorhandener Workflow, ein sichtbarer Ausführen-Button, technisch vorhandene Berechtigungen, zugängliche Secrets, eine allgemeine Beauftragung zur Umsetzung, Schweigen, eine frühere Freigabe für einen anderen Lauf oder die Freigabe eines ähnlichen Workflows sind **keine Erlaubnis**.
- Vor jeder erstmaligen oder nicht bereits exakt erfassten Verwendung muss der KI-Assistent wörtlich fragen: `Darf ich die folgende GitHub Action als Werkzeug verwenden beziehungsweise anpassen: <Workflow, Zweck, konkrete Ausführung und benötigte Berechtigungen>?` Erst ein danach erteiltes eindeutiges `Ja` erlaubt die konkret beschriebene Aktion. Frage und Ausführung dürfen nicht in einem Schritt zusammenfallen.
- Die Erlaubnis muss mindestens Repository, Workflow-Datei und -Name, Zweck, Trigger oder konkrete manuelle Ausführung, Branch beziehungsweise PR, benötigte Berechtigungen, Inputs, Outputs, Datenzugriffe, Secrets, Artefakte sowie einmalige oder dauerhafte Geltung festlegen. Nicht benannte Aspekte bleiben verboten.
- Eine einmalige Erlaubnis gilt nur für den beschriebenen Lauf. Eine dauerhafte selbständige Ausführung ist nur zulässig, wenn sie ausdrücklich als solche genehmigt und im Freigabeverzeichnis dieser Datei dokumentiert wurde.
- Jede Freigabe erlischt automatisch, sobald sich Workflow-Datei, verwendete Action oder Commit-SHA, Trigger, Berechtigungen, Inputs, Outputs, Secrets, Datenzugriff, Artefakte, Runner oder Zweck ändern. Vor einer weiteren Ausführung ist eine neue ausdrückliche Erlaubnis erforderlich.
- Reines Lesen von Workflow-Dateien, Statusinformationen und vorhandenen Logs ist zulässig, wenn dadurch sicher kein Lauf ausgelöst, kein Zustand verändert und kein Geheimnis offengelegt wird.
- Fehlt ein erlaubtes Werkzeug, bleibt die technische Prüfung offen. Der KI-Assistent dokumentiert präzise, welche Prüfung nicht möglich war, und meldet den Stand als `Implementiert, technische Prüfung ausstehend`. Er darf keine Ersatz-Pipeline, Hilfs-Action oder externe Werkzeugkette eigenmächtig aufbauen.
- Änderungen an Anwendungscode, Hilfsskripten, GitHub Actions, CI/CD-Konfiguration oder anderer ausführbarer Automatisierung werden niemals direkt in `master` oder `release/*` vorgenommen, sondern ausschließlich über Story, eigenen Branch und Pull Request integriert.
- Jede Erstellung oder Änderung einer GitHub Action, CI/CD-Konfiguration oder eines Codes beziehungsweise Skripts zur Erweiterung der Werkzeugkette benötigt **vor der Implementierung** eine eigene Story. Anschließend erfolgt die Änderung in einem dafür bestimmten, separaten Pull Request. Dieser Pull Request muss vor der ersten Verwendung menschlich geprüft und gemergt sein.
- Eine Werkzeugkettenänderung darf nicht in einem Fach- oder Bug-PR versteckt und nicht im selben PR bereits verwendet werden. Verbindliche Reihenfolge: **Story → separater Werkzeugketten-PR → menschliche Prüfung und Merge → ausdrückliche Ausführungsfreigabe → Verwendung**.
- Eine solche Story dokumentiert mindestens Zweck, Bedrohungs- und Risikoanalyse, Trigger, minimale Berechtigungen, verwendete Actions mit unveränderlichen Commit-SHAs, Inputs und Outputs, Secrets und Datenflüsse, Artefakte und Log-Aufbewahrung, Supply-Chain- und Lizenzprüfung, Laufzeit und Kosten, erlaubte Akteure und Nutzungen, Auditierbarkeit sowie Deaktivierung und Rollback.
- Workflows dürfen keine Codeänderungen oder Commits erzeugen, sofern dies nicht gesondert in Story, Pull Request und ausdrücklicher Freigabe genehmigt wurde. Eine Workflow-Ausführung ersetzt niemals den vorgeschriebenen Pull-Request-Prozess.

#### Freigabeverzeichnis für selbständige Ausführungen

Folgende Freigabe ist erteilt:

- **Repository:** `Huluvu424242/taugts`
- **Workflow:** `Flutter-Prüfungen`
- **Datei und freigegebene Version:** `.github/workflows/flutter-ci.yml`, Git-Blob-SHA `24a879f05efe8ef44a89701a1200aa949f4df564`
- **Geltung:** dauerhaft bis zum Widerruf oder bis zu einer Änderung der unten genannten Gültigkeitsmerkmale
- **Erlaubte selbständige Ausführung:** automatische Ausführung über die in dieser Version vorhandenen `pull_request`- und `push`-Trigger für `master` und `release/**` sowie bedarfsweises erneutes Ausführen eines zu dieser freigegebenen Version gehörenden Workflow-Laufs
- **Zweck:** Abhängigkeiten laden, Dart-Code formatieren, statische Flutter-Analyse ausführen, Flutter-Tests ausführen und unbeabsichtigte Formatierungsänderungen erkennen
- **Berechtigungen und Datenzugriff:** ausschließlich `contents: read`; Eingaben sind Repositoryinhalt und öffentlich beziehungsweise regulär auflösbare Projektabhängigkeiten; es sind keine Secrets und keine schreibenden Repositoryberechtigungen freigegeben
- **Ausgaben:** GitHub-Actions-Status und Laufprotokolle; keine Artefakte und keine durch den Workflow erzeugten Commits oder Codeänderungen
- **Freigabe erteilt:** 30. August 2026 durch den Projektverantwortlichen

Diese Freigabe gilt ausschließlich für die oben bezeichnete Version. Jede Änderung an `flutter-ci.yml`, an einer anderen Action- oder Workflow-Datei oder an den von diesem Workflow verwendeten Actions, Triggern, Berechtigungen, Inputs, Outputs, Secrets, Datenzugriffen, Artefakten, Runnern oder Zwecken erfolgt weiterhin ausschließlich über eine vorherige Story, einen eigenen Branch und einen Pull Request. Die geänderte oder neu hinzugefügte Action ist bis zu einer erneuten ausdrücklichen Freigabe nicht zur selbständigen Ausführung zugelassen. Andere Workflows oder externe Werkzeugketten sind nicht freigegeben.

- Eine temporäre Ausnahme für Änderungen an GitHub-Projekteinstellungen gilt ausschließlich, wenn der KI-Assistent zuvor wörtlich gefragt hat: `Darf ich die Settings auf github selbst anpassen?` Erst ein darauf folgendes eindeutiges `Ja` erteilt die Erlaubnis für die konkret beauftragte Änderung. Ohne diese Abfolge liegt keine Erlaubnis vor.
- Secrets, Tokens, Passwörter, Schlüssel und echte personenbezogene Testdaten niemals hardcodieren, einchecken, protokollieren oder in Screenshots und Fehlertexte übernehmen.
- `.env`, Keystores, Signierschlüssel und lokale Konfigurationen durch Ignore-Regeln schützen.
- Tests verwenden Fakes und eindeutig ungültige Beispielwerte.
- Abhängigkeiten und GitHub Actions auf Herkunft, Wartungszustand, Lizenz und minimale Berechtigungen prüfen.
- GitHub Actions erhalten explizite minimale `permissions`; externe Actions möglichst auf unveränderliche Commit-SHAs festlegen.
- Eine vermutete Offenlegung als Sicherheitsvorfall behandeln: Zugang widerrufen oder rotieren, Reichweite prüfen und bereinigen.

## Datenmigration und Persistenz

- Persistierte Daten benötigen ein erkennbares Schema beziehungsweise eine Versionsnummer.
- Schemaänderungen erhalten getestete, vorwärtsgerichtete Migrationen. Bestehende Nutzerdaten dürfen nicht still verworfen werden.
- Schreibvorgänge müssen Abstürze und Teilfehler möglichst ohne beschädigten Datenbestand überstehen.
- Importdaten gelten als nicht vertrauenswürdig und werden vollständig validiert, bevor sie den lokalen Bestand verändern.
- Vor migrationsrelevanten Änderungen werden Sicherungs- und Wiederherstellungsverhalten dokumentiert.

## Codestyle und Prüfungen

- Dart-/Flutter-Konventionen und `analysis_options.yaml` einhalten: Klassen `UpperCamelCase`, Variablen und Funktionen `lowerCamelCase`, Dateien `snake_case.dart`.
- Vor Abschluss mindestens ausführen, soweit das Flutter-SDK verfügbar ist:

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

- Plattform- oder UI-Änderungen zusätzlich auf der betroffenen Zielplattform manuell prüfen. Für Android vor dem Merge nach Möglichkeit `flutter clean`, `flutter analyze`, `flutter test` und `flutter run` ausführen.
- Ein Pull Request mit geändertem Dart- oder Flutter-Code darf nur dann als technisch geprüft und mergebereit gemeldet werden, wenn `dart format`, `flutter analyze` und `flutter test` erfolgreich ausgeführt wurden.
- Fehlt das Flutter-SDK in der Arbeitsumgebung, darf vor dem Abschluss ausschließlich eine nach dem Abschnitt „Strikter Erlaubnisvorbehalt für GitHub Actions und externe Werkzeugketten“ freigegebene CI-Prüfung verwendet werden. Ist keine entsprechend freigegebene Prüfung verfügbar, wird der PR ausdrücklich als `Implementiert, technische Prüfung ausstehend` und nicht als mergebereit gemeldet.
- Nicht ausgeführte Prüfungen und der Grund dafür werden ausdrücklich genannt.

## Dokumentation und Lizenzen

- `README.md` enthält Zweck, Voraussetzungen, Setup, Start und Tests.
- Architekturentscheidungen mit aktuellem Nutzen werden unter `docs/` als Markdown dokumentiert; Diagramme bevorzugt als Mermaid und Architekturübersichten nach C4.
- Änderungen an Architektur, Persistenz, Import/Export oder Plattformintegration aktualisieren die Dokumentation im selben PR.
- Lizenzrelevante ausgelieferte Frameworks, Laufzeitabhängigkeiten, Logos, Bilder, Schriften und Assets werden mit Herkunft, Rechteinhaber, Lizenz und Verwendung in `ATTRIBUTIONS.md` dokumentiert, sobald sie hinzukommen.
- `CHANGELOG.md` wird nach Keep a Changelog gepflegt.

## Pull Requests und Branches

- `master` wird nur über Pull Requests verändert und niemals rebased oder per Force Push überschrieben.
- PRs enthalten Ziel, Änderungen, Tests, Dokumentationsstatus, Risiken und ein Closing-Keyword wie `Closes #123`.
- Arbeitsbranches dürfen auf den aktuellen `master` rebased werden. Geteilte Branches nur nach Abstimmung rebasen.
- Nach Rebase Prüfungen wiederholen. Veröffentlichte Arbeitsbranches ausschließlich mit `git push --force-with-lease` aktualisieren; `git push --force` ist verboten.
- Konflikte fachlich auflösen; bei Unsicherheit Rebase abbrechen statt Änderungen zu erraten.

## Abschlussdefinition

Eine Arbeit ist fertig, wenn Umfang und Akzeptanzkriterien erfüllt, relevante Tests erfolgreich, Formatierung und Analyse sauber, Dokumentation und Lizenzen geprüft sowie offene manuelle Prüfungen transparent benannt sind.

Die Abschlussmeldung unterscheidet verbindlich:

- `Implementiert, technische Prüfung ausstehend`: Mindestens eine vorgeschriebene automatisierte Prüfung konnte weder lokal noch über CI erfolgreich ausgeführt werden.
- `Geprüft und mergebereit`: Alle vorgeschriebenen automatisierten Prüfungen waren erfolgreich; noch offene manuelle Prüfungen sind transparent benannt und stehen dem Merge nach den Projektvorgaben nicht entgegen.
