#!/bin/bash

# Terminal macOS DMG Installer Build Script
# Creates a distributable DMG file for macOS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Terminal"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}-macOS"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build/macos/Build/Products/Release"
OUTPUT_DIR="${PROJECT_ROOT}/build/installers/macos"
DMG_TEMP_DIR="${PROJECT_ROOT}/build/dmg_temp"

echo -e "${CYAN}================================${NC}"
echo -e "${CYAN}Terminal macOS DMG Builder${NC}"
echo -e "${CYAN}================================${NC}"
echo ""

# Parse arguments
SKIP_FLUTTER_BUILD=false
CLEAN=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --skip-build) SKIP_FLUTTER_BUILD=true ;;
        --clean) CLEAN=true ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --skip-build    Skip Flutter build step"
            echo "  --clean         Clean previous builds"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

cd "${PROJECT_ROOT}"

# Clean if requested
if [ "$CLEAN" = true ]; then
    echo -e "${YELLOW}[1/5] Cleaning previous builds...${NC}"
    rm -rf build/macos
    rm -rf "${OUTPUT_DIR}"
    rm -rf "${DMG_TEMP_DIR}"
else
    echo -e "${YELLOW}[1/5] Skipping clean (use --clean to clean)${NC}"
fi

# Build Flutter app
if [ "$SKIP_FLUTTER_BUILD" = false ]; then
    echo -e "${YELLOW}[2/5] Building Flutter macOS app...${NC}"
    flutter clean
    flutter pub get
    flutter build macos --release

    if [ $? -ne 0 ]; then
        echo -e "${RED}Flutter build failed!${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}[2/5] Skipping Flutter build${NC}"
fi

# Verify app exists
if [ ! -d "${BUILD_DIR}/${APP_NAME}.app" ]; then
    echo -e "${RED}Error: ${APP_NAME}.app not found at ${BUILD_DIR}${NC}"
    echo -e "${YELLOW}Please build the app first with: flutter build macos --release${NC}"
    exit 1
fi

# Create output directory
echo -e "${YELLOW}[3/5] Creating output directory...${NC}"
mkdir -p "${OUTPUT_DIR}"
rm -rf "${DMG_TEMP_DIR}"
mkdir -p "${DMG_TEMP_DIR}"

# Copy app to temp directory
echo -e "${YELLOW}[4/5] Preparing DMG contents...${NC}"
cp -R "${BUILD_DIR}/${APP_NAME}.app" "${DMG_TEMP_DIR}/"

# Create symbolic link to Applications folder
ln -s /Applications "${DMG_TEMP_DIR}/Applications"

# Create DMG
echo -e "${YELLOW}[5/5] Creating DMG file...${NC}"

# Remove existing DMG if present
rm -f "${OUTPUT_DIR}/${DMG_NAME}.dmg"

# Create DMG using hdiutil
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${DMG_TEMP_DIR}" \
    -ov -format UDZO \
    "${OUTPUT_DIR}/${DMG_NAME}.dmg"

if [ $? -ne 0 ]; then
    echo -e "${RED}DMG creation failed!${NC}"
    exit 1
fi

# Cleanup
rm -rf "${DMG_TEMP_DIR}"

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${CYAN}DMG created at: ${OUTPUT_DIR}/${DMG_NAME}.dmg${NC}"
echo ""

# Show file size
DMG_SIZE=$(du -h "${OUTPUT_DIR}/${DMG_NAME}.dmg" | cut -f1)
echo -e "DMG size: ${DMG_SIZE}"
echo ""
