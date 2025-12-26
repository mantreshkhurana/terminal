#!/bin/bash

# Terminal Linux .rpm Package Build Script
# Creates an RPM package for Fedora/RHEL/CentOS based distributions
# Requires: rpm-build package (dnf install rpm-build)

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
RELEASE="1"
ARCH="x86_64"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build/linux/x64/release/bundle"
OUTPUT_DIR="${PROJECT_ROOT}/build/installers/linux"
RPM_BUILD_DIR="${PROJECT_ROOT}/build/rpmbuild"

echo -e "${CYAN}================================${NC}"
echo -e "${CYAN}Terminal Linux .rpm Builder${NC}"
echo -e "${CYAN}================================${NC}"
echo ""

# Check for rpmbuild
if ! command -v rpmbuild &> /dev/null; then
    echo -e "${RED}rpmbuild not found!${NC}"
    echo -e "${YELLOW}Please install rpm-build:${NC}"
    echo -e "  Fedora/RHEL: sudo dnf install rpm-build"
    echo -e "  Ubuntu/Debian: sudo apt install rpm"
    exit 1
fi

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
    rm -rf "${RPM_BUILD_DIR}"
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

# Create RPM build directory structure
echo -e "${YELLOW}[3/5] Creating RPM build structure...${NC}"
rm -rf "${RPM_BUILD_DIR}"
mkdir -p "${RPM_BUILD_DIR}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Create tarball for source
TARBALL_DIR="${RPM_BUILD_DIR}/SOURCES/${PACKAGE_NAME}-${VERSION}"
mkdir -p "${TARBALL_DIR}"
cp -r "${BUILD_DIR}"/* "${TARBALL_DIR}/"
cp "${SCRIPT_DIR}/terminal.desktop" "${TARBALL_DIR}/"
if [ -f "${PROJECT_ROOT}/assets/images/icon.png" ]; then
    cp "${PROJECT_ROOT}/assets/images/icon.png" "${TARBALL_DIR}/terminal.png"
elif [ -f "${PROJECT_ROOT}/snap/gui/app_icon.png" ]; then
    cp "${PROJECT_ROOT}/snap/gui/app_icon.png" "${TARBALL_DIR}/terminal.png"
fi

cd "${RPM_BUILD_DIR}/SOURCES"
tar -czvf "${PACKAGE_NAME}-${VERSION}.tar.gz" "${PACKAGE_NAME}-${VERSION}"
rm -rf "${PACKAGE_NAME}-${VERSION}"
cd "${PROJECT_ROOT}"

# Create spec file
echo -e "${YELLOW}[4/5] Creating RPM spec file...${NC}"
cat > "${RPM_BUILD_DIR}/SPECS/${PACKAGE_NAME}.spec" << EOF
Name:           ${PACKAGE_NAME}
Version:        ${VERSION}
Release:        ${RELEASE}%{?dist}
Summary:        A simple yet customizable terminal emulator

License:        MIT
URL:            https://github.com/mantreshkhurana/terminal
Source0:        %{name}-%{version}.tar.gz

BuildArch:      ${ARCH}
Requires:       gtk3
Requires:       libblkid
Requires:       xz-libs

%description
Terminal is a modern, customizable terminal emulator built with Flutter.
It supports multiple shells including bash and zsh, and provides
a clean, intuitive interface for command-line operations.

%prep
%setup -q

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/lib/${APP_NAME_LOWER}
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps

# Copy application files
cp -r * %{buildroot}/usr/lib/${APP_NAME_LOWER}/

# Create launcher script
cat > %{buildroot}/usr/bin/${APP_NAME_LOWER} << 'LAUNCHER'
#!/bin/bash
export LD_LIBRARY_PATH="/usr/lib/${APP_NAME_LOWER}/lib:\${LD_LIBRARY_PATH}"
exec /usr/lib/${APP_NAME_LOWER}/terminal "\$@"
LAUNCHER
chmod 755 %{buildroot}/usr/bin/${APP_NAME_LOWER}

# Install desktop file
install -m 644 terminal.desktop %{buildroot}/usr/share/applications/
sed -i "s|Exec=terminal|Exec=/usr/bin/${APP_NAME_LOWER}|g" %{buildroot}/usr/share/applications/terminal.desktop

# Install icon
install -m 644 terminal.png %{buildroot}/usr/share/icons/hicolor/256x256/apps/terminal.png

%files
/usr/lib/${APP_NAME_LOWER}
/usr/bin/${APP_NAME_LOWER}
/usr/share/applications/terminal.desktop
/usr/share/icons/hicolor/256x256/apps/terminal.png

%post
/usr/bin/update-desktop-database &> /dev/null || :
/usr/bin/gtk-update-icon-cache /usr/share/icons/hicolor &> /dev/null || :

%postun
/usr/bin/update-desktop-database &> /dev/null || :
/usr/bin/gtk-update-icon-cache /usr/share/icons/hicolor &> /dev/null || :

%changelog
* $(date "+%a %b %d %Y") Mantresh Khurana <mantreshkhurana@gmail.com> - ${VERSION}-${RELEASE}
- Initial package release
EOF

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Build RPM
echo -e "${YELLOW}[5/5] Building .rpm package...${NC}"
rpmbuild -bb "${RPM_BUILD_DIR}/SPECS/${PACKAGE_NAME}.spec" \
    --define "_topdir ${RPM_BUILD_DIR}" \
    --define "_rpmdir ${OUTPUT_DIR}"

if [ $? -ne 0 ]; then
    echo -e "${RED}.rpm package creation failed!${NC}"
    exit 1
fi

# Move RPM to output directory
mv "${OUTPUT_DIR}/${ARCH}/"*.rpm "${OUTPUT_DIR}/" 2>/dev/null || true
rmdir "${OUTPUT_DIR}/${ARCH}" 2>/dev/null || true

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${CYAN}.rpm package created in: ${OUTPUT_DIR}${NC}"
echo ""

# Show file
ls -lh "${OUTPUT_DIR}"/*.rpm 2>/dev/null || echo "RPM file location may vary"
echo ""
echo -e "${YELLOW}To install the package:${NC}"
echo -e "  sudo dnf install ${PACKAGE_NAME}-${VERSION}-${RELEASE}.${ARCH}.rpm"
echo -e "  # Or on older systems:"
echo -e "  sudo yum install ${PACKAGE_NAME}-${VERSION}-${RELEASE}.${ARCH}.rpm"
echo ""
