# Barrierefreiheit und Bug-Meldung

Stand: 31. August 2026 · vorbereitete Version: 0.1.0+2

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

Die Verwaltung der Bewertungskriterien bietet semantisch beschriftete Aktionen,
einen fokussierbaren Fehlersammler, wahrnehmbare Lade-, Leer-, Fehler- und
Erfolgszustände sowie eine platzsparende Aktionsauswahl, die auch bei großer
Systemschrift bedienbar bleibt. Verwendete Kriterien werden beim Entfernen nur
deaktiviert, damit historische Bewertungen lesbar bleiben.

Vor einem öffentlichen Release bleiben folgende manuelle Prüfungen offen:

- vollständiger Kernablauf mit TalkBack auf Android,
- große Systemschrift und erhöhte Display-Skalierung,
- kleine Android-Bildschirmgröße,
- Gestennavigation und Erreichbarkeit unterer Aktionen,
- zusammenhängender Ablauf aus Produkt, Ort, Erlebnisentwurf und Bewertung,
- Bug-Meldung und vollständige Barrierefreiheitserklärung auf einem realen
  Gerät.

Der Getränkebewertungsbogen ist ausdrücklich einzubeziehen. Die gebündelte
Prüfung wird in
[Story #30](https://github.com/Huluvu424242/taugts/issues/30) verfolgt. Solange
diese Punkte offen sind, wird für Version 0.1.0+1 kein vollständig manuell
bestätigter Barrierefreiheitsstatus behauptet. Der konkrete Freigabestand wird
zusätzlich in der
[Release-Checkliste](release-checklist-0.1.0+1.md) dokumentiert.

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
