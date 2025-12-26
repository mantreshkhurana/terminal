#!/bin/bash

# Terminal Linux .deb Package Build Script
# Creates a Debian package for Debian/Ubuntu based distributions

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
PACKAGE_NAME="terminal-emulator"
VERSION="1.0.0"
ARCH="amd64"
MAINTAINER="Mantresh Khurana <mantreshkhurana@gmail.com>"
DESCRIPTION="A simple yet customizable terminal emulator"
HOMEPAGE="https://github.com/mantreshkhurana/terminal"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build/linux/x64/release/bundle"
OUTPUT_DIR="${PROJECT_ROOT}/build/installers/linux"
DEB_DIR="${PROJECT_ROOT}/build/deb/${PACKAGE_NAME}_${VERSION}_${ARCH}"

echo -e "${CYAN}================================${NC}"
echo -e "${CYAN}Terminal Linux .deb Builder${NC}"
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
    rm -rf build/linux
    rm -rf "${OUTPUT_DIR}"
    rm -rf "${PROJECT_ROOT}/build/deb"
else
    echo -e "${YELLOW}[1/5] Skipping clean (use --clean to clean)${NC}"
fi

# Build Flutter app
if [ "$SKIP_FLUTTER_BUILD" = false ]; then
    echo -e "${YELLOW}[2/5] Building Flutter Linux app...${NC}"
    flutter clean
    flutter pub get
    flutter build linux --release

    if [ $? -ne 0 ]; then
        echo -e "${RED}Flutter build failed!${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}[2/5] Skipping Flutter build${NC}"
fi

# Verify build exists
if [ ! -d "${BUILD_DIR}" ]; then
    echo -e "${RED}Error: Build directory not found at ${BUILD_DIR}${NC}"
    echo -e "${YELLOW}Please build the app first with: flutter build linux --release${NC}"
    exit 1
fi

# Create .deb directory structure
echo -e "${YELLOW}[3/5] Creating .deb package structure...${NC}"
rm -rf "${DEB_DIR}"
mkdir -p "${DEB_DIR}/DEBIAN"
mkdir -p "${DEB_DIR}/usr/bin"
mkdir -p "${DEB_DIR}/usr/lib/${APP_NAME_LOWER}"
mkdir -p "${DEB_DIR}/usr/share/applications"
mkdir -p "${DEB_DIR}/usr/share/icons/hicolor/256x256/apps"
mkdir -p "${DEB_DIR}/usr/share/doc/${PACKAGE_NAME}"

# Create control file
echo -e "${YELLOW}[4/5] Creating package metadata...${NC}"
cat > "${DEB_DIR}/DEBIAN/control" << EOF
Package: ${PACKAGE_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Depends: libgtk-3-0, libblkid1, liblzma5
Maintainer: ${MAINTAINER}
Homepage: ${HOMEPAGE}
Description: ${DESCRIPTION}
 Terminal is a modern, customizable terminal emulator built with Flutter.
 It supports multiple shells including bash and zsh, and provides
 a clean, intuitive interface for command-line operations.
EOF

# Create postinst script
cat > "${DEB_DIR}/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e
# Update desktop database
if [ -x /usr/bin/update-desktop-database ]; then
    update-desktop-database -q /usr/share/applications || true
fi
# Update icon cache
if [ -x /usr/bin/gtk-update-icon-cache ]; then
    gtk-update-icon-cache -q /usr/share/icons/hicolor || true
fi
exit 0
EOF
chmod 755 "${DEB_DIR}/DEBIAN/postinst"

# Create postrm script
cat > "${DEB_DIR}/DEBIAN/postrm" << 'EOF'
#!/bin/bash
set -e
# Update desktop database
if [ -x /usr/bin/update-desktop-database ]; then
    update-desktop-database -q /usr/share/applications || true
fi
# Update icon cache
if [ -x /usr/bin/gtk-update-icon-cache ]; then
    gtk-update-icon-cache -q /usr/share/icons/hicolor || true
fi
exit 0
EOF
chmod 755 "${DEB_DIR}/DEBIAN/postrm"

# Copy application files
cp -r "${BUILD_DIR}"/* "${DEB_DIR}/usr/lib/${APP_NAME_LOWER}/"

# Create launcher script
cat > "${DEB_DIR}/usr/bin/${APP_NAME_LOWER}" << EOF
#!/bin/bash
export LD_LIBRARY_PATH="/usr/lib/${APP_NAME_LOWER}/lib:\${LD_LIBRARY_PATH}"
exec /usr/lib/${APP_NAME_LOWER}/terminal "\$@"
EOF
chmod 755 "${DEB_DIR}/usr/bin/${APP_NAME_LOWER}"

# Copy desktop file
cp "${SCRIPT_DIR}/terminal.desktop" "${DEB_DIR}/usr/share/applications/"
# Update Exec path in desktop file
sed -i "s|Exec=terminal|Exec=/usr/bin/${APP_NAME_LOWER}|g" "${DEB_DIR}/usr/share/applications/terminal.desktop"

# Copy icon
if [ -f "${PROJECT_ROOT}/assets/images/icon.png" ]; then
    cp "${PROJECT_ROOT}/assets/images/icon.png" "${DEB_DIR}/usr/share/icons/hicolor/256x256/apps/${APP_NAME_LOWER}.png"
elif [ -f "${PROJECT_ROOT}/snap/gui/app_icon.png" ]; then
    cp "${PROJECT_ROOT}/snap/gui/app_icon.png" "${DEB_DIR}/usr/share/icons/hicolor/256x256/apps/${APP_NAME_LOWER}.png"
fi

# Create copyright file
cat > "${DEB_DIR}/usr/share/doc/${PACKAGE_NAME}/copyright" << EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${APP_NAME}
Upstream-Contact: ${MAINTAINER}
Source: ${HOMEPAGE}

Files: *
Copyright: 2024 Mantresh Khurana
License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
EOF

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Build .deb package
echo -e "${YELLOW}[5/5] Building .deb package...${NC}"
dpkg-deb --build "${DEB_DIR}" "${OUTPUT_DIR}/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"

if [ $? -ne 0 ]; then
    echo -e "${RED}.deb package creation failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${CYAN}.deb package created at: ${OUTPUT_DIR}/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb${NC}"
echo ""

# Show file size
DEB_SIZE=$(du -h "${OUTPUT_DIR}/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb" | cut -f1)
echo -e ".deb package size: ${DEB_SIZE}"
echo ""
echo -e "${YELLOW}To install the package:${NC}"
echo -e "  sudo dpkg -i ${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
echo -e "  # Or with apt (handles dependencies):"
echo -e "  sudo apt install ./${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
echo ""
