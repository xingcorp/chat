<#
.SYNOPSIS
    OXII Chat — Windows Build & Distribution Script

.DESCRIPTION
    Builds Flutter Windows app and packages for distribution.
    Supports 3 packaging methods: ZIP, Inno Setup (.exe installer), MSIX.

.PARAMETER Flavor
    Build flavor: staging | production (default: staging)

.PARAMETER Method
    Packaging method: zip | inno | msix | all (default: zip)

.PARAMETER Clean
    Clean build before building

.PARAMETER InnoSetupPath
    Custom path to Inno Setup ISCC.exe

.EXAMPLE
    .\scripts\build_windows.ps1
    # Build + ZIP (staging)

.EXAMPLE
    .\scripts\build_windows.ps1 -Flavor production -Method all
    # Build all 3 formats (production)

.EXAMPLE
    .\scripts\build_windows.ps1 -Method inno
    # Build Inno Setup installer

.EXAMPLE
    .\scripts\build_windows.ps1 -Method msix -Flavor production
    # Build MSIX package (production)
#>

[CmdletBinding()]
param(
    [ValidateSet('staging', 'production')]
    [string]$Flavor = 'staging',

    [ValidateSet('zip', 'inno', 'msix', 'all')]
    [string]$Method = 'zip',

    [switch]$Clean,

    [string]$InnoSetupPath = ''
)

# ─── Strict Mode ──────────────────────────────────────────────────────────────
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─── Constants ────────────────────────────────────────────────────────────────
$APP_NAME        = 'OXII Chat'
$APP_EXE_NAME    = 'oxii_chat.exe'
$SCRIPT_DIR      = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_DIR     = Split-Path -Parent $SCRIPT_DIR
$BUILD_DIR       = Join-Path $PROJECT_DIR 'build\windows\x64\runner\Release'
$OUTPUT_DIR      = Join-Path $PROJECT_DIR 'build\distribution\windows'
$INSTALLER_DIR   = Join-Path $PROJECT_DIR 'installer'
$ISS_FILE        = Join-Path $INSTALLER_DIR 'oxii_chat_setup.iss'

# ─── Logging ──────────────────────────────────────────────────────────────────
function Write-Info    { param([string]$Msg) Write-Host "[INFO]    $Msg" -ForegroundColor Cyan }
function Write-Ok      { param([string]$Msg) Write-Host "[SUCCESS] $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "[WARNING] $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg) Write-Host "[ERROR]   $Msg" -ForegroundColor Red }
function Write-Step    { param([string]$Msg) Write-Host "`n>>> $Msg" -ForegroundColor White -BackgroundColor DarkCyan }

# ─── Utilities ────────────────────────────────────────────────────────────────
function Get-AppVersion {
    $pubspec = Get-Content (Join-Path $PROJECT_DIR 'pubspec.yaml') -Raw
    if ($pubspec -match 'version:\s*(\d+\.\d+\.\d+)') {
        return $Matches[1]
    }
    return '1.0.0'
}

function Get-FileSize {
    param([string]$Path)
    $size = (Get-Item $Path).Length
    if ($size -ge 1GB) { return '{0:N1} GB' -f ($size / 1GB) }
    if ($size -ge 1MB) { return '{0:N1} MB' -f ($size / 1MB) }
    return '{0:N0} KB' -f ($size / 1KB)
}

function Find-InnoSetup {
    # User-specified path
    if ($InnoSetupPath -and (Test-Path $InnoSetupPath)) {
        return $InnoSetupPath
    }

    # Common install locations
    $candidates = @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 5\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 5\ISCC.exe"
    )

    foreach ($path in $candidates) {
        if (Test-Path $path) {
            return $path
        }
    }

    # Try PATH
    $found = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }

    return $null
}

# ─── Header ───────────────────────────────────────────────────────────────────
function Show-Header {
    $version = Get-AppVersion

    Write-Host ''
    Write-Host '╔══════════════════════════════════════════════╗' -ForegroundColor White
    Write-Host '║      OXII Chat — Windows Build Script       ║' -ForegroundColor White
    Write-Host '╠══════════════════════════════════════════════╣' -ForegroundColor White
    Write-Host "║  Version:  $version"                             -ForegroundColor White
    Write-Host "║  Flavor:   $Flavor"                              -ForegroundColor Cyan
    Write-Host "║  Method:   $Method"                              -ForegroundColor Cyan
    Write-Host "║  Clean:    $Clean"                               -ForegroundColor Cyan
    Write-Host '╚══════════════════════════════════════════════╝' -ForegroundColor White
    Write-Host ''
}

