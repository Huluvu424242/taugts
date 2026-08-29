# Barrierefreiheit und Bug-Meldung

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

Vor einem öffentlichen Release bleiben manuelle Prüfungen mit TalkBack, großer
Systemschrift, einem kleinen Android-Gerät und Gestennavigation erforderlich.

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
