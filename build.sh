#!/bin/bash
set -e

APP_NAME="MyApp"
PKG_NAME="com.example.myapp"
BUILD_DIR=$(pwd)
RES_DIR="$BUILD_DIR/res"
SRC_DIR="$BUILD_DIR/src"
BIN_DIR="$BUILD_DIR/bin"
OBJ_DIR="$BUILD_DIR/obj"
ANDROID_JAR="$ANDROID_HOME/platforms/android-34/android.jar"

# pilih versi build-tools terbaru yang tersedia
BUILD_TOOLS=$(ls -d $ANDROID_HOME/build-tools/* | sort -r | head -n 1)

mkdir -p "$BIN_DIR" "$OBJ_DIR"

echo "[1] Compiling Java source..."
find "$SRC_DIR" -name "*.java" > sources.txt
javac -d "$OBJ_DIR" -source 1.8 -target 1.8 -bootclasspath "$ANDROID_JAR" @"sources.txt"

echo "[2] Converting to DEX..."
if [ -x "$BUILD_TOOLS/dx" ]; then
    echo "→ Using dx"
    "$BUILD_TOOLS/dx" --dex --output="$BIN_DIR/classes.dex" "$OBJ_DIR"
elif [ -f "$BUILD_TOOLS/lib/d8.jar" ]; then
    echo "→ Using d8.jar"
    java -cp "$BUILD_TOOLS/lib/d8.jar" com.android.tools.r8.D8 \
      --output "$BIN_DIR" "$OBJ_DIR"
else
    echo "❌ Neither dx nor d8 found!"
    exit 1
fi

echo "[3] Packaging APK..."
"$BUILD_TOOLS/aapt" package -f -m -F "$BIN_DIR/$APP_NAME.unsigned.apk" \
  -M "$BUILD_DIR/AndroidManifest.xml" \
  -S "$RES_DIR" \
  -I "$ANDROID_JAR"

echo "[4] Adding classes.dex..."
cd "$BIN_DIR"
zip -u "$APP_NAME.unsigned.apk" classes.dex
cd "$BUILD_DIR"

echo "[5] Signing APK..."
KEYSTORE="$BUILD_DIR/mykey.keystore"
if [ ! -f "$KEYSTORE" ]; then
  echo "Generating keystore..."
  keytool -genkey -v -keystore "$KEYSTORE" -storepass 123456 \
    -alias mykey -keypass 123456 -keyalg RSA -keysize 2048 \
    -validity 10000 -dname "CN=Termux,O=MyOrg,C=ID"
fi

"$BUILD_TOOLS/apksigner" sign \
  --ks "$KEYSTORE" --ks-pass pass:123456 \
  --out "$BIN_DIR/$APP_NAME.apk" "$BIN_DIR/$APP_NAME.unsigned.apk"

echo "✅ Build complete! Output: $BIN_DIR/$APP_NAME.apk"
