# Terminal Installers

This directory contains scripts and configurations for building distributable installers for Terminal on Windows, macOS, and Linux.

## Quick Start

### Build for Current Platform

```bash
# Build all installer formats for your current platform
./installers/build_all.sh

# Build specific format
./installers/build_all.sh --format appimage  # Linux only
./installers/build_all.sh --format deb       # Linux only
./installers/build_all.sh --format dmg       # macOS only
```

### Output Location

All built installers are placed in:

```txt
build/installers/
├── windows/
│   └── Terminal-1.0.0-Setup.exe
├── macos/
│   └── Terminal-1.0.0-macOS.dmg
└── linux/
    ├── Terminal-1.0.0-x86_64.AppImage
    ├── terminal-emulator_1.0.0_amd64.deb
    └── terminal-emulator-1.0.0-1.x86_64.rpm
```

---

## Platform-Specific Instructions

### Windows

**Requirements:**

- Windows 10 or later
- Flutter SDK
- [Inno Setup 6](https://jrsoftware.org/isinfo.php) (free installer creator)

**Build Steps:**

```powershell
# Open PowerShell and navigate to project root
cd path\to\terminal

# Run the installer build script
powershell -ExecutionPolicy Bypass -File .\installers\windows\build_installer.ps1

or

# From Command Prompt
cd path\to\terminal
powershell -ExecutionPolicy Bypass -File .\installers\windows\build_installer


# Options:
#   -Clean            Clean previous builds first
#   -SkipFlutterBuild Skip the Flutter build step (use existing build)
```

**Output:** `build\installers\windows\Terminal-1.0.0-Setup.exe`

The Windows installer:

- Creates Start Menu shortcuts
- Optional desktop shortcut
- Proper uninstaller with Add/Remove Programs entry
- Supports per-user or all-users installation

---

### macOS

**Requirements:**

- macOS 10.15 (Catalina) or later
- Flutter SDK
- Xcode Command Line Tools
- (Optional) `create-dmg` for professional DMG styling: `brew install create-dmg`

**Build Steps:**

```bash
# Standard DMG (uses hdiutil)
./installers/macos/build_dmg.sh

# Professional DMG with custom styling (uses create-dmg)
./installers/macos/create_dmg_with_background.sh

# Options:
#   --skip-build    Skip Flutter build step
#   --clean         Clean previous builds
```

**Output:** `build/installers/macos/Terminal-1.0.0-macOS.dmg`

The DMG:

- Drag-and-drop installation to Applications
- Proper volume icon
- Clean, professional appearance

**Note:** For distribution outside the Mac App Store, you may want to:

1. Sign the app with a Developer ID certificate
2. Notarize the app with Apple

---

### Linux

**Requirements:**

- Linux (Ubuntu 20.04+ or equivalent)
- Flutter SDK
- GTK3 development libraries: `sudo apt install libgtk-3-dev`
- For .deb: `dpkg-deb` (usually pre-installed)
- For .rpm: `rpm-build` (`sudo dnf install rpm-build` on Fedora)
- For AppImage: Internet connection (downloads appimagetool automatically)

**Build Steps:**

```bash
# Build all formats
./installers/build_all.sh --format all

# Or build individually:

# AppImage (portable, runs on most Linux distros)
./installers/linux/build_appimage.sh

# Debian package (.deb for Ubuntu, Debian, etc.)
./installers/linux/build_deb.sh

# RPM package (for Fedora, RHEL, CentOS, etc.)
./installers/linux/build_rpm.sh

# Options for all scripts:
#   --skip-build    Skip Flutter build step
#   --clean         Clean previous builds
```

**Output:**

- `build/installers/linux/Terminal-1.0.0-x86_64.AppImage`
- `build/installers/linux/terminal-emulator_1.0.0_amd64.deb`
- `build/installers/linux/terminal-emulator-1.0.0-1.x86_64.rpm`

**Installing:**

```bash
# AppImage (portable - no installation required)
chmod +x Terminal-1.0.0-x86_64.AppImage
./Terminal-1.0.0-x86_64.AppImage

# Debian/Ubuntu
sudo apt install ./terminal-emulator_1.0.0_amd64.deb

# Fedora/RHEL
sudo dnf install terminal-emulator-1.0.0-1.x86_64.rpm
```

---

## Directory Structure

```txt
installers/
├── README.md              # This file
├── build_all.sh           # Unified build script
├── windows/
│   ├── installer.iss      # Inno Setup configuration
│   └── build_installer.ps1 # PowerShell build script
├── macos/
│   ├── build_dmg.sh       # Standard DMG builder
│   └── create_dmg_with_background.sh  # Professional DMG builder
└── linux/
    ├── terminal.desktop   # Desktop entry file
    ├── build_appimage.sh  # AppImage builder
    ├── build_deb.sh       # Debian package builder
    └── build_rpm.sh       # RPM package builder
```

---

## Versioning

The version number is defined in `pubspec.yaml`. To update the version:

1. Edit `pubspec.yaml`:

   ```yaml
   version: 1.0.1+2  # semantic version + build number
   ```

2. Update installer configs:
   - Windows: Edit `VERSION` in `installers/windows/installer.iss`
   - macOS/Linux: The scripts read from pubspec.yaml or use hardcoded values

---

## Troubleshooting

### Windows: "Inno Setup not found"

Install Inno Setup 6 from <https://jrsoftware.org/isinfo.php>

### macOS: "create-dmg not found"

```bash
brew install create-dmg
# Or use the standard build_dmg.sh which uses hdiutil
```

### Linux: "appimagetool failed"

Ensure you have FUSE installed:

```bash
sudo apt install fuse libfuse2  # Ubuntu/Debian
sudo dnf install fuse fuse-libs  # Fedora
```

### Linux: ".deb build fails"

Ensure dpkg-dev is installed:

```bash
sudo apt install dpkg-dev
```

### General: "Flutter build failed"

```bash
flutter doctor  # Check Flutter installation
flutter clean   # Clean build cache
flutter pub get # Update dependencies
```

---

## Code Signing & Notarization

### Windows Signing

For production distribution, consider signing the installer with an Authenticode certificate.

### macOS Signing

For distribution outside the App Store:

1. Sign with Developer ID: `codesign --deep --force --sign "Developer ID Application: Your Name" Terminal.app`
2. Notarize with Apple: `xcrun notarytool submit Terminal.dmg --apple-id your@email.com --password app-specific-password --team-id TEAMID`

### Linux Signing

AppImages can be signed with GPG for verification.

---

## License

Copyright © 2024 Mantresh Khurana. All rights reserved.
