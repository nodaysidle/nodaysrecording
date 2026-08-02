#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ICONSET="$ROOT/.build/NoDaysRecord.iconset"
mkdir -p "$ROOT/Resources"
rm -rf "$ICONSET"

swift "$ROOT/Scripts/generate_icon.swift" --output "$ICONSET"
iconutil --convert icns --output "$ROOT/Resources/AppIcon.icns" "$ICONSET"
cp "$ICONSET/icon_512x512@2x.png" "$ROOT/Resources/AppIcon-1024.png"

echo "Created $ROOT/Resources/AppIcon.icns"
