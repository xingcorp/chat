<#
.SYNOPSIS
    Bump OXII Chat version and rebuild installer for distribution.

.DESCRIPTION
    Automates the full release flow:
    1. Bump version in pubspec.yaml (+ msix_config)
    2. Build Flutter Windows release
    3. Package with chosen method (zip / inno / msix / all)

.PARAMETER Version
    New version string, e.g. "1.2.0"

.PARAMETER Bump
    Auto-bump type: major | minor | patch (alternative to -Version)

.PARAMETER Method
    Packaging method: zip | inno | msix | all (default: all)

.PARAMETER Flavor
    Build flavor: staging | production (default: production)

.PARAMETER SkipBuild
    Skip Flutter build (use existing build output)

.EXAMPLE
    .\scripts\release_windows.ps1 -Bump patch
    # 1.0.0 → 1.0.1, build all formats

.EXAMPLE
    .\scripts\release_windows.ps1 -Version 2.0.0 -Method inno
    # Set version to 2.0.0, build Inno installer only

.EXAMPLE
    .\scripts\release_windows.ps1 -Bump minor -Flavor staging
    # 1.0.0 → 1.1.0, staging build
#>

[CmdletBinding()]
param(
    [string]$Version = '',

    [ValidateSet('major', 'minor', 'patch')]
    [string]$Bump = '',

    [ValidateSet('zip', 'inno', 'msix', 'all')]
    [string]$Method = 'all',

    [ValidateSet('staging', 'production')]
    [string]$Flavor = 'production',

    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$SCRIPT_DIR  = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_DIR = Split-Path -Parent $SCRIPT_DIR
$PUBSPEC     = Join-Path $PROJECT_DIR 'pubspec.yaml'

# ─── Logging ──────────────────────────────────────────────────────────────────
function Write-Info    { param([string]$Msg) Write-Host "[INFO]    $Msg" -ForegroundColor Cyan }
function Write-Ok      { param([string]$Msg) Write-Host "[SUCCESS] $Msg" -ForegroundColor Green }
function Write-Err     { param([string]$Msg) Write-Host "[ERROR]   $Msg" -ForegroundColor Red }
function Write-Step    { param([string]$Msg) Write-Host "`n>>> $Msg" -ForegroundColor White -BackgroundColor DarkCyan }

# ─── Read Current Version ────────────────────────────────────────────────────
function Get-CurrentVersion {
    $content = Get-Content $PUBSPEC -Raw
    if ($content -match 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
        return @{
            Major = [int]$Matches[1]
            Minor = [int]$Matches[2]
            Patch = [int]$Matches[3]
            Build = [int]$Matches[4]
            Full  = "$($Matches[1]).$($Matches[2]).$($Matches[3])"
            Raw   = "$($Matches[1]).$($Matches[2]).$($Matches[3])+$($Matches[4])"
        }
    }
    throw "Could not parse version from pubspec.yaml"
}

# ─── Calculate New Version ───────────────────────────────────────────────────
function Get-NewVersion {
    $current = Get-CurrentVersion

    if ($Version) {
        # Explicit version provided
        if ($Version -notmatch '^\d+\.\d+\.\d+$') {
            throw "Invalid version format: $Version (expected: X.Y.Z)"
        }
        $parts = $Version.Split('.')
        return @{
            Major = [int]$parts[0]
            Minor = [int]$parts[1]
            Patch = [int]$parts[2]
            Build = $current.Build + 1
            Full  = $Version
        }
    }

    if ($Bump) {
        $major = $current.Major
        $minor = $current.Minor
        $patch = $current.Patch
        $build = $current.Build + 1

        switch ($Bump) {
            'major' { $major++; $minor = 0; $patch = 0 }
            'minor' { $minor++; $patch = 0 }
            'patch' { $patch++ }
        }

        return @{
            Major = $major
            Minor = $minor
            Patch = $patch
            Build = $build
            Full  = "$major.$minor.$patch"
        }
    }

    throw "Specify either -Version '1.2.0' or -Bump patch|minor|major"
}

# ─── Update pubspec.yaml ─────────────────────────────────────────────────────
function Update-PubspecVersion {
    param($NewVer)

    Write-Step "Updating version in pubspec.yaml"

    $content = Get-Content $PUBSPEC -Raw
    $newVersionString = "$($NewVer.Full)+$($NewVer.Build)"

    # Update main version
    $content = $content -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $newVersionString"

    # Update msix_config version (X.Y.Z.0 format)
    $msixVersion = "$($NewVer.Major).$($NewVer.Minor).$($NewVer.Patch).0"
    $content = $content -replace 'msix_version:\s*\d+\.\d+\.\d+\.\d+', "msix_version: $msixVersion"

    Set-Content $PUBSPEC $content -NoNewline

    Write-Ok "Version: $newVersionString (MSIX: $msixVersion)"
}

# ─── Build & Package ─────────────────────────────────────────────────────────
function Invoke-BuildAndPackage {
    $buildScript = Join-Path $SCRIPT_DIR 'build_windows.ps1'

    if (-not (Test-Path $buildScript)) {
        throw "build_windows.ps1 not found at: $buildScript"
    }

    $params = @{
        Flavor = $Flavor
        Method = $Method
    }

    if (-not $SkipBuild) {
        Write-Info "Building and packaging..."
    } else {
        Write-Info "Skipping build, packaging only..."
    }

    & $buildScript @params
}

# ─── Main ─────────────────────────────────────────────────────────────────────
function Main {
    $current = Get-CurrentVersion
    $new     = Get-NewVersion

    Write-Host ''
    Write-Host '╔══════════════════════════════════════════════╗' -ForegroundColor White
    Write-Host '║       OXII Chat — Release Script             ║' -ForegroundColor White
    Write-Host '╠══════════════════════════════════════════════╣' -ForegroundColor White
    Write-Host "║  Current: $($current.Raw)"                       -ForegroundColor Yellow
    Write-Host "║  New:     $($new.Full)+$($new.Build)"            -ForegroundColor Green
    Write-Host "║  Flavor:  $Flavor"                               -ForegroundColor Cyan
    Write-Host "║  Method:  $Method"                               -ForegroundColor Cyan
    Write-Host '╚══════════════════════════════════════════════╝' -ForegroundColor White
    Write-Host ''

    # Confirm
    $confirm = Read-Host "Proceed with version bump $($current.Full) -> $($new.Full)? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Info 'Cancelled.'
        return
    }

    # 1. Bump version
    Update-PubspecVersion -NewVer $new

    # 2. Build & Package
    Invoke-BuildAndPackage

    # 3. Summary
    Write-Host ''
    Write-Host '════════════════════════════════════════════════' -ForegroundColor Green
    Write-Host "  Release $($new.Full) ready!"                     -ForegroundColor Green
    Write-Host '════════════════════════════════════════════════' -ForegroundColor Green
    Write-Host ''
    Write-Host '  Next steps:' -ForegroundColor White
    Write-Host "  1. Test the installer from build\distribution\windows\" -ForegroundColor White
    Write-Host "  2. Send to customer" -ForegroundColor White
    Write-Host "  3. Git commit & tag:" -ForegroundColor White
    Write-Host "     git add pubspec.yaml" -ForegroundColor DarkGray
    Write-Host "     git commit -m 'release: v$($new.Full)'" -ForegroundColor DarkGray
    Write-Host "     git tag v$($new.Full)" -ForegroundColor DarkGray
    Write-Host ''
}

Main
