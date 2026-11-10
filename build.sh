#!/bin/bash
# Manual (no Gradle) build of the nearme-statistics-stub APK.
# Requires: JDK 17 on PATH (or JAVA_HOME set) and an Android SDK with
# platform android-34 and build-tools 34.0.0.
#   export JAVA_HOME=/path/to/jdk17
#   export ANDROID_HOME=/path/to/android-sdk
set -euo pipefail
cd "$(dirname "$0")"

: "${JAVA_HOME:?set JAVA_HOME to a JDK 17 install}"
: "${ANDROID_HOME:?set ANDROID_HOME to the Android SDK root}"
BT="$ANDROID_HOME/build-tools/34.0.0"
PLATFORM="$ANDROID_HOME/platforms/android-34/android.jar"
export PATH="$JAVA_HOME/bin:$PATH"

BUILD_DIR="$(pwd)/build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/gen" "$BUILD_DIR/classes"

# 1. Compile resources
"$BT/aapt2" compile --dir app/src/main/res -o "$BUILD_DIR/compiled.zip"

# 2. Link resources + manifest -> unsigned APK skeleton, also generate R.java
"$BT/aapt2" link -I "$PLATFORM" \
  --manifest app/src/main/AndroidManifest.xml \
  --java "$BUILD_DIR/gen" \
  --auto-add-overlay \
  --version-code 7 --version-name 1.6 \
  --min-sdk-version 29 --target-sdk-version 34 \
  -o "$BUILD_DIR/app-unsigned.apk" \
  "$BUILD_DIR/compiled.zip"

# 3. Compile Java (our sources + generated R.java)
find app/src/main/java "$BUILD_DIR/gen" -name '*.java' > "$BUILD_DIR/sources.txt"
javac -encoding UTF-8 -source 17 -target 17 -cp "$PLATFORM" -d "$BUILD_DIR/classes" @"$BUILD_DIR/sources.txt"

# 4. DEX the classes (pass .class files explicitly; d8 8.2 rejects a bare dir)
# shellcheck disable=SC2046
"$BT/d8" --lib "$PLATFORM" --output "$BUILD_DIR" $(find "$BUILD_DIR/classes" -name '*.class')

# 5. Add classes.dex to the APK, align, sign (debug keystore)
cp "$BUILD_DIR/app-unsigned.apk" "$BUILD_DIR/app-aligned.apk"
(
  cd "$BUILD_DIR"
  zip -q app-aligned.apk classes.dex
  # zipalign must run after adding the dex and before signing
)
"$BT/zipalign" -f 4 "$BUILD_DIR/app-aligned.apk" "$BUILD_DIR/app-debug.apk"

if [ ! -f debug.keystore ]; then
  keytool -genkeypair -keystore debug.keystore -alias androiddebugkey \
    -storepass android -keypass android \
    -dname "CN=Android Debug,O=Android,C=US" \
    -keyalg RSA -keysize 2048 -validity 10000 -noprompt
fi
"$BT/apksigner" sign --ks debug.keystore --ks-key-alias androiddebugkey \
  --ks-pass pass:android --key-pass pass:android \
  --out app-debug.apk "$BUILD_DIR/app-debug.apk"

# 6. Verify
"$BT/apksigner" verify --verbose app-debug.apk
"$BT/aapt2" dump badging app-debug.apk | head -20
echo "Built: $(pwd)/app-debug.apk"
ls -lh app-debug.apk
