# BLACKFOX

**BLACKFOX** is an independent, open-source VPN client for Windows and Android, with Linux and macOS build support.

- Product: BLACKFOX
- Current app version: **2.0.69**
- Repository: https://github.com/betelgeuseromaneeconti/blackfox
- Maintainer: [@betelgeuseromaneeconti](https://github.com/betelgeuseromaneeconti)
- License: GNU GPL v3.0 (see [LICENSE](LICENSE))

## Downloads

Get published builds from the [BLACKFOX Releases](https://github.com/betelgeuseromaneeconti/blackfox/releases) page. Use only assets attached to releases in this repository.

## Build from source

### Go core

```bash
cd core
go test ./...
go vet ./...
```

### Flutter app

```bash
cd app
flutter pub get
flutter analyze
```

### Windows

From PowerShell at the repository root:

```powershell
.\scripts\build-windows.ps1 -Version 2.0.69
```

### Android

Use the repository's Android build workflow or `scripts/build-android.ps1` on a configured Windows host.

## Project identity

BLACKFOX maintains its own application identifiers, release assets, update metadata, installer, and repository links. The VPN core and account/tunnel behavior remain part of the application.

## Third-party notices

BLACKFOX includes third-party and GPL-licensed components. Their original license and copyright notices are retained in the repository. BLACKFOX is an independent project and is not affiliated with or endorsed by Mozilla.
