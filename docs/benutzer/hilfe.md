# Bekannte Einschränkungen und Hilfe

## Versionsstand

**0.1.0+10 ist für die Veröffentlichung vorbereitet**, aber noch nicht als offizielle APK bestätigt. Ob eine vorherige vorbereitete Version bereits veröffentlicht wurde, ist vor der Freigabe anhand von GitHub Releases zu prüfen. Die Änderungen für 0.1.0+10 stehen im [Changelog](https://github.com/Huluvu424242/taugts/blob/master/CHANGELOG.md).

## Bekannte Einschränkungen

- Windows und Linux gehören weiterhin nicht zum veröffentlichten Funktionsumfang.
- Barcode-Scanner, Standortermittlung, Karte und Reverse Geocoding müssen vor einer öffentlichen Freigabe auf den vorgesehenen realen Geräten manuell geprüft werden.
- Import, Export und der Android-Speicherdialog sind mit realistischen Datenbeständen sowie Abbruch- und Fehlerfällen auf einem echten Gerät zu prüfen. Dasselbe gilt für den Excel-Export einschließlich des Diagramms in einer Tabellenkalkulation.
- Eine systematische manuelle Prüfung mit TalkBack, großer Systemschrift, Gestennavigation und kleinem Android-Gerät steht noch aus; siehe [Story #30](https://github.com/Huluvu424242/taugts/issues/30).
- Datenbanken aus 0.1.0+6 oder älteren Vorabversionen besitzen keinen direkten SQLite-Upgradepfad auf die ab 0.1.0+7 eingeführte Baseline. Vor dem Update einen JSON-Export sichern und dessen Import prüfen.
- Für Änderungen aus `master` ist kein neues offizielles Release festgelegt. Eine [Test-APK](../entwicklung/android-test-apk.md) kann nur über den gesondert freizugebenden manuellen Workflow erstellt werden.

## Hilfe zu Daten und Erlebnissen

- [Installation und Updates](installation.md)
- [Bedienung, Erlebnisse und Bewertungen](bedienung.md)
- [Datenschutz, JSON-Import und -Export sowie Migration](datenhaltung.md)
- [Auswertungen und Excel-Export](auswertungen.md)

## Projekt und Dokumentation

Im App-Menü führt **Über** zur **Projektseite** auf GitHub und zur veröffentlichten **Projektdokumentation**. Beide Ziele werden extern geöffnet. Kann ein Ziel nicht geöffnet werden, bleibt der Dialog offen und zeigt einen verständlichen Fehler.

## Fehler melden

Über **Bug melden** wird ein Bericht mit App-Version und Aufrufkontext vorbereitet und zur Prüfung auf GitHub geöffnet. Erst dort entscheidet der Nutzer über das Absenden. Alternativ können Fehler über die [GitHub-Issues](https://github.com/Huluvu424242/taugts/issues) erfasst werden. Bitte keine Passwörter, Tokens oder unnötigen personenbezogenen Daten mitsenden.

## Barrierefreiheit

Umsetzungsstand und bekannte Barrieren stehen in der [Barrierefreiheitserklärung](../barrierefreiheit.md). Barrierefreiheitsprobleme können ebenfalls in der App gemeldet werden.
