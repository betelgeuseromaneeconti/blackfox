# Builds the Android APKs (armeabi-v7a, arm64-v8a, x86_64, and universal)
# for BLACKFOX into RELEASE\ANDROID\.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$match = Select-String -Path "$root\app\pubspec.yaml" -Pattern '^version:\s*(\d+\.\d+\.\d+)'
if (-not $match) { throw 'No version in app\pubspec.yaml' }
$version = $match.Matches[0].Groups[1].Value

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter SDK (flutter) is not installed or not in PATH.'
}
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    throw 'Go toolchain (go) is not installed or not in PATH.'
}
if (-not (Get-Command gomobile -ErrorAction SilentlyContinue)) {
    throw 'gomobile is not installed or not in PATH.'
}

if (-not $env:ANDROID_HOME) {
    if (Test-Path 'F:\Android\Sdk') { $env:ANDROID_HOME = 'F:\Android\Sdk' }
    else { $env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk" }
}
$ndk = (Select-String -Path "$root\app\android\app\build.gradle.kts" -Pattern 'ndkVersion\s*=\s*"([^"]+)"').Matches[0].Groups[1].Value
if (-not $env:ANDROID_NDK_HOME) { $env:ANDROID_NDK_HOME = "$env:ANDROID_HOME\ndk\$ndk" }
if (-not $env:JAVA_HOME) { $env:JAVA_HOME = "$env:ProgramFiles\Android\Android Studio\jbr" }

$ldflags = "-s -w -X github.com/shakur4min/blackfox/core/internal/version.Current=$version"

Push-Location "$root\core"
try {
    gomobile bind -target=android -androidapi 24 -trimpath -ldflags $ldflags -o ..\app\android\app\libs\core.aar ./mobile
    if ($LASTEXITCODE -ne 0) { throw 'gomobile bind failed' }
} finally { Pop-Location }

Push-Location "$root\app"
try {
    flutter pub get --offline
    if ($LASTEXITCODE -ne 0) { flutter pub get }
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }

    # 1. Split-per-ABI APKs (armeabi-v7a, arm64-v8a, x86_64)
    flutter build apk --release --no-pub --split-per-abi --dart-define=APP_VERSION=$version
    if ($LASTEXITCODE -ne 0) { throw 'flutter build apk --split-per-abi failed' }

    foreach ($abi in @('armeabi-v7a', 'arm64-v8a', 'x86_64')) {
        $src = "$root\app\build\app\outputs\flutter-apk\app-$abi-release.apk"
        if (Test-Path $src) {
            $destDir = Join-Path $root "RELEASE\ANDROID\$abi"
            New-Item -ItemType Directory -Force $destDir | Out-Null
            Copy-Item $src (Join-Path $destDir "BLACKFOX-$abi.apk") -Force
        }
    }

    # 2. Universal APK
    flutter build apk --release --no-pub --dart-define=APP_VERSION=$version
    if ($LASTEXITCODE -ne 0) { throw 'flutter build apk (universal) failed' }
    $univSrc = "$root\app\build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $univSrc) {
        $univDir = Join-Path $root 'RELEASE\ANDROID\universal'
        New-Item -ItemType Directory -Force $univDir | Out-Null
        Copy-Item $univSrc (Join-Path $univDir 'BLACKFOX-universal.apk') -Force
    }
} finally { Pop-Location }
