# Releasevorbereitung

Die Releasevorbereitung durch einen KI-Agenten ist ein eigener, verbindlicher Arbeitsablauf. Sie wird auf einem eigenen Arbeitsbranch durchgeführt und über einen Pull Request gegen `master` bereitgestellt. Ein Release darf erst als vorbereitet gemeldet werden, wenn die nachfolgenden Schritte vollständig durchgeführt und auf Konsistenz geprüft wurden.

## Verbindlicher Ablauf

1. Den vorgesehenen Releaseumfang und die Zielversion einschließlich Buildnummer anhand des aktuellen `master`-Stands und der seit dem letzten Release aufgenommenen Änderungen ermitteln.
2. Die zentrale Versionsangabe des Projekts auf die vorgesehene Releaseversion einschließlich Buildnummer aktualisieren. Alle Stellen, die diese Version fest oder abgeleitet anzeigen, müssen denselben Release-Stand wiedergeben.
3. `CHANGELOG.md` nach Keep a Changelog für das Release aktualisieren. Der Changelog auf `master` ist die maßgebliche fachliche Quelle für die veröffentlichte Änderungshistorie.
4. Alle für den Release-Stand relevanten Dokumentationen prüfen und aktualisieren. Dazu gehören mindestens Benutzerdokumentation, Entwicklerdokumentation und vorhandene Release-Dokumentation; insbesondere müssen neue oder geänderte sichtbare Funktionen, Bedienabläufe, Einschränkungen, Datenhaltung sowie Import-/Exportverhalten korrekt beschrieben sein. Zusätzlich ist repositoryweit nach fest eingetragenen Versions- und Buildangaben in der Dokumentation zu suchen. Jede Angabe, die den aktuell ausgelieferten, aktuellen oder empfohlenen Release-Stand beschreibt, muss auf die Zielversion einschließlich Buildnummer geprüft und erforderlichenfalls aktualisiert werden. Historische Versionsangaben, die ausdrücklich einen früheren Release oder dessen damaligen Funktionsstand beschreiben, bleiben unverändert, sofern ihr historischer Bezug weiterhin korrekt ist.
5. Die in der laufenden App im Bereich `Über` angezeigte `Änderungshistorie` im selben Releasevorbereitungs-PR aktualisieren. Ihr fachlicher Inhalt muss mit dem für dieses Release vorgesehenen Inhalt von `CHANGELOG.md` übereinstimmen und darf keine eigenständig abweichend gepflegte Releasehistorie bilden.
6. Vor Abschluss ausdrücklich gegenprüfen, dass zentrale Versionsangabe einschließlich Buildnummer, `CHANGELOG.md`, alle dokumentierten Angaben zum aktuellen Release-Stand, relevante Dokumentation und die unter `Über` angezeigte `Änderungshistorie` denselben Release-Stand beschreiben. Abweichungen werden vor Bereitstellung des PRs behoben.
7. Die nach [Qualität und Dokumentation](06-quality-documentation.md#codestyle-und-prüfungen) sowie [Workflow und Zusammenarbeit](01-workflow.md#pull-requests-und-branches) erforderlichen Prüfungen durchführen und den Releasevorbereitungs-PR mit Ziel, Änderungen, Prüfungen, Dokumentationsstatus, Risiken und Closing-Keyword bereitstellen.

## Versionsangaben in der Dokumentation

- Die Suche nach Versions- und Buildangaben umfasst das gesamte Repository, soweit dort Benutzer-, Entwickler-, Installations-, Bezugs-, Release- oder sonstige Dokumentation gepflegt wird.
- Maßgeblich ist die Bedeutung der Fundstelle: Aussagen wie „aktuell ausgeliefert“, „aktuelle Version“, „derzeitige Version“ oder gleichwertige Formulierungen müssen auf die Zielversion einschließlich Buildnummer zeigen.
- Versionsangaben in historischen Releasehinweisen, Changelog-Einträgen, alten Release-Checklisten oder Beschreibungen eines ausdrücklich früheren Funktionsstands werden nicht pauschal ersetzt.
- Ist nicht eindeutig erkennbar, ob eine Versionsangabe aktuell oder historisch gemeint ist, muss ihr fachlicher Kontext geprüft und die Formulierung erforderlichenfalls eindeutig gemacht werden, statt die Nummer mechanisch zu ersetzen.
- Eine Releasevorbereitung ist unvollständig, solange eine Dokumentationsstelle eine ältere Version als aktuell ausgeliefert, aktuell oder empfohlen bezeichnet oder eine sonstige aktuelle Versions-/Buildangabe von der vorgesehenen Zielversion abweicht.

## Synchronisationsregel für die Änderungshistorie

- `CHANGELOG.md` auf `master` ist der fachliche Master für die Änderungshistorie eines veröffentlichten Releases.
- Die im Bereich `Über` angezeigte `Änderungshistorie` ist eine Nutzeransicht dieses Inhalts und muss zum Zeitpunkt des Releases inhaltlich mit dem Changelog synchron sein.
- Formulierungen dürfen für die Darstellung in der App gekürzt oder an die verfügbare Oberfläche angepasst werden, solange keine Änderung ergänzt, weggelassen oder in ihrer Bedeutung verändert wird.
- Wird `CHANGELOG.md` im Releasevorbereitungs-PR nachträglich geändert, muss die angezeigte `Änderungshistorie` im selben PR erneut abgeglichen und erforderlichenfalls angepasst werden.
- Eine Releasevorbereitung ist unvollständig, solange Changelog und angezeigte Änderungshistorie für das vorgesehene Release voneinander abweichen.
