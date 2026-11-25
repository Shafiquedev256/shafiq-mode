#!/usr/bin/env bash
# Generates the android/ platform folder and applies Shafiq mode overrides.
# Run once locally, and in CI before building. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/.."

flutter create . --platforms=android --org com.shafiq --project-name shafiq_mode --no-overwrite
rm -f test/widget_test.dart   # generated sample test references a non-existent MyApp

cp platform/android/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
KT=android/app/src/main/kotlin/com/shafiq/shafiq_mode
mkdir -p "$KT"
cp platform/android/MainActivity.kt "$KT/MainActivity.kt"

# audio plugins need minSdk 24+
for f in android/app/build.gradle android/app/build.gradle.kts; do
  [ -f "$f" ] && sed -i -E 's/minSdk(Version)? ?=? ?flutter\.minSdkVersion/minSdk = 24/' "$f"
done
echo "Android platform ready."
