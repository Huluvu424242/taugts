# Projektaufsetzung und Grundgerüst

## App-Identität: Name und Logo vor Implementierungsbeginn

- Jede neu zu erstellende App erhält vor Beginn der App-Implementierung einen finalen Namen und ein auf diesem Namen sowie der fachlichen Aufgabe beruhendes finales Logo.
- Name und Logo sind fachliche Startvoraussetzungen und keine nachträgliche Verschönerung. Erst mit beiden lässt sich die Identität der App eindeutig festlegen; insbesondere hängen Repositoryname, Paket- und Anzeigenamen, visuelle Wiedererkennbarkeit und weitere Projektartefakte davon ab.
- Das erste lauffähige App-Grundgerüst muss sich bereits durch seinen finalen Namen und sein Logo eindeutig von anderen Apps unterscheiden. Generische Frameworknamen, Standard-Launcher-Icons oder Platzhalterlogos sind nicht als fertiges Grundgerüst zulässig.
- Das Logo wird von Anfang an mindestens als App- beziehungsweise Launcher-Icon der primären Zielplattform integriert. Erforderliche plattformspezifische Varianten und Größen werden aus einer geeigneten hochwertigen Quelldatei reproduzierbar abgeleitet.
- Logoentwurf, Auswahl und Integration werden in den initialen Stories und Akzeptanzkriterien berücksichtigt. Ohne finales Logo darf die fachliche Implementierung nicht beginnen.
- Herkunft, Urheberschaft, Nutzungsrechte, Lizenz und Verwendung des Logos werden spätestens mit seiner Integration in `ATTRIBUTIONS.md` dokumentiert.

## Verbindliche Grundgerüst-Funktionen

Ein App-Grundgerüst ist erst fertig, wenn neben Name und Logo auch eine Barrierefreiheitserklärung, eine Funktion zum Melden von Bugs, ein direkter Zugang zur Projektseite und eine öffentlich erreichbare Benutzerdokumentation vorhanden, aus der laufenden App erreichbar und soweit automatisierbar getestet sind. Diese Bestandteile gehören in die Initial-Story des Grundgerüsts und dürfen weder als spätere Fachstory noch als nachgelagerte Querschnittsarbeit verschoben werden.

Die Implementierung ist vollständig innerhalb des jeweiligen App-Projekts zu dokumentieren und zu pflegen. App-Name, Repository, Projekt-URL, URL der Benutzerdokumentation, Issue-Vorlage, Labels, Versionsermittlung, Texte, bekannte Barrieren und fachliche Aufrufkontexte werden projektspezifisch festgelegt. Es darf keine Laufzeit-, Quellcode- oder Dokumentationsabhängigkeit zu einem anderen App-Projekt entstehen.

### Gemeinsamer Zugang und technische Struktur

- Jeder vollständige Screen bietet an einer konsistenten, semantisch beschrifteten Stelle ein gemeinsames App- beziehungsweise Support-Menü mit mindestens `Bug melden` und `Über`.
- Temporäre Dialoge und fachliche Unterabläufe, in denen Fehler eigenständig auftreten können, bieten ebenfalls einen direkt erreichbaren Meldeweg oder übergeben ihren eindeutigen Kontext an die gemeinsame Meldefunktion.
- Der Über-Dialog zeigt App-Name sowie die tatsächlich installierte Releaseversion einschließlich Buildnummer und verlinkt die Barrierefreiheitserklärung, die Projektseite der App und die Benutzerdokumentation. Auch der Über-Dialog und die Barrierefreiheitserklärung bieten unmittelbar `Bug melden`.
- Für Apps, die unter Einsatz von KI entwickelt wurden, wird die Kennzeichnung „Powered by KI“ als verbindliche rechtliche Projektvorgabe im Über-Dialog unmittelbar links neben der `Schließen`-Aktion sichtbar eingebunden. Das KI-Hinweislogo ist ausdrücklich vom App-Logo getrennt zu behandeln und so zu skalieren beziehungsweise ohne zusätzlichen Layout-Footprint zu platzieren, dass der bestehende Abstand zwischen `Schließen` und der benachbarten Aktion für die Barrierefreiheitserklärung unverändert bleibt.
- Die Links auf Projektseite und Benutzerdokumentation besitzen verständliche sichtbare und semantische Bezeichnungen; ihr externes Öffnen folgt denselben testbaren Plattformabstraktionen und Fehlerbehandlungen wie andere externe Ziele der Support-Oberfläche.
- Die Support-Oberfläche, die Ermittlung der installierten App-Version und das Öffnen externer Ziele werden getrennt. Plattformzugriffe liegen hinter kleinen injizierbaren Schnittstellen, damit Widgettests Fakes verwenden und keine realen Browser, Paketinformationen oder Netzverbindungen benötigen.
- Alle asynchronen Übergänge beachten die Lebenszyklusregeln aus [Architektur und Implementierung](03-architecture.md). Fehler beim Laden der Version oder Öffnen eines externen Ziels werden verständlich und als Live-Region ausgegeben; der Dialog schließt sich bei einem Fehler nicht und bereits eingegebene Daten bleiben erhalten.

