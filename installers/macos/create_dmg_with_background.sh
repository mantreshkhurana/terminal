#!/bin/bash

# Terminal macOS DMG Installer with Custom Background
# Creates a professional-looking DMG with custom background and icon positioning
# Requires: create-dmg (brew install create-dmg)

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

echo -e "${CYAN}================================${NC}"
echo -e "${CYAN}Terminal macOS DMG Builder (Pro)${NC}"
echo -e "${CYAN}================================${NC}"
echo ""

# Check for create-dmg
if ! command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}create-dmg not found. Installing via Homebrew...${NC}"
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}Homebrew not found. Please install Homebrew first:${NC}"
        echo -e "${CYAN}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
        exit 1
    fi
    brew install create-dmg
fi

# Parse arguments
SKIP_FLUTTER_BUILD=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --skip-build) SKIP_FLUTTER_BUILD=true ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --skip-build    Skip Flutter build step"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

cd "${PROJECT_ROOT}"

# Build Flutter app
if [ "$SKIP_FLUTTER_BUILD" = false ]; then
    echo -e "${YELLOW}[1/3] Building Flutter macOS app...${NC}"
    flutter clean
    flutter pub get
    flutter build macos --release

    if [ $? -ne 0 ]; then
        echo -e "${RED}Flutter build failed!${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}[1/3] Skipping Flutter build${NC}"
fi

# Verify app exists
if [ ! -d "${BUILD_DIR}/${APP_NAME}.app" ]; then
    echo -e "${RED}Error: ${APP_NAME}.app not found at ${BUILD_DIR}${NC}"
    echo -e "${YELLOW}Please build the app first with: flutter build macos --release${NC}"
    exit 1
fi

# Create output directory
echo -e "${YELLOW}[2/3] Creating output directory...${NC}"
mkdir -p "${OUTPUT_DIR}"

# Remove existing DMG if present
rm -f "${OUTPUT_DIR}/${DMG_NAME}.dmg"

# Create DMG with create-dmg
echo -e "${YELLOW}[3/3] Creating DMG with create-dmg...${NC}"

create-dmg \
    --volname "${APP_NAME}" \
    --volicon "${PROJECT_ROOT}/assets/images/icon.png" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "${APP_NAME}.app" 150 185 \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link 450 185 \
    --no-internet-enable \
    "${OUTPUT_DIR}/${DMG_NAME}.dmg" \
    "${BUILD_DIR}/${APP_NAME}.app"

# create-dmg returns 2 if everything succeeded but code signing failed (which is expected for unsigned apps)
if [ $? -ne 0 ] && [ $? -ne 2 ]; then
    echo -e "${RED}DMG creation failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${CYAN}DMG created at: ${OUTPUT_DIR}/${DMG_NAME}.dmg${NC}"
echo ""

# Show file size
if [ -f "${OUTPUT_DIR}/${DMG_NAME}.dmg" ]; then
    DMG_SIZE=$(du -h "${OUTPUT_DIR}/${DMG_NAME}.dmg" | cut -f1)
    echo -e "DMG size: ${DMG_SIZE}"
fi
echo ""
