# Sicherheit und Werkzeugketten

## Sicherheit

- Nie im Chat nach Anmeldedaten wie Nutzernamen, Passwörtern oder Tokens fragen.
- GitHub-Projekteinstellungen niemals eigenmächtig über den Cloud-Browser in Vertretung des menschlichen Entwicklers ändern.

## Strikter Erlaubnisvorbehalt für GitHub Actions und externe Werkzeugketten

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

### Freigabeverzeichnis für selbständige Ausführungen

Folgende Freigabe ist erteilt:

- **Repository:** `Huluvu424242/taugts`
- **Workflow:** `Flutter-Prüfungen`
- **Datei und freigegebene Version:** `.github/workflows/kiagent-check-ci.yml`, Git-Blob-SHA `8b771813664c515a4410d8a1d6a9c77acc4ae211`
- **Geltung:** dauerhaft bis zum Widerruf oder bis zu einer Änderung der unten genannten Gültigkeitsmerkmale
- **Erlaubte selbständige Ausführung:** automatische Ausführung über den in dieser Version vorhandenen `push`-Trigger auf allen Branches sowie den `pull_request`-Trigger für Zielbranches `master` und `release/**`; außerdem bedarfsweise manuelle Ausführung über `workflow_dispatch` und erneutes Ausführen eines zu dieser freigegebenen Version gehörenden Workflow-Laufs
- **Zweck:** Abhängigkeiten laden, Dart-Code formatieren, statische Flutter-Analyse ausführen, Flutter-Tests ausführen und unbeabsichtigte Formatierungsänderungen erkennen
- **Berechtigungen und Datenzugriff:** ausschließlich `contents: read`; Eingaben sind Repositoryinhalt und öffentlich beziehungsweise regulär auflösbare Projektabhängigkeiten; es sind keine Secrets und keine schreibenden Repositoryberechtigungen freigegeben
- **Ausgaben:** GitHub-Actions-Status und Laufprotokolle; keine Artefakte und keine durch den Workflow erzeugten Commits oder Codeänderungen
- **Freigabe erteilt:** 1. September 2026 durch den Projektverantwortlichen

Diese Freigabe gilt ausschließlich für die oben bezeichnete Version. Jede Änderung an `kiagent-check-ci.yml`, an einer anderen Action- oder Workflow-Datei oder an den von diesem Workflow verwendeten Actions, Triggern, Berechtigungen, Inputs, Outputs, Secrets, Datenzugriffen, Artefakten, Runnern oder Zwecken erfolgt weiterhin ausschließlich über eine vorherige Story, einen eigenen Branch und einen Pull Request. Die geänderte oder neu hinzugefügte Action ist bis zu einer erneuten ausdrücklichen Freigabe nicht zur selbständigen Ausführung zugelassen. Andere Workflows oder externe Werkzeugketten sind nicht freigegeben.

- Eine temporäre Ausnahme für Änderungen an GitHub-Projekteinstellungen gilt ausschließlich, wenn der KI-Assistent zuvor wörtlich gefragt hat: `Darf ich die Settings auf github selbst anpassen?` Erst ein darauf folgendes eindeutiges `Ja` erteilt die Erlaubnis für die konkret beauftragte Änderung. Ohne diese Abfolge liegt keine Erlaubnis vor.
- Secrets, Tokens, Passwörter, Schlüssel und echte personenbezogene Testdaten niemals hardcodieren, einchecken, protokollieren oder in Screenshots und Fehlertexte übernehmen.
- `.env`, Keystores, Signierschlüssel und lokale Konfigurationen durch Ignore-Regeln schützen.
- Tests verwenden Fakes und eindeutig ungültige Beispielwerte.
- Abhängigkeiten und GitHub Actions auf Herkunft, Wartungszustand, Lizenz und minimale Berechtigungen prüfen.
- GitHub Actions erhalten explizite minimale `permissions`; externe Actions möglichst auf unveränderliche Commit-SHAs festlegen.
- Eine vermutete Offenlegung als Sicherheitsvorfall behandeln: Zugang widerrufen oder rotieren, Reichweite prüfen und bereinigen.
