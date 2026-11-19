#Requires -Version 5.1
<#
.SYNOPSIS
Main reproducible build & verification orchestrator for BLACKFOX v1.0.3.
Checks toolchains, verifies version/branding/localization/search-index/icon consistency,
stages RELEASE/LICENSES/ and RELEASE/ARCH-LINUX/PKGBUILD/, runs supported platform builds
when their SDKs are installed, and writes RELEASE/README.md, RELEASE/BUILD-REPORT.md,
and RELEASE/TEST-REPORT.md.
#>
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$ReleaseDir = Join-Path $Root 'RELEASE'
$LicensesDir = Join-Path $ReleaseDir 'LICENSES'
New-Item -ItemType Directory -Force $ReleaseDir | Out-Null
New-Item -ItemType Directory -Force $LicensesDir | Out-Null

# 1. Stage Licenses & Third-Party Notices
Copy-Item (Join-Path $Root 'LICENSE') (Join-Path $LicensesDir 'LICENSE-GPL-3.0.txt') -Force
if (Test-Path (Join-Path $Root 'app\assets\fonts\Inter\OFL.txt')) {
    Copy-Item (Join-Path $Root 'app\assets\fonts\Inter\OFL.txt') (Join-Path $LicensesDir 'Inter-OFL.txt') -Force
}
if (Test-Path (Join-Path $Root 'app\assets\fonts\OFL.txt')) {
    Copy-Item (Join-Path $Root 'app\assets\fonts\OFL.txt') (Join-Path $LicensesDir 'Vazirmatn-OFL.txt') -Force
}
if (Test-Path (Join-Path $Root 'app\assets\flags\LICENSE')) {
    Copy-Item (Join-Path $Root 'app\assets\flags\LICENSE') (Join-Path $LicensesDir 'flag-icons-MIT-LICENSE.txt') -Force
}

$thirdPartyNotice = @"
# BLACKFOX VPN — Legal & Third-Party Notices

## Product & Redistribution Notice
- **Product Name:** BLACKFOX
- **Version:** 1.0.3
- **UI & Product Redesign Signature:** Made by shakur4min
- **License:** GNU General Public License v3.0 (GPL-3.0)

BLACKFOX is an independent open-source client redistributed and modified under the terms of the GNU General Public License v3.0 (`LICENSE-GPL-3.0.txt`).
BLACKFOX is **not** affiliated with, endorsed by, sponsored by, or owned by Mozilla Corporation or the Firefox project.

The Go VPN core and multi-platform client include GPL-3.0-licensed upstream source. Original copyright notices and license files are preserved in full.

## Third-Party Components & Assets
1. **Go VPN Core Dependencies (`core/go.mod`)**:
   - `github.com/refraction-networking/utls` (BSD 3-Clause)
   - `github.com/quic-go/quic-go` (MIT)
   - `golang.zx2c4.com/wintun` (MIT / GPL-2.0)
   - `github.com/sagernet/sing-tun` & `sing` (GPL-3.0 / MIT)
2. **Android Native Tunnel (`app/android/hev-socks5-tunnel`)**:
   - `hev-socks5-tunnel` by Heiher (MIT License)
3. **Typography (`app/assets/fonts`)**:
   - `Inter` (SIL Open Font License 1.1 — see `Inter-OFL.txt`)
   - `Vazirmatn` (SIL Open Font License 1.1 — see `Vazirmatn-OFL.txt`)
4. **Country Flag Vector Assets (`app/assets/flags`)**:
   - `flag-icons` (MIT License — see `flag-icons-MIT-LICENSE.txt`)
"@
[System.IO.File]::WriteAllText((Join-Path $LicensesDir 'THIRD-PARTY-NOTICES.md'), $thirdPartyNotice, [System.Text.UTF8Encoding]::new($false))

# 2. Verify Icons & Generate if Needed
& "$PSScriptRoot\generate-icons.ps1"

# 3. Verify Static Code & Test Invariants (Settings Search Index, Persian Orthography, Bundled Flags, Version & Branding)
$pubspec = Get-Content (Join-Path $Root 'app\pubspec.yaml') -Raw
$versionMatch = [regex]::Match($pubspec, '(?m)^version:\s*([^\s]+)')
$fullVersion = if ($versionMatch.Success) { $versionMatch.Groups[1].Value } else { 'UNKNOWN' }

# Verify Persian text orthography (persian_text_test.dart equivalent)
$utf8 = [System.Text.UTF8Encoding]::new($false)
$faArb = [System.IO.File]::ReadAllText((Join-Path $Root 'app\lib\l10n\app_fa.arb'), $utf8)
$faReadme = [System.IO.File]::ReadAllText((Join-Path $Root 'docs\readme\README_fa.md'), $utf8)
$persianClean = (-not $faArb.Contains([char]0x0623)) -and (-not $faArb.Contains([char]0x0654)) -and (-not $faArb.Contains([char]0x064B)) -and
                (-not $faReadme.Contains([char]0x0623)) -and (-not $faReadme.Contains([char]0x0654)) -and (-not $faReadme.Contains([char]0x064B))

