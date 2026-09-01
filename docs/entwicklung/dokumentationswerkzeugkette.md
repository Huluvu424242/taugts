# Dokumentationswerkzeugkette

## Zweck

Die Projektdokumentation wird ausschließlich als Markdown unter `docs/` gepflegt. MkDocs erzeugt daraus eine statische HTML-Website, die über GitHub Pages unter `https://huluvu424242.github.io/taugts/` veröffentlicht werden soll. Die HTML-Ausgabe ist ein Build-Artefakt und keine zweite Dokumentationsquelle.

## Komponenten

- **MkDocs 1.6.1** – statischer Dokumentationsgenerator.
- **Material for MkDocs 9.7.7** – responsives MkDocs-Theme, MIT-Lizenz.
- **GitHub Actions** – Build und Deployment über `.github/workflows/ghpage-generator.yml`.
- **GitHub Pages** – Hosting des erzeugten statischen Artefakts.

Die Python-Abhängigkeiten sind in `requirements-docs.txt` fest versioniert. Änderungen daran sind wie Änderungen an der übrigen Werkzeugkette zu prüfen.

## Workflow `ghpage-generator.yml`

### Trigger

Der Workflow ist für folgende Trigger vorgesehen:

- `push` auf `master`, beschränkt auf Änderungen an `docs/**`, `mkdocs.yml`, `requirements-docs.txt` oder der Workflow-Datei selbst,
- `workflow_dispatch` für eine bewusst manuell gestartete Neuveröffentlichung.

Er besitzt bewusst **keinen `pull_request`-Trigger**. Damit wird der neue, noch nicht freigegebene Workflow nicht bereits durch den Implementierungs-PR ausgeführt.

### Jobs und Datenfluss

1. Repository mit `contents: read` auschecken.
2. Python 3.13 bereitstellen.
3. dokumentationsbezogene Python-Abhängigkeiten aus `requirements-docs.txt` installieren.
4. `mkdocs build --strict` ausführen; Eingabe sind ausschließlich Repository-Dateien und öffentlich auflösbare Python-Pakete.
5. den erzeugten Ordner `site/` als GitHub-Pages-Artefakt hochladen.
6. das Artefakt in einem getrennten Deployment-Job mit `pages: write` und `id-token: write` auf GitHub Pages veröffentlichen.

Es werden keine Anwendungscodeänderungen, Commits oder Repository-Dateien erzeugt oder zurückgeschrieben.

## Berechtigungen

Die Berechtigungen werden jobbezogen minimiert:

- Build: `contents: read`
- Deployment: `pages: write`, `id-token: write`

Es werden keine projektspezifischen Secrets verwendet. Das von GitHub bereitgestellte OIDC-Token dient ausschließlich der Herkunftsprüfung des Pages-Deployments.

## Verwendete externe Actions

Alle externen Actions stammen aus der offiziellen GitHub-Organisation `actions` und sind auf unveränderliche Commit-SHAs festgelegt:

- `actions/checkout` v5: `fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09`
- `actions/setup-python` v6: `ece7cb06caefa5fff74198d8649806c4678c61a1`
- `actions/configure-pages` v6: `45bfe0192ca1faeb007ade9deae92b16b8254a0d`
- `actions/upload-pages-artifact` v4: `7b1f4a764d45c48632c6b24a0339c27f5614fb0b`
- `actions/deploy-pages` v4: `d6db90164ac5ed86f2b6aed7e0febac5b3c0c03e`

Die zugehörigen Major-Tags wurden bei der Einführung gegen diese Commit-SHAs aufgelöst. Eine spätere Änderung eines SHAs gilt gemäß `AGENTS.md` als Werkzeugkettenänderung und benötigt eine neue Prüfung und Freigabe.

## Bedrohungs- und Risikoanalyse

### Supply Chain

Risiko: manipulierte oder kompromittierte Build-Abhängigkeiten könnten während des Builds ausgeführt werden.

Gegenmaßnahmen:

- Python-Abhängigkeiten sind versionsfest.
- GitHub Actions sind auf Commit-SHAs fixiert.
- es werden nur etablierte öffentliche Quellen verwendet.
- der Workflow besitzt im Build-Job keine Schreibrechte.

### Veröffentlichung unerwünschter Inhalte

Risiko: Inhalte unter `docs/` werden öffentlich, obwohl sie nicht für die Veröffentlichung bestimmt sind.

Gegenmaßnahmen:

- `docs/` wird als öffentlich veröffentlichbarer Dokumentationsbereich behandelt.
- Secrets, Zugangsdaten und personenbezogene Daten dürfen dort gemäß `AGENTS.md` nicht abgelegt werden.
- Änderungen gelangen nur über den geschützten `master`-Workflow in die Veröffentlichungsquelle.

### Übermäßige Berechtigungen

Risiko: ein kompromittierter Build-Schritt könnte Repository- oder Pages-Rechte missbrauchen.

Gegenmaßnahmen:

- Build und Deployment sind getrennte Jobs.
- `pages: write` und `id-token: write` existieren nur im Deployment-Job.
- keine `contents: write`-Berechtigung und keine projektspezifischen Secrets.

## Artefakte, Logs, Laufzeit und Kosten

Das einzige Build-Artefakt ist die statische Website aus `site/`, die über `actions/upload-pages-artifact` für das Pages-Deployment bereitgestellt wird. Workflow-Logs und Artefaktaufbewahrung folgen den GitHub-seitigen Repository- bzw. Plattformvorgaben; der Workflow legt keine zusätzliche Aufbewahrungsdauer fest.

Die erwartete Laufzeit liegt bei wenigen Minuten auf einem GitHub-gehosteten Ubuntu-Runner. Es werden keine kostenpflichtigen externen Dienste angesprochen; mögliche GitHub-Actions-Kontingente richten sich nach dem jeweiligen GitHub-Tarif.

## Erlaubte Akteure und Nutzung

Der automatische Trigger ist ausschließlich für Änderungen auf `master` vorgesehen. Eine manuelle Ausführung über `workflow_dispatch` ist technisch möglich, unterliegt aber weiterhin dem Erlaubnisvorbehalt der `AGENTS.md`. Die bloße Existenz oder der Merge des Workflows erteilt einem KI-Assistenten keine Ausführungsfreigabe.

## Auditierbarkeit

Build- und Deployment-Schritte sind vollständig in der versionierten Workflow-Datei definiert. Verwendete Action-SHAs und Python-Versionen sind nachvollziehbar festgelegt. GitHub Actions protokolliert die einzelnen Läufe und GitHub Pages das zugehörige Deployment.

## Deaktivierung und Rollback

Rollback ist möglich, indem der Workflow über einen regulären Pull Request auf eine zuvor geprüfte Version zurückgesetzt oder entfernt wird. Bei einem sicherheitsrelevanten Problem darf er bis zur Klärung nicht ausgeführt werden. Änderungen an GitHub-Projekteinstellungen erfolgen ausschließlich nach der gesonderten Erlaubnisregel der `AGENTS.md`.

## Lokale Prüfung

Die Dokumentationsgenerierung lässt sich unabhängig von GitHub Actions prüfen:

```bash
python -m pip install -r requirements-docs.txt
mkdocs build --strict
```

Die Ausgabe entsteht ausschließlich unter `site/` und wird nicht eingecheckt.
