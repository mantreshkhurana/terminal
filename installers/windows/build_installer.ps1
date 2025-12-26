# Terminal Windows Installer Build Script
# Requires: Inno Setup installed and in PATH

param(
    [switch]$SkipFlutterBuild,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Terminal Windows Installer Build" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to project root
Set-Location $ProjectRoot

# Clean if requested
if ($Clean) {
    Write-Host "[1/4] Cleaning previous builds..." -ForegroundColor Yellow
    if (Test-Path "build\windows") {
        Remove-Item -Recurse -Force "build\windows"
    }
    if (Test-Path "build\installers\windows") {
        Remove-Item -Recurse -Force "build\installers\windows"
    }
} else {
    Write-Host "[1/4] Skipping clean (use -Clean to clean)" -ForegroundColor Gray
}

# Build Flutter app
if (-not $SkipFlutterBuild) {
    Write-Host "[2/4] Building Flutter Windows app..." -ForegroundColor Yellow
    flutter clean
    flutter pub get
    flutter build windows --release

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Flutter build failed!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[2/4] Skipping Flutter build (use without -SkipFlutterBuild to build)" -ForegroundColor Gray
}

# Create output directory
Write-Host "[3/4] Creating installer output directory..." -ForegroundColor Yellow
$InstallerOutputDir = "build\installers\windows"
if (-not (Test-Path $InstallerOutputDir)) {
    New-Item -ItemType Directory -Path $InstallerOutputDir -Force | Out-Null
}

# Build installer with Inno Setup
Write-Host "[4/4] Building installer with Inno Setup..." -ForegroundColor Yellow

# Try to find Inno Setup
$InnoSetupPath = $null
$PossiblePaths = @(
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles}\Inno Setup 6\ISCC.exe"
)

foreach ($Path in $PossiblePaths) {
    if (Test-Path $Path) {
        $InnoSetupPath = $Path
        break
    }
}

# Also check if ISCC is in PATH
if (-not $InnoSetupPath) {
    try {
        $InnoSetupPath = (Get-Command "ISCC.exe" -ErrorAction SilentlyContinue).Source
    } catch {
        # Command not found
    }
}

if (-not $InnoSetupPath) {
    Write-Host ""
    Write-Host "Inno Setup not found!" -ForegroundColor Red
    Write-Host "Please install Inno Setup 6 from: https://jrsoftware.org/isinfo.php" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "After installation, run this script again." -ForegroundColor Yellow
    exit 1
}

Write-Host "Using Inno Setup: $InnoSetupPath" -ForegroundColor Gray

# Run Inno Setup compiler
& $InnoSetupPath "installers\windows\installer.iss"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Inno Setup compilation failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installer created at: $ProjectRoot\$InstallerOutputDir" -ForegroundColor Cyan
Write-Host ""