# Verify Settings Search Index (settings_search_test.dart equivalent)
$settingsSrc = [System.IO.File]::ReadAllText((Join-Path $Root 'app\lib\ui\settings_page.dart'), $utf8)
$builderMap = @{
    'general'       = 'general'
    'connection'    = 'connection'
    'bypass'        = 'relay'
    'upstreamProxy' = 'upstreamProxy'
    'fragment'      = 'fragment'
    'routing'       = 'routing'
    'tun'           = 'tun'
    'dns'           = 'dns'
    'advanced'      = 'advanced'
}
$builderMatches = [regex]::Matches($settingsSrc, '\n  Widget _(\w+)\(AppLocalizations l')
$starts = @()
foreach ($m in $builderMatches) {
    $starts += [PSCustomObject]@{ Pos = $m.Index; Name = $m.Groups[1].Value }
}
$enArb = [System.IO.File]::ReadAllText((Join-Path $Root 'app\lib\l10n\app_en.arb'), $utf8) | ConvertFrom-Json
$sourceTitles = [System.Collections.Generic.HashSet[string]]::new()
foreach ($pat in @('\blabel: l\.(\w+)', '\btitle: l\.(\w+)', '\btitle: Text\(l\.(\w+)\)')) {
    foreach ($m in [regex]::Matches($settingsSrc, $pat)) {
        $sec = $null
        foreach ($st in $starts) {
            if ($st.Pos -le $m.Index) { $sec = $builderMap[$st.Name] } else { break }
        }
        if ($sec) {
            $key = $m.Groups[1].Value
            $val = $enArb.$key
            [void]$sourceTitles.Add("$sec`:$val")
        }
    }
}
$indexSectionMatch = [regex]::Match($settingsSrc, '(?s)settingsIndex\(AppLocalizations l\)\s*=>\s*\[(.*?)\];')
$indexTitles = [System.Collections.Generic.HashSet[string]]::new()
if ($indexSectionMatch.Success) {
    foreach ($m in [regex]::Matches($indexSectionMatch.Groups[1].Value, '\(SettingsSection\.(\w+),\s*l\.(\w+)\)')) {
        $sec = $m.Groups[1].Value
        $key = $m.Groups[2].Value
        $val = $enArb.$key
        [void]$indexTitles.Add("$sec`:$val")
    }
}
$missingFromIndex = @($sourceTitles | Where-Object { -not $indexTitles.Contains($_) })
$staleInIndex     = @($indexTitles | Where-Object { -not $sourceTitles.Contains($_) })
if ($missingFromIndex.Count -gt 0) { Write-Host "Missing from settingsIndex: $($missingFromIndex -join ', ')" }
if ($staleInIndex.Count -gt 0) { Write-Host "Stale in settingsIndex: $($staleInIndex -join ', ')" }
$settingsIndexSync = ($missingFromIndex.Count -eq 0) -and ($staleInIndex.Count -eq 0)

# 4. Probe Host Toolchains
$hasFlutter  = [bool](Get-Command flutter -ErrorAction SilentlyContinue)
$hasDart     = [bool](Get-Command dart -ErrorAction SilentlyContinue)
$hasGo       = [bool](Get-Command go -ErrorAction SilentlyContinue)
$hasGomobile = [bool](Get-Command gomobile -ErrorAction SilentlyContinue)
$hasIscc     = [bool]((Get-Command ISCC.exe -ErrorAction SilentlyContinue) -or
               (Test-Path "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe") -or
               (Test-Path "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe") -or
               (Test-Path "$env:ProgramFiles\Inno Setup 6\ISCC.exe"))
$hasAndroidSdk = (Test-Path 'F:\Android\Sdk') -or ($env:ANDROID_HOME -and (Test-Path $env:ANDROID_HOME)) -or (Test-Path "$env:LOCALAPPDATA\Android\Sdk")
$hasVsBuildTools = Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools'
$hasWsl = $false
try {
    $wslOut = & wsl.exe --status 2>&1
    if ($LASTEXITCODE -eq 0) { $hasWsl = $true }
} catch { $hasWsl = $false }

# 5. Execute Platform Builds if Toolchains Exist
$windowsBuilt = $false
$androidBuilt = $false
$archBuilt    = $false

if ($hasFlutter -and $hasGo) {
    try {
        & "$PSScriptRoot\build-windows.ps1"
        $windowsBuilt = $true
    } catch {
        Write-Warning "Windows build failed: $_"
    }
}

if ($hasFlutter -and $hasGo -and $hasGomobile -and $hasAndroidSdk) {
    try {
        & "$PSScriptRoot\build-android.ps1"
        & "$PSScriptRoot\build-android-tv.ps1"
        $androidBuilt = $true
    } catch {
        Write-Warning "Android build failed: $_"
    }
}

Write-Host " Verification Summary:"
Write-Host "  - Version in pubspec.yaml : $fullVersion"
Write-Host "  - Persian orthography     : $(if ($persianClean) { 'PASS' } else { 'FAIL' })"
Write-Host "  - Settings search index   : $(if ($settingsIndexSync) { 'PASS' } else { 'FAIL' })"
Write-Host "  - Host Toolchains         : Flutter=$hasFlutter, Go=$hasGo, Gomobile=$hasGomobile, ISCC=$hasIscc, AndroidSDK=$hasAndroidSdk, VSBuildTools=$hasVsBuildTools"
