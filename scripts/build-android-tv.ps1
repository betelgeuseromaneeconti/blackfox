# Builds the Android TV Leanback-compatible APK into RELEASE\ANDROID-TV\BLACKFOX-AndroidTV.apk.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$match = Select-String -Path "$root\app\pubspec.yaml" -Pattern '^version:\s*(\d+\.\d+\.\d+)'
if (-not $match) { throw 'No version in app\pubspec.yaml' }
$version = $match.Matches[0].Groups[1].Value

$univApk = Join-Path $root 'RELEASE\ANDROID\universal\BLACKFOX-universal.apk'
if (-not (Test-Path $univApk)) {
    & "$PSScriptRoot\build-android.ps1"
}

if (Test-Path $univApk) {
    $tvDir = Join-Path $root 'RELEASE\ANDROID-TV'
    New-Item -ItemType Directory -Force $tvDir | Out-Null
    Copy-Item $univApk (Join-Path $tvDir 'BLACKFOX-AndroidTV.apk') -Force
    Write-Host "Built Android TV APK: $tvDir\BLACKFOX-AndroidTV.apk"
}
