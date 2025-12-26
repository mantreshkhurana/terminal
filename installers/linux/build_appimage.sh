#!/bin/bash

# Terminal Linux AppImage Build Script
# Creates a portable AppImage that runs on most Linux distributions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Terminal"
APP_NAME_LOWER="terminal"
VERSION="1.0.0"
ARCH="x86_64"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build/linux/x64/release/bundle"
OUTPUT_DIR="${PROJECT_ROOT}/build/installers/linux"
APPDIR="${PROJECT_ROOT}/build/appimage/${APP_NAME}.AppDir"

echo -e "${CYAN}================================${NC}"
echo -e "${CYAN}Terminal Linux AppImage Builder${NC}"
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
    echo -e "${YELLOW}[1/6] Cleaning previous builds...${NC}"
    rm -rf build/linux
    rm -rf "${OUTPUT_DIR}"
    rm -rf "${PROJECT_ROOT}/build/appimage"
else
    echo -e "${YELLOW}[1/6] Skipping clean (use --clean to clean)${NC}"
fi

# Build Flutter app
if [ "$SKIP_FLUTTER_BUILD" = false ]; then
    echo -e "${YELLOW}[2/6] Building Flutter Linux app...${NC}"
    flutter clean
    flutter pub get
    flutter build linux --release

    if [ $? -ne 0 ]; then
        echo -e "${RED}Flutter build failed!${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}[2/6] Skipping Flutter build${NC}"
fi

# Verify build exists
if [ ! -d "${BUILD_DIR}" ]; then
    echo -e "${RED}Error: Build directory not found at ${BUILD_DIR}${NC}"
    echo -e "${YELLOW}Please build the app first with: flutter build linux --release${NC}"
    exit 1
fi

# Create AppDir structure
echo -e "${YELLOW}[3/6] Creating AppDir structure...${NC}"
rm -rf "${APPDIR}"
mkdir -p "${APPDIR}/usr/bin"
mkdir -p "${APPDIR}/usr/lib"
mkdir -p "${APPDIR}/usr/share/applications"
mkdir -p "${APPDIR}/usr/share/icons/hicolor/256x256/apps"
mkdir -p "${APPDIR}/usr/share/metainfo"

# Copy Flutter bundle
echo -e "${YELLOW}[4/6] Copying application files...${NC}"
cp -r "${BUILD_DIR}"/* "${APPDIR}/usr/bin/"

# Copy desktop file
cp "${SCRIPT_DIR}/terminal.desktop" "${APPDIR}/usr/share/applications/"
cp "${SCRIPT_DIR}/terminal.desktop" "${APPDIR}/${APP_NAME_LOWER}.desktop"

# Copy icon
if [ -f "${PROJECT_ROOT}/assets/images/icon.png" ]; then
    cp "${PROJECT_ROOT}/assets/images/icon.png" "${APPDIR}/usr/share/icons/hicolor/256x256/apps/${APP_NAME_LOWER}.png"
    cp "${PROJECT_ROOT}/assets/images/icon.png" "${APPDIR}/${APP_NAME_LOWER}.png"
elif [ -f "${PROJECT_ROOT}/snap/gui/app_icon.png" ]; then
    cp "${PROJECT_ROOT}/snap/gui/app_icon.png" "${APPDIR}/usr/share/icons/hicolor/256x256/apps/${APP_NAME_LOWER}.png"
    cp "${PROJECT_ROOT}/snap/gui/app_icon.png" "${APPDIR}/${APP_NAME_LOWER}.png"
fi

# Create AppRun script
cat > "${APPDIR}/AppRun" << 'EOF'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/bin/lib:${HERE}/usr/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/terminal" "$@"
EOF
chmod +x "${APPDIR}/AppRun"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Download appimagetool if not present
echo -e "${YELLOW}[5/6] Preparing AppImage tool...${NC}"
APPIMAGETOOL="${PROJECT_ROOT}/build/appimagetool-x86_64.AppImage"
if [ ! -f "${APPIMAGETOOL}" ]; then
    echo "Downloading appimagetool..."
    curl -L -o "${APPIMAGETOOL}" "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "${APPIMAGETOOL}"
fi

# Build AppImage
echo -e "${YELLOW}[6/6] Building AppImage...${NC}"
ARCH=x86_64 "${APPIMAGETOOL}" "${APPDIR}" "${OUTPUT_DIR}/${APP_NAME}-${VERSION}-${ARCH}.AppImage"

if [ $? -ne 0 ]; then
    echo -e "${RED}AppImage creation failed!${NC}"
    exit 1
fi

# Make AppImage executable
chmod +x "${OUTPUT_DIR}/${APP_NAME}-${VERSION}-${ARCH}.AppImage"

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${CYAN}AppImage created at: ${OUTPUT_DIR}/${APP_NAME}-${VERSION}-${ARCH}.AppImage${NC}"
echo ""

# Show file size
APPIMAGE_SIZE=$(du -h "${OUTPUT_DIR}/${APP_NAME}-${VERSION}-${ARCH}.AppImage" | cut -f1)
echo -e "AppImage size: ${APPIMAGE_SIZE}"
echo ""
echo -e "${YELLOW}To run the AppImage:${NC}"
echo -e "  chmod +x ${APP_NAME}-${VERSION}-${ARCH}.AppImage"
echo -e "  ./${APP_NAME}-${VERSION}-${ARCH}.AppImage"
echo ""
