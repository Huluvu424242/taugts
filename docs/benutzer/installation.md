# Installation und Updates

## Android

Nach Veröffentlichung wird die APK über die [GitHub Releases](https://github.com/Huluvu424242/taugts/releases) des Projekts bereitgestellt.

Für Version 0.1.0+3 werden die APK und eine zugehörige SHA-256-Prüfsummendatei bereitgestellt. Vor der Installation sollte die Prüfsumme kontrolliert werden. Unter Windows kann dies beispielsweise mit folgendem Befehl erfolgen:

```powershell
Get-FileHash .\taugts-0.1.0+3.apk -Algorithm SHA256
```

Der ermittelte Hash muss mit dem Inhalt der bereitgestellten `.apk.sha256`-Datei übereinstimmen.

Android kann bei einer manuellen APK-Installation verlangen, die Installation aus dem verwendeten Browser oder Dateimanager ausdrücklich zu erlauben. Anschließend kann die APK geöffnet und die Installation bestätigt werden.

## Updates

APK-Updates können über eine vorhandene Installation installiert werden, wenn sie mit demselben Release-Signierschlüssel signiert wurden. Vor einer Neuinstallation oder einem Wechsel des Signierschlüssels ist zu beachten, dass die derzeitige Version noch keinen Exportweg für die lokal gespeicherten Fachdaten besitzt.

## Weitere Plattformen

Android ist die primäre Zielplattform. Windows und Linux werden architektonisch berücksichtigt, gehören aber noch nicht zum veröffentlichten Funktionsumfang.
