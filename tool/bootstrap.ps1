$ErrorActionPreference = 'Stop'
$projectDir = Split-Path -Parent $PSScriptRoot
Set-Location $projectDir

flutter create --org de.huluvu --project-name taugts --platforms android,windows,linux .
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
