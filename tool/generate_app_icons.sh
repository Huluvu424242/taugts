#!/usr/bin/env bash
set -euo pipefail

projekt_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
quelle="$projekt_root/assets/icons/app_icon_source.png"

if command -v magick >/dev/null 2>&1; then
  bildwerkzeug=(magick)
elif command -v convert >/dev/null 2>&1; then
  bildwerkzeug=(convert)
else
  echo "ImageMagick (magick oder convert) wird zur Icon-Erzeugung benötigt." >&2
  exit 1
fi

erzeuge_icon() {
  local groesse="$1"
  local ziel="$2"
  "${bildwerkzeug[@]}" "$quelle" -resize "${groesse}x${groesse}" "$ziel"
}

erzeuge_icon 48 "$projekt_root/android/app/src/main/res/mipmap-mdpi/ic_launcher.png"
erzeuge_icon 72 "$projekt_root/android/app/src/main/res/mipmap-hdpi/ic_launcher.png"
erzeuge_icon 96 "$projekt_root/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
erzeuge_icon 144 "$projekt_root/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
erzeuge_icon 192 "$projekt_root/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"

echo "Android-Launcher-Icons wurden aus assets/icons/app_icon_source.png erzeugt."
