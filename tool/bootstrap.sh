#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"

flutter create \
  --org de.huluvu \
  --project-name taugts \
  --platforms android,windows,linux \
  .
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
