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

APP_GRADLE="android/app/build.gradle.kts"
if [[ -f "$APP_GRADLE" ]]; then
  python3 - "$APP_GRADLE" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
if 'isCoreLibraryDesugaringEnabled = true' not in s:
    s = s.replace('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', 1)
if 'desugar_jdk_libs' not in s:
    s += '\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
p.write_text(s)
PY
fi

rm -rf lib assets
cp -R "$TMP_DIR/lib" ./lib
cp -R "$TMP_DIR/assets" ./assets
cp "$TMP_DIR/pubspec.yaml" ./pubspec.yaml
rm -rf "$TMP_DIR"

echo "Android host generated with desugaring: ir.teamo.app"
