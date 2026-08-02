#!/usr/bin/env bash
set -euo pipefail

CONF=${1:-release}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

APP_NAME="NoDaysRecord"
BUNDLE_ID="com.nodaysidle.nodaysrecord"
MACOS_MIN_VERSION="15.0"
SIGNING_MODE=${SIGNING_MODE:-adhoc}

source "$ROOT/version.env"

"$ROOT/Scripts/build_icon.sh"
swift build -c "$CONF" --arch "$(uname -m)"

APP="$ROOT/${APP_NAME}.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

BUILD_PATH=".build/$(uname -m)-apple-macosx/$CONF/$APP_NAME"
if [[ ! -f "$BUILD_PATH" ]]; then
  BUILD_PATH=".build/$CONF/$APP_NAME"
fi
cp "$BUILD_PATH" "$APP/Contents/MacOS/$APP_NAME"
chmod +x "$APP/Contents/MacOS/$APP_NAME"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>NoDaysRecord</string>
    <key>CFBundleDisplayName</key><string>NoDays Record</string>
    <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
    <key>CFBundleExecutable</key><string>${APP_NAME}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleShortVersionString</key><string>${MARKETING_VERSION}</string>
    <key>CFBundleVersion</key><string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key><string>${MACOS_MIN_VERSION}</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSScreenCaptureUsageDescription</key><string>NoDays Record needs screen access to capture the screen, a window, or a selected area.</string>
    <key>NSMicrophoneUsageDescription</key><string>NoDays Record uses the microphone only when you enable microphone audio for a recording.</string>
    <key>NSCameraUsageDescription</key><string>NoDays Record uses the camera only when you enable a face-cam overlay for a recording.</string>
    <key>NSSpeechRecognitionUsageDescription</key><string>NoDays Record can create captions locally from a recording you choose.</string>
</dict>
</plist>
PLIST

cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"

echo "Created $APP"
