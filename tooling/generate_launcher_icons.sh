#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ICON="$PROJECT_ROOT/icon.png"

if [[ ! -f "$SOURCE_ICON" ]]; then
  echo "Source icon not found: $SOURCE_ICON" >&2
  exit 1
fi

resize_icon() {
  local size="$1"
  local output_path="$2"

  mkdir -p "$(dirname "$output_path")"

  if command -v /usr/bin/sips >/dev/null 2>&1; then
    /usr/bin/sips -z "$size" "$size" "$SOURCE_ICON" --out "$output_path" >/dev/null
    return
  fi

  if command -v magick >/dev/null 2>&1; then
    magick "$SOURCE_ICON" -resize "${size}x${size}" "$output_path"
    return
  fi

  if command -v convert >/dev/null 2>&1; then
    convert "$SOURCE_ICON" -resize "${size}x${size}" "$output_path"
    return
  fi

  echo "No supported image resize tool found. Install 'sips' (macOS) or ImageMagick." >&2
  exit 1
}

icons=(
  "48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png"
  "72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png"
  "96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
  "144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
  "192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
  "20 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png"
  "40 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png"
  "60 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png"
  "29 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png"
  "58 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png"
  "87 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png"
  "40 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png"
  "80 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png"
  "120 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png"
  "120 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png"
  "180 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png"
  "76 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png"
  "152 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png"
  "167 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png"
  "1024 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
)

for spec in "${icons[@]}"; do
  size="${spec%% *}"
  path="${spec#* }"
  resize_icon "$size" "$PROJECT_ROOT/$path"
done

echo "Launcher icons generated from $SOURCE_ICON"
