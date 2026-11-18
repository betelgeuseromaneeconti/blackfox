# Prints the public half of the key that updates are signed with
# (core\internal\signing): the release's SHA256SUMS.txt, which the Windows
# app checks before it installs a new version, and arman-vpn-tun.exe,
# which the installed TUN service checks before it replaces itself. The
# private key comes from BLACKFOX_SIGNING_KEY (base64) or BLACKFOX_SIGNING_KEY_FILE; legacy
# ARMAN_VPN_SIGNING_KEY names remain accepted for existing CI secrets (a developer key); without
# one it prints nothing and warns: such a build takes no updates. The build
# scripts pass the result to the core and the TUN service
# (-X ...internal/signing.Key=...).
#Requires -Version 7
$ErrorActionPreference = 'Stop'

if (-not ($env:BLACKFOX_SIGNING_KEY -or $env:BLACKFOX_SIGNING_KEY_FILE -or $env:ARMAN_VPN_SIGNING_KEY -or $env:ARMAN_VPN_SIGNING_KEY_FILE)) {
    Write-Warning 'No signing key (BLACKFOX_SIGNING_KEY or BLACKFOX_SIGNING_KEY_FILE): this build takes no updates'
    return ''
}
# The Go signing helper still accepts the legacy environment variable names.
if ($env:BLACKFOX_SIGNING_KEY) { $env:ARMAN_VPN_SIGNING_KEY = $env:BLACKFOX_SIGNING_KEY }
if ($env:BLACKFOX_SIGNING_KEY_FILE) { $env:ARMAN_VPN_SIGNING_KEY_FILE = $env:BLACKFOX_SIGNING_KEY_FILE }
Push-Location (Join-Path (Split-Path -Parent $PSScriptRoot) 'core')
try {
    $public = (go run ./tools/sign -public).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $public) { throw 'reading the signing key failed' }
    $public
} finally { Pop-Location }
