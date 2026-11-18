# Builds the Windows x64 BLACKFOX application, Go Core, TUN service, Portable
# bundle, and Inno Setup installers into RELEASE\WINDOWS\x64\ and dist\.
param([string]$AppVersion)
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$match = Select-String -Path "$root\app\pubspec.yaml" -Pattern '^version:\s*(\d+\.\d+\.\d+)'
if (-not $match) { throw 'No version in app\pubspec.yaml' }
$version = $match.Matches[0].Groups[1].Value
if ($AppVersion) { $version = $AppVersion }

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter SDK (flutter) is not installed or not in PATH.'
}
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    throw 'Go toolchain (go) is not installed or not in PATH.'
}

$iscc = (Get-Command ISCC.exe -ErrorAction SilentlyContinue).Source
if (-not $iscc) {
    $iscc = @(
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
}

$relWin = Join-Path $root 'RELEASE\WINDOWS\x64'
$portableOut = Join-Path $relWin 'Portable'

Push-Location "$root\app"
try {
    foreach ($stale in "build\flutter_assets", "build\windows\x64\runner\Release\data\flutter_assets") {
        if (Test-Path $stale) { Remove-Item -LiteralPath $stale -Recurse -Force }
    }
    flutter pub get --offline
    if ($LASTEXITCODE -ne 0) { flutter pub get }
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
    flutter build windows --release --no-pub --dart-define=APP_VERSION=$version
    if ($LASTEXITCODE -ne 0) { throw 'flutter build windows failed' }
} finally { Pop-Location }

New-Item -ItemType Directory -Force $portableOut | Out-Null
Copy-Item "$root\app\build\windows\x64\runner\Release\*" $portableOut -Recurse -Force
if (Test-Path "$portableOut\arman-vpn.exe") {
    Copy-Item "$portableOut\arman-vpn.exe" "$portableOut\BLACKFOX.exe" -Force
    Remove-Item "$portableOut\arman-vpn.exe" -Force
}

$public = & "$PSScriptRoot\signing-key.ps1"
Push-Location "$root\core"
try {
    $env:APP_VERSION = $version
    go generate ./cmd/arman-vpn-core
    if ($LASTEXITCODE -ne 0) { throw 'go generate failed' }
    $ldflags = "-s -w -X github.com/armanlife/arman-vpn-client/core/internal/version.Current=$version"
    if ($public) { $ldflags += " -X github.com/armanlife/arman-vpn-client/core/internal/signing.Key=$public" }
    New-Item -ItemType Directory -Force "$portableOut\core" | Out-Null
    go build -trimpath -ldflags $ldflags -o "$portableOut\core\arman-vpn-core.exe" ./cmd/arman-vpn-core
    if ($LASTEXITCODE -ne 0) { throw 'go build failed' }
    & "$PSScriptRoot\build-windows-tun.ps1" -Version $version -Out "$portableOut\core" -PublicKey $public
} finally { Pop-Location }

if (-not $iscc) {
    throw 'Inno Setup 6 (ISCC.exe) is required to build the Windows installer.'
}

$installerScript = Join-Path $root 'app\windows\installer\BLACKFOX.iss'
if (-not (Test-Path -LiteralPath $installerScript)) {
    throw "Inno Setup script not found: $installerScript"
}

# Compile the installer from the script that is actually present in the repo.
& $iscc /Q "/DAppVersion=$version" "/DSourceDir=$portableOut" "/DOutputDir=$relWin" "/DOutputName=BLACKFOX-VPN-Setup" $installerScript
if ($LASTEXITCODE -ne 0) { throw 'BLACKFOX-VPN-Setup.exe failed to build' }

$installer = Join-Path $relWin 'BLACKFOX-VPN-Setup.exe'
if (-not (Test-Path -LiteralPath $installer)) {
    throw "Inno Setup reported success but did not create: $installer"
}
Copy-Item $installer (Join-Path $relWin 'BLACKFOX-Setup.exe') -Force

# The GitHub Actions workflow consumes these exact versioned paths in its
# Release names step. Keep the portable archive and installer together.
$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null
$portableArchive = Join-Path $dist "BLACKFOX-VPN-$version-Windows-x64.zip"
Compress-Archive -Path (Join-Path $portableOut '*') -DestinationPath $portableArchive -CompressionLevel Optimal -Force
Copy-Item $installer (Join-Path $dist "BLACKFOX-VPN-$version-Windows-Setup-x64.exe") -Force

Write-Host "Built Windows x64 Portable in $portableOut"
Write-Host "Created $portableArchive"
Write-Host "Created $(Join-Path $dist "BLACKFOX-VPN-$version-Windows-Setup-x64.exe")"
