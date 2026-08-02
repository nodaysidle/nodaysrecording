#!/usr/bin/env bash
set -euo pipefail

CONF=${1:-release}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

APP_NAME="NoDaysRecord"
source "$ROOT/version.env"

DIST_DIR="$ROOT/dist"
STAGING_DIR="$ROOT/.dmg-staging"
DMG_NAME="${APP_NAME}-${MARKETING_VERSION}.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"

cleanup() {
    rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

"$ROOT/Scripts/package_app.sh" "$CONF"

rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR" "$DIST_DIR"
ditto "$ROOT/${APP_NAME}.app" "$STAGING_DIR/${APP_NAME}.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
    -volname "NoDays Record ${MARKETING_VERSION}" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

test -s "$DMG_PATH"
echo "Created $DMG_PATH"
