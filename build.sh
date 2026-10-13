#!/bin/sh
# Builds Heater.app and Heater.dmg into ./build
set -e
cd "$(dirname "$0")"
APP=build/Heater.app
rm -rf build && mkdir -p "$APP/Contents/MacOS"

swiftc -O -parse-as-library -swift-version 5 Heater.swift -o "$APP/Contents/MacOS/Heater"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Heater</string>
  <key>CFBundleIdentifier</key><string>local.heater</string>
  <key>CFBundleExecutable</key><string>Heater</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
</dict></plist>
EOF

codesign --force --sign - "$APP"

mkdir -p build/dmg && cp -R "$APP" build/dmg/ && ln -s /Applications build/dmg/Applications
hdiutil create -volname Heater -srcfolder build/dmg -ov -format UDZO build/Heater.dmg
rm -rf build/dmg
echo "done: build/Heater.dmg"
