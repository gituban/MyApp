#!/bin/bash
set -e

mkdir -p obj bin

echo "[1] Compile Java..."
javac -d obj -source 1.8 -target 1.8 \
  -bootclasspath $ANDROID_HOME/platforms/android-33/android.jar \
  $(find src -name "*.java")

echo "[2] Convert to DEX..."
$ANDROID_HOME/build-tools/33.0.2/dx --dex --output=classes.dex obj

echo "[3] Package APK..."
aapt package -f -m -F bin/MyApp.unsigned.apk \
  -M AndroidManifest.xml -S res -I $ANDROID_HOME/platforms/android-33/android.jar

echo "[4] Add classes.dex..."
aapt add bin/MyApp.unsigned.apk classes.dex

echo "[5] Sign APK..."
apksigner sign --ks mykey.keystore --ks-pass pass:123456 \
  --out bin/MyApp.apk bin/MyApp.unsigned.apk

echo "✅ Done! APK: bin/MyApp.apk"
