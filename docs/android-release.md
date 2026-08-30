# Android-Release

Für reproduzierbare, installierbare APKs ist der manuell startbare Workflow
**Android Release APK** unter `.github/workflows/android-release.yml`
vorbereitet.

Der Workflow:

- prüft, dass `release_version` exakt der Version in `pubspec.yaml`
  entspricht,
- weist bereits vorhandene Release-Tags zurück,
- führt `flutter analyze` und `flutter test` aus,
- lädt einen stabilen Android-Keystore ausschließlich aus GitHub Actions
  Secrets,
- baut eine signierte Release-APK,
- erzeugt eine SHA-256-Prüfsumme,
- veröffentlicht APK und Prüfsumme als GitHub Release
  `v<release_version>`.

Der Workflow wird nicht durch Pushes oder Pull Requests gestartet. Seine erste
und jede nicht bereits ausdrücklich freigegebene Ausführung unterliegt dem
Erlaubnisvorbehalt aus `AGENTS.md`.

## Warum ein stabiler Keystore notwendig ist

Android-APKs müssen signiert sein. Für spätere Updates muss immer derselbe
Signaturschlüssel verwendet werden. Der private Keystore darf deshalb nicht in
das Repository eingecheckt werden, sondern wird GitHub Actions verschlüsselt
als Secret bereitgestellt.

Wenn bereits eine APK mit einem anderen Schlüssel installiert wurde, kann
Android das Update verweigern. In diesem Fall muss die alte Installation
einmalig deinstalliert werden. Danach funktionieren Updates, solange derselbe
Release-Keystore weiterverwendet wird.

## Keystore unter Windows/PowerShell erzeugen

```powershell
keytool -genkeypair `
  -v `
  -keystore taugts-release.jks `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias taugts
```

Den Keystore danach als Base64-String für GitHub Actions kodieren:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("taugts-release.jks")) | Set-Clipboard
```

Optional zusätzlich in eine lokale Datei schreiben:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("taugts-release.jks")) | Set-Content -NoNewline "taugts-release.jks.base64.txt"
```

Die `.jks`-Datei und eine daraus erzeugte Base64-Datei dürfen nicht ins
Repository eingecheckt werden. Der Keystore muss dauerhaft und sicher gesichert
werden, weil spätere APK-Updates denselben Schlüssel benötigen. Geheimwerte
werden niemals im Chat, in Issues, Pull Requests oder Logs veröffentlicht.

## Benötigte GitHub Actions Secrets

Unter **Settings → Secrets and variables → Actions → New repository secret**
werden durch den Projektverantwortlichen folgende Repository-Secrets angelegt:

- `ANDROID_KEYSTORE_BASE64`: Base64-Inhalt der `.jks`-Datei
- `ANDROID_KEYSTORE_PASSWORD`: Passwort des Keystores
- `ANDROID_KEY_ALIAS`: Alias, beispielsweise `taugts`
- `ANDROID_KEY_PASSWORD`: Passwort des Schlüssels

## Release ausführen

Vor der ersten Ausführung müssen der Workflow-PR menschlich geprüft und gemergt,
die Secrets eingerichtet und die endgültige Workflow-Version gemäß
`AGENTS.md` ausdrücklich zur Ausführung freigegeben sein.

1. `pubspec.yaml` auf eine neue Version im Format
   `MAJOR.MINOR.PATCH+BUILD` setzen, beispielsweise `0.1.1+2`.
2. Die Versionsänderung über einen Pull Request mergen.
3. In GitHub **Actions → Android Release APK → Run workflow** öffnen.
4. `release_version` exakt wie in `pubspec.yaml` eintragen.
5. Optional Release Notes in Markdown erfassen.
6. Den Workflow nur bei vorliegender Ausführungsfreigabe starten.
7. Nach erfolgreichem Lauf das erzeugte GitHub Release öffnen und die APK
   herunterladen.
8. Die SHA-256-Prüfsumme der heruntergeladenen APK prüfen.
9. Vom erzeugten Release-Tag den produktiven Release-Branch anlegen.

## Produktiver Release-Branch

Nach einem erfolgreich veröffentlichten Release wird vom zugehörigen
Release-Tag ein Wartungsbranch nach diesem Schema erstellt:

```text
release/<tagname>
```

Erzeugt der Workflow beispielsweise den Tag `v0.1.1+2`, lautet der Branch:

```text
release/v0.1.1+2
```

Der Branch muss exakt vom Release-Tag ausgehen:

```powershell
git fetch origin --tags
git branch release/v0.1.1+2 v0.1.1+2
git push origin release/v0.1.1+2
```

Auf Release-Branches sind keine neuen Features vorgesehen. Bugfixes,
Sicherheitsupdates und notwendige Wartungsmaßnahmen werden über Pull Requests
eingebracht und, soweit weiterhin relevant, auch nach `master` übernommen.

Die Gradle-Konfiguration liest Signing-Daten nur aus Umgebungsvariablen oder
Gradle-Properties. Lokale Release-Builds ohne diese Werte behalten die
Debug-Signatur als Entwicklungs-Fallback. Der GitHub-Release-Workflow verlangt
dagegen alle vier Secrets und bricht bei fehlenden Werten vor dem Build ab.

## Deaktivierung und Schlüsselvorfälle

Der Workflow kann über einen eigenen Story- und Pull-Request-Prozess entfernt
oder deaktiviert werden. Ein fehlerhaftes Release oder Tag wird niemals
automatisch gelöscht. Bei vermuteter Offenlegung des Keystores oder eines
Passworts sind die betroffenen Secrets umgehend zu entfernen beziehungsweise
zu rotieren und die Auswirkungen auf die Updatefähigkeit bestehender
Installationen zu bewerten.