### Projektseite und Benutzerdokumentation

- Jedes App-Projekt besitzt eine eindeutig festgelegte Projektseite. Bei einem GitHub-Projekt ist dies die kanonische Repository-Seite. Die Seite `Über` verlinkt dieses Ziel direkt.
- Für **Taugt’s?** ist die Projektseite verbindlich `https://github.com/Huluvu424242/taugts`.
- Jedes App-Projekt enthält eine für Endnutzer geschriebene Benutzerdokumentation unter `docs/`. Sie wird neben Architektur- und Entwicklerdokumentation als eigener Dokumentationsbereich gepflegt und beschreibt mindestens Installation beziehungsweise Bezug der App, grundlegende Bedienung, zentrale Funktionen, Datenhaltung und Datenaustausch soweit vorhanden, bekannte Einschränkungen sowie Hilfe- und Meldewege.
- Die Dokumentation wird ausschließlich im Markdown-Format unter `docs/` fachlich gepflegt. Manuell gepflegte HTML-Kopien sind unzulässig; generiertes HTML ist ausschließlich ein Build-Artefakt.
- **MkDocs** ist der verbindliche Generator für die veröffentlichte Dokumentationswebsite eines App-Grundgerüsts. Die MkDocs-Konfiguration liegt reproduzierbar im Repository; Benutzer-, Entwickler- und Architekturdokumentation werden über dieselbe Website zugänglich gemacht.
- Die GitHub-Pages-Erzeugung und -Veröffentlichung erfolgt in jedem App-Grundgerüst über den einheitlich benannten Workflow `.github/workflows/ghpage-generator.yml`. Abweichende Workflow-Dateinamen sind für diese Grundgerüst-Funktion nicht zulässig.
- Der Workflow `ghpage-generator.yml` baut ausschließlich die Dokumentation und veröffentlicht das statische Ergebnis auf GitHub Pages. Er erzeugt keine Codeänderungen oder Commits und folgt vollständig dem Erlaubnisvorbehalt und den Sicherheitsanforderungen aus [Sicherheit und Werkzeugketten](05-security-tooling.md).
- Die Benutzerdokumentation wird von Anfang an so strukturiert, dass sie als statische Website veröffentlicht werden kann. Interne Entwicklerdetails dürfen auf weiterführende Dokumente verweisen, gehören aber nicht ungefiltert in die Benutzerdokumentation.
- Die Benutzerdokumentation wird über GitHub Pages der Projektseite frei im Web zugänglich gemacht. Die kanonische veröffentlichte URL wird projektspezifisch dokumentiert und von der Seite `Über` aus direkt geöffnet.
- Für **Taugt’s?** ist die kanonische Benutzerdokumentation verbindlich `https://huluvu424242.github.io/taugts/`.
- Fachliche oder UX-relevante Änderungen, die das Nutzerverhalten, sichtbare Funktionen, Einschränkungen, Datenhaltung oder Bedienabläufe verändern, prüfen und aktualisieren die Benutzerdokumentation im selben Pull Request.
- Projektseite und Benutzerdokumentation müssen vor dem ersten öffentlichen Release erreichbar sein. Ist die Veröffentlichung technisch noch nicht eingerichtet, ist das Grundgerüst in diesem Punkt nicht vollständig abgeschlossen.

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

- Erreichbarkeit von `Bug melden`, `Über`, Barrierefreiheitserklärung, Projektseite und Benutzerdokumentation über alle vorgesehenen Einstiege,
- Anzeige der installierten Release- und Buildversion sowie verständliche Behandlung eines Ladefehlers,
- korrekte projektspezifische Ziele für Projektseite und Benutzerdokumentation sowie verständliche Fehlerzustände beim externen Öffnen,
- Offline-Anzeige, Scrollbarkeit, Semantik und Meldeweg der Barrierefreiheitserklärung,
- unterschiedliche erwartete Aufrufkontexte für sämtliche Screens, Dialoge und fachlichen Varianten,
- Pflichtfeldvalidierung, Fehlersammler, Fokus- und Scrollverhalten sowie Erhalt der Eingaben,
- korrekt kodierter Ziel-Link mit projektspezifischem Repository, Issue-Vorlage, Bug-Label, Fehlerart, Kontext, Version und optionaler Beschreibung,
- Ausschluss von Tokens, Passwörtern, Logs und nicht ausdrücklich eingegebenen Diagnose- oder Nutzerdaten,
- verständlicher Fehlerzustand bei fehlgeschlagener Versionsermittlung oder beim Öffnen des externen Ziels.

Zusätzlich werden die Erklärung und der vollständige Meldeablauf vor dem ersten öffentlichen Release manuell mit großer Systemschrift, TalkBack sowie auf einem kleinen Android-Bildschirm geprüft. Offene manuelle Prüfungen werden wie in der [Abschlussdefinition](01-workflow.md#abschlussdefinition) beschrieben ausgewiesen.