# ─── Preflight Checks ────────────────────────────────────────────────────────
function Test-Prerequisites {
    Write-Step 'Preflight Checks'

    # Flutter
    $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
    if (-not $flutterCmd) {
        Write-Err 'Flutter not found. Install Flutter SDK and add to PATH.'
        exit 1
    }
    Write-Info "Flutter: $((flutter --version | Select-Object -First 1))"

    # Visual Studio / Build Tools
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vsWhere) {
        $vsPath = & $vsWhere -latest -property installationPath
        Write-Info "Visual Studio: $vsPath"
    } else {
        Write-Warn 'Visual Studio not detected. Windows build may fail.'
    }

    # Inno Setup (if needed)
    if ($Method -eq 'inno' -or $Method -eq 'all') {
        $iscc = Find-InnoSetup
        if (-not $iscc) {
            Write-Warn 'Inno Setup not found. Inno installer will be skipped.'
            Write-Info 'Download from: https://jrsoftware.org/isinfo.php'
        } else {
            Write-Info "Inno Setup: $iscc"
        }
    }

    Write-Ok 'Preflight checks passed'
}

# ─── Clean ────────────────────────────────────────────────────────────────────
function Invoke-Clean {
    Write-Step 'Cleaning build artifacts'
    Push-Location $PROJECT_DIR
    try {
        flutter clean
        flutter pub get
    } finally {
        Pop-Location
    }
    Write-Ok 'Clean complete'
}

# ─── Build Flutter Windows ───────────────────────────────────────────────────
function Invoke-FlutterBuild {
    Write-Step 'Building Flutter Windows app (release)'
    Push-Location $PROJECT_DIR
    try {
        flutter pub get

        $buildArgs = @('build', 'windows', '--release', "--dart-define=FLAVOR=$Flavor")
        Write-Info "Running: flutter $($buildArgs -join ' ')"

        & flutter @buildArgs
        if ($LASTEXITCODE -ne 0) {
            Write-Err 'Flutter build failed'
            exit 1
        }
    } finally {
        Pop-Location
    }

    # Verify
    $exePath = Join-Path $BUILD_DIR $APP_EXE_NAME
    if (-not (Test-Path $exePath)) {
        Write-Err "Build output not found: $exePath"
        exit 1
    }

    Write-Ok "Build complete: $exePath"
}

# ─── Method 1: ZIP ───────────────────────────────────────────────────────────
function Build-Zip {
    $version = Get-AppVersion
    $zipName = "OxiiChat_v${version}_Windows.zip"
    $zipPath = Join-Path $OUTPUT_DIR $zipName

    Write-Step "Packaging: ZIP ($zipName)"
    New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null

    # Remove old zip
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

    # Create ZIP
    Compress-Archive -Path "$BUILD_DIR\*" -DestinationPath $zipPath -Force

    $size = Get-FileSize $zipPath
    Write-Ok "ZIP created: $zipPath ($size)"
    Write-Info 'Customer: Extract ZIP and run oxii_chat.exe'

    return $zipPath
}

# ─── Method 2: Inno Setup ────────────────────────────────────────────────────
function Build-InnoSetup {
    $iscc = Find-InnoSetup
    if (-not $iscc) {
        Write-Warn 'Inno Setup not installed — skipping'
        Write-Info 'Download: https://jrsoftware.org/isinfo.php'
        return $null
    }

    if (-not (Test-Path $ISS_FILE)) {
        Write-Err "Inno Setup script not found: $ISS_FILE"
        return $null
    }

    $version = Get-AppVersion

    Write-Step "Packaging: Inno Setup Installer"

    # Create output directory
    $innoOutputDir = Join-Path $PROJECT_DIR 'build\installer'
    New-Item -ItemType Directory -Force -Path $innoOutputDir | Out-Null

    # Build installer
    Write-Info "Running: ISCC.exe $ISS_FILE"
    & $iscc $ISS_FILE
    if ($LASTEXITCODE -ne 0) {
        Write-Err 'Inno Setup build failed'
        return $null
    }

    # Find output file
    $setupExe = Get-ChildItem $innoOutputDir -Filter '*.exe' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($setupExe) {
        # Copy to distribution folder
        New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null
        $destPath = Join-Path $OUTPUT_DIR $setupExe.Name
        Copy-Item $setupExe.FullName $destPath -Force

        $size = Get-FileSize $destPath
        Write-Ok "Inno Setup installer: $destPath ($size)"
        Write-Info 'Customer: Run the .exe installer wizard'

        return $destPath
    }

    Write-Warn 'Inno Setup output not found'
    return $null
}

