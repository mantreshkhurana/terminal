#!/bin/bash

# Terminal - Unified Installer Build Script
# Builds installers for the current platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════╗"
echo "║     Terminal Installer Builder           ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# Detect platform
detect_platform() {
    case "$(uname -s)" in
        Linux*)     PLATFORM="linux" ;;
        Darwin*)    PLATFORM="macos" ;;
        CYGWIN*|MINGW*|MSYS*) PLATFORM="windows" ;;
        *)          PLATFORM="unknown" ;;
    esac
    echo "${PLATFORM}"
}

PLATFORM=$(detect_platform)
echo -e "${CYAN}Detected platform: ${BOLD}${PLATFORM}${NC}"
echo ""

# Show help
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --platform <name>   Build for specific platform (linux, macos, windows)"
    echo "  --format <format>   Build specific format:"
    echo "                        Linux: appimage, deb, rpm, all (default: all)"
    echo "                        macOS: dmg, dmg-pro (default: dmg)"
    echo "                        Windows: inno (default: inno)"
    echo "  --skip-build        Skip Flutter build step"
    echo "  --clean             Clean previous builds first"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Build all formats for current platform"
    echo "  $0 --format appimage        # Build only AppImage on Linux"
    echo "  $0 --format deb --clean     # Clean and build .deb package"
    echo "  $0 --skip-build             # Build installer without rebuilding Flutter app"
    echo ""
}

# Parse arguments
FORMAT="all"
SKIP_BUILD=""
CLEAN=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --platform) PLATFORM="$2"; shift ;;
        --format) FORMAT="$2"; shift ;;
        --skip-build) SKIP_BUILD="--skip-build" ;;
        --clean) CLEAN="--clean" ;;
        -h|--help) show_help; exit 0 ;;
        *) echo -e "${RED}Unknown parameter: $1${NC}"; show_help; exit 1 ;;
    esac
    shift
done

cd "${PROJECT_ROOT}"

# Build for Linux
build_linux() {
    echo -e "${YELLOW}Building Linux installers...${NC}"
    echo ""

    case "${FORMAT}" in
        appimage)
            echo -e "${CYAN}Building AppImage...${NC}"
            "${SCRIPT_DIR}/linux/build_appimage.sh" ${SKIP_BUILD} ${CLEAN}
            ;;
        deb)
            echo -e "${CYAN}Building .deb package...${NC}"
            "${SCRIPT_DIR}/linux/build_deb.sh" ${SKIP_BUILD} ${CLEAN}
            ;;
        rpm)
            echo -e "${CYAN}Building .rpm package...${NC}"
            "${SCRIPT_DIR}/linux/build_rpm.sh" ${SKIP_BUILD} ${CLEAN}
            ;;
        all)
            echo -e "${CYAN}Building all Linux formats...${NC}"
            echo ""
            echo -e "${YELLOW}[1/3] Building AppImage...${NC}"
            "${SCRIPT_DIR}/linux/build_appimage.sh" ${CLEAN}
            echo ""
            echo -e "${YELLOW}[2/3] Building .deb package...${NC}"
            "${SCRIPT_DIR}/linux/build_deb.sh" --skip-build
            echo ""
            echo -e "${YELLOW}[3/3] Building .rpm package...${NC}"
            "${SCRIPT_DIR}/linux/build_rpm.sh" --skip-build
            ;;
        *)
            echo -e "${RED}Unknown format: ${FORMAT}${NC}"
            echo "Valid formats for Linux: appimage, deb, rpm, all"
            exit 1
            ;;
    esac
}

# Build for macOS
build_macos() {
    echo -e "${YELLOW}Building macOS installer...${NC}"
    echo ""

    case "${FORMAT}" in
        dmg|all)
            echo -e "${CYAN}Building DMG...${NC}"
            "${SCRIPT_DIR}/macos/build_dmg.sh" ${SKIP_BUILD} ${CLEAN}
            ;;
        dmg-pro)
            echo -e "${CYAN}Building DMG with custom styling (requires create-dmg)...${NC}"
            "${SCRIPT_DIR}/macos/create_dmg_with_background.sh" ${SKIP_BUILD}
            ;;
        *)
            echo -e "${RED}Unknown format: ${FORMAT}${NC}"
            echo "Valid formats for macOS: dmg, dmg-pro, all"
            exit 1
            ;;
    esac
}

# Build for Windows
build_windows() {
    echo -e "${YELLOW}Building Windows installer...${NC}"
    echo ""
    echo -e "${RED}Note: Windows builds must be run on Windows.${NC}"
    echo -e "Please run the following PowerShell script on Windows:"
    echo -e "${CYAN}  .\\installers\\windows\\build_installer.ps1${NC}"
    echo ""
    echo -e "Requirements:"
    echo -e "  - Windows 10 or later"
    echo -e "  - Flutter SDK installed"
    echo -e "  - Inno Setup 6 installed (https://jrsoftware.org/isinfo.php)"
    echo ""
}

# Main build logic
case "${PLATFORM}" in
    linux)
        build_linux
        ;;
    macos)
        build_macos
        ;;
    windows)
        build_windows
        ;;
    *)
        echo -e "${RED}Unsupported platform: ${PLATFORM}${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}${BOLD}================================${NC}"
echo -e "${GREEN}${BOLD}All requested builds complete!${NC}"
echo -e "${GREEN}${BOLD}================================${NC}"
echo ""
echo -e "Installers are located in: ${CYAN}${PROJECT_ROOT}/build/installers/${NC}"
echo ""
