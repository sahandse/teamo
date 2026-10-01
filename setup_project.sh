#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
cp -R lib "$TMP_DIR/lib"
cp -R assets "$TMP_DIR/assets"
cp pubspec.yaml "$TMP_DIR/pubspec.yaml"

flutter create --platforms=android --org ir.teamo --project-name app .teamo_android_host
rm -rf android
cp -R .teamo_android_host/android ./android
rm -rf .teamo_android_host

rm -rf lib assets
cp -R "$TMP_DIR/lib" ./lib
cp -R "$TMP_DIR/assets" ./assets
cp "$TMP_DIR/pubspec.yaml" ./pubspec.yaml
rm -rf "$TMP_DIR"

echo "Android host generated: ir.teamo.app"
