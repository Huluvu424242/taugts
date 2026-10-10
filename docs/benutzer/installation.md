# Installation und Updates

## Offizielle Android-Version

Die Version **0.1.0+9** wird derzeit für die Veröffentlichung vorbereitet; bis dahin bleibt **0.1.0+8 vom 6. September 2026** der letzte dokumentierte offizielle Release. Die APK und ihre SHA-256-Prüfsummendatei werden über [GitHub Releases](https://github.com/Huluvu424242/taugts/releases) bereitgestellt. Die neuen Funktionen von 0.1.0+9 sind erst nach Veröffentlichung der entsprechenden APK verfügbar.

1. Die Datei `taugts-0.1.0+9.apk` und die zugehörige Datei `.apk.sha256` aus demselben Release herunterladen.
2. Die Prüfsumme kontrollieren. Unter Windows beispielsweise:

```powershell
Get-FileHash .\taugts-0.1.0+9.apk -Algorithm SHA256
```

3. Die ermittelte SHA-256-Prüfsumme mit der veröffentlichten Prüfsummendatei vergleichen.
4. Falls Android danach fragt, die Installation aus dem verwendeten Browser oder Dateimanager ausdrücklich erlauben und die APK installieren.

## Updates und Datensicherung

Ein Update über eine vorhandene Android-Installation setzt denselben Signierschlüssel und eine höhere Android-Buildnummer voraus. **Vor jedem Test-Update einen JSON-Export erstellen**, separat aufbewahren und die Wiederherstellbarkeit prüfen. Nicht deinstallieren oder App-Daten löschen, solange diese Daten gebraucht werden.

Besonders wichtig: Die SQLite-Datenbanken aus Vorabversionen **0.1.0+6 und früher** besitzen keinen direkten Upgradepfad zur ab 0.1.0+7 konsolidierten Baseline. Für solche Daten ist ein geprüfter JSON-Export und Import in eine frisch angelegte Datenbank erforderlich. Für 0.1.0+7 → 0.1.0+8 wurde keine neue Datenbank-Baseline eingeführt.

Der unveröffentlichte `master` enthält zusätzlich eine Datenmigration für den vereinheitlichten Erlebniszeitraum sowie das JSON-Austauschformat Version 3. Hinweise stehen in [Datenschutz und Datenhaltung](datenhaltung.md) und in der [Datenbankdokumentation](../architecture/datenbank.md).

## Test-APK vom aktuellen master

Neben offiziellen Releases existiert ein [separater Workflow für Test-APKs](../entwicklung/android-test-apk.md). Er ist ausschließlich manuell startbar und benötigt eine **gesonderte ausdrückliche Ausführungsfreigabe**. Er erstellt keine neue offizielle Version und keinen GitHub-Release-Tag. Für eine installierbare Aktualisierung muss die gewählte Test-Buildnummer größer als die bereits installierte sein; die Signatur muss zur bestehenden App passen.

## Weitere Plattformen

Android ist die primäre Zielplattform. Windows und Linux werden architektonisch berücksichtigt, gehören jedoch nicht zum veröffentlichten Funktionsumfang.