# ─── Method 3: MSIX ──────────────────────────────────────────────────────────
function Build-Msix {
    $version = Get-AppVersion

    Write-Step "Packaging: MSIX"

    Push-Location $PROJECT_DIR
    try {
        Write-Info 'Running: dart run msix:create'
        dart run msix:create
        if ($LASTEXITCODE -ne 0) {
            Write-Err 'MSIX build failed'
            return $null
        }
    } finally {
        Pop-Location
    }

    # Find output MSIX
    $msixFile = Get-ChildItem (Join-Path $PROJECT_DIR 'build') -Filter '*.msix' -Recurse |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1

    if ($msixFile) {
        # Copy to distribution folder
        New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null
        $msixName = "OxiiChat_v${version}_Windows.msix"
        $destPath = Join-Path $OUTPUT_DIR $msixName
        Copy-Item $msixFile.FullName $destPath -Force

        $size = Get-FileSize $destPath
        Write-Ok "MSIX package: $destPath ($size)"
        Write-Info 'Customer: Double-click .msix to install'

        return $destPath
    }

    Write-Warn 'MSIX output not found'
    return $null
}

# ─── Run Packaging ───────────────────────────────────────────────────────────
function Invoke-Packaging {
    $outputs = @()

    switch ($Method) {
        'zip'  { $outputs += Build-Zip }
        'inno' { $outputs += Build-InnoSetup }
        'msix' { $outputs += Build-Msix }
        'all'  {
            $outputs += Build-Zip
            $outputs += Build-InnoSetup
            $outputs += Build-Msix
        }
    }

    return $outputs | Where-Object { $_ -ne $null }
}

# ─── Summary ──────────────────────────────────────────────────────────────────
function Show-Summary {
    param([string[]]$OutputFiles)

    $version = Get-AppVersion

    Write-Host ''
    Write-Host '╔══════════════════════════════════════════════╗' -ForegroundColor Green
    Write-Host '║            Build Complete!                   ║' -ForegroundColor Green
    Write-Host '╠══════════════════════════════════════════════╣' -ForegroundColor Green
    Write-Host "║  App:     $APP_NAME v$version"                   -ForegroundColor Green
    Write-Host "║  Flavor:  $Flavor"                               -ForegroundColor Green
    Write-Host '╠══════════════════════════════════════════════╣' -ForegroundColor Green
    Write-Host '║  Output files:'                                  -ForegroundColor Green

    if ($OutputFiles -and $OutputFiles.Count -gt 0) {
        foreach ($file in $OutputFiles) {
            if ($file -and (Test-Path $file)) {
                $size = Get-FileSize $file
                $name = Split-Path $file -Leaf
                Write-Host "║    $name ($size)" -ForegroundColor White
            }
        }
    } else {
        $exePath = Join-Path $BUILD_DIR $APP_EXE_NAME
        Write-Host "║    $exePath" -ForegroundColor White
    }

    Write-Host '╠══════════════════════════════════════════════╣' -ForegroundColor Green
    Write-Host '║  Distribution folder:'                           -ForegroundColor Green
    Write-Host "║    $OUTPUT_DIR"                                  -ForegroundColor White
    Write-Host '╚══════════════════════════════════════════════╝' -ForegroundColor Green
    Write-Host ''

    # Open output folder
    if (Test-Path $OUTPUT_DIR) {
        Write-Info 'Opening output folder...'
        Start-Process explorer.exe $OUTPUT_DIR
    }
}

# ─── Main ─────────────────────────────────────────────────────────────────────
function Main {
    Show-Header
    Test-Prerequisites

    if ($Clean) {
        Invoke-Clean
    }

    Invoke-FlutterBuild

    $outputs = Invoke-Packaging

    Show-Summary -OutputFiles $outputs
}

# Run
Main
