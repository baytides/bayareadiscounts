#!/bin/bash
set -e

# Bay Navigator Local Release Script
# Usage: ./scripts/release.sh [version]
# Example: ./scripts/release.sh 0.1.003

VERSION=${1:-"0.1.0"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"

echo "🚀 Bay Navigator Release v$VERSION"
echo "=================================="
echo ""

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

cd "$PROJECT_DIR"

# Function to build and export
build_platform() {
    local PLATFORM=$1
    local SCHEME=$2
    local DESTINATION=$3
    local ARCHIVE_PATH="$BUILD_DIR/BayNavigator-$PLATFORM.xcarchive"
    local EXPORT_PATH="$BUILD_DIR/$PLATFORM"

    echo ""
    echo "📱 Building $PLATFORM..."
    echo "------------------------"

    # Archive
    xcodebuild -project BayNavigator.xcodeproj \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        archive \
        MARKETING_VERSION="$VERSION" \
        CURRENT_PROJECT_VERSION="$VERSION" \
        | grep -E "(error:|warning:|BUILD|ARCHIVE)" || true

    if [ ! -d "$ARCHIVE_PATH" ]; then
        echo "❌ Archive failed for $PLATFORM"
        return 1
    fi

    echo "✅ Archive complete: $ARCHIVE_PATH"

    # Export for App Store
    echo "📦 Exporting $PLATFORM for App Store..."

    # Create export options plist
    local EXPORT_OPTIONS="$BUILD_DIR/ExportOptions-$PLATFORM.plist"
    cat > "$EXPORT_OPTIONS" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>C5U8Z5536K</string>
    <key>uploadSymbols</key>
    <true/>
    <key>manageAppVersionAndBuildNumber</key>
    <true/>
</dict>
</plist>
EOF

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS" \
        -exportPath "$EXPORT_PATH" \
        | grep -E "(error:|warning:|EXPORT)" || true

    echo "✅ Export complete: $EXPORT_PATH"
}

# Function to upload to TestFlight
upload_platform() {
    local PLATFORM=$1
    local EXPORT_PATH="$BUILD_DIR/$PLATFORM"

    echo ""
    echo "☁️  Uploading $PLATFORM to TestFlight..."
    echo "---------------------------------------"

    # Find the .ipa or .pkg file
    local APP_FILE=$(find "$EXPORT_PATH" -name "*.ipa" -o -name "*.pkg" 2>/dev/null | head -1)

    if [ -z "$APP_FILE" ]; then
        echo "⚠️  No uploadable file found for $PLATFORM, skipping upload"
        return 0
    fi

    # Upload using xcrun notarytool for macOS or altool for iOS
    xcrun altool --upload-app \
        --type ios \
        --file "$APP_FILE" \
        --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
        --apiIssuer "$APP_STORE_CONNECT_API_ISSUER_ID" \
        2>&1 || echo "⚠️  Upload may have failed - check App Store Connect"

    echo "✅ Upload complete for $PLATFORM"
}

echo ""
echo "Which platforms would you like to build?"
echo "  1) iOS only"
echo "  2) macOS only"
echo "  3) visionOS only"
echo "  4) All platforms"
echo "  5) iOS + macOS (skip visionOS)"
echo ""
read -p "Select option [4]: " OPTION
OPTION=${OPTION:-4}

case $OPTION in
    1)
        build_platform "iOS" "Bay Navigator (iOS)" "generic/platform=iOS"
        ;;
    2)
        build_platform "macOS" "Bay Navigator (macOS)" "generic/platform=macOS"
        ;;
    3)
        build_platform "visionOS" "Bay Navigator (visionOS)" "generic/platform=visionOS"
        ;;
    4)
        build_platform "iOS" "Bay Navigator (iOS)" "generic/platform=iOS"
        build_platform "macOS" "Bay Navigator (macOS)" "generic/platform=macOS"
        build_platform "visionOS" "Bay Navigator (visionOS)" "generic/platform=visionOS"
        ;;
    5)
        build_platform "iOS" "Bay Navigator (iOS)" "generic/platform=iOS"
        build_platform "macOS" "Bay Navigator (macOS)" "generic/platform=macOS"
        ;;
esac

echo ""
echo "=================================="
echo "🎉 Build complete!"
echo ""
echo "Archives are in: $BUILD_DIR"
echo ""
echo "Next steps:"
echo "  1. Open Xcode Organizer (Window → Organizer)"
echo "  2. Select each archive and click 'Distribute App'"
echo "  3. Choose 'App Store Connect' → 'Upload'"
echo ""
echo "Or run with --upload flag to upload automatically (requires API key setup)"
