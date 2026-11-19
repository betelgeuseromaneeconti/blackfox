# BLACKFOX — Independence & Legacy Reference Audit

**Repository:** `https://github.com/shakur4min/blackfox`  
**Owner:** `shakur4min` (`@shakur4min`)  
**Audit Branch:** `redesign/blackfox-independence` (branched from `main` @ `ecde6f9b2d3dd847c6984c2e72947465723af332`)  
**Target Version:** `2.0.69` (`2.0.69+2069` in `app/pubspec.yaml`, `.github/updates.json`)

---

## 1. Executive Summary

BLACKFOX (`2.0.69`) is an inherited multi-platform VPN and censored-network proxy client built with a Flutter UI (`app/`) and a Go core (`core/`), supporting Windows, Android (including Android TV), Linux, and macOS plus a browser-accessible Web Dashboard. Although partial rebranding from `Firefox VPN` -> `Arman VPN` -> `BLACKFOX` already occurred on `main`, the codebase still contains critical operational, packaging, CI, and branding leftovers pointing to prior project owners (`betelgeuseromaneeconti`, `armanlife`) and old names (`arman_vpn`, `arman-vpn`, `Arman VPN`, `Arman-VPN-*`, `firefoxvpn`).

Key blocking defects uncovered in this audit:
1. **Broken CI (`Build #112`, run `44328760175`)**: `app/pubspec.yaml` declares `name: blackfox`, but 19 of 24 test files in `app/test/` still import `package:arman_vpn/...`, causing `flutter analyze` to fail with 879 errors/warnings. `.github/workflows/build.yml` also triggers only on `main` (skipping feature/redesign branches) and uses an old macOS TUN launchd label `com.betelgeuseromaneeconti.blackfox.tun`.
2. **Broken Go Module & Binary/Service Mismatches**:
   - `core/go.mod` and ~80 Go files import `github.com/betelgeuseromaneeconti/blackfox/core/...` instead of `github.com/shakur4min/blackfox/core/...`.
   - `app/lib/core/tun_service.dart` invokes `arman-vpn-tun` while all build scripts produce `blackfox-vpn-tun(.exe)` (matching Go `cmd/blackfox-tun`).
   - `app/test/app_settings_test.dart` asserts `core/arman-vpn-core`, while `CoreProcess.executableFrom` returns `blackfox-vpn-core(.exe)`.
3. **Broken Android ProGuard & Owner Identity**:
   - `app/android/app/proguard-rules.pro` keeps `com.arman.firefoxvpn.Tun2Socks` even though `Tun2Socks.kt` moved to `com.betelgeuseromaneeconti.blackfox` (and will migrate to `com.shakur4min.blackfox`). Under R8 minification, `Tun2Socks` JNI native bindings are unprotected.
4. **Update & Release Validation Lock-In**:
   - `app/lib/app_info.dart` hardcodes `githubRepo = 'betelgeuseromaneeconti/blackfox'` and raw/jsDelivr manifest URLs under that owner.
   - `app/lib/core/updates.dart` (`_isBlackfoxRelease`) rejects release URLs unless `uri.path.startsWith('/betelgeuseromaneeconti/blackfox/releases/')`.
   - `app/test/updates_test.dart` asserts legacy `Arman-VPN-*` asset filenames while `app_info.dart` / `updates.dart` construct `BLACKFOX-VPN-*`.
5. **Unmigrated Installers & Desktop Branding**:
   - `core/scripts/install-systemd.sh` and `RELEASE/ARCH-LINUX/PKGBUILD/PKGBUILD` still install `arman-vpn` / `/opt/blackfox/arman-vpn` / `./cmd/arman-vpn-core` from `github.com/armanlife/arman-vpn-client`.
   - `app/windows/installer/BLACKFOX.iss`, `app/windows/runner/Runner.rc`, `app/linux/CMakeLists.txt`, `app/macos/Runner/`, `install.sh`, `core/cmd/blackfox-tun/intro.go`, and `app/lib/ui/about_page.dart` reference `betelgeuseromaneeconti` or `Arman VPN` / `arman-vpn`.

---

## 2. Canonical Target Identity Constants

All active build, runtime, packaging, and update paths must converge on these canonical identifiers:

| Component | Canonical Value |
| :--- | :--- |
| Application Display Name | `BLACKFOX` |
| GitHub Repository & Owner | `shakur4min/blackfox` (`@shakur4min`) |
| Primary URLs | `https://github.com/shakur4min/blackfox` |
| Update Manifest Primary / Mirror | `https://raw.githubusercontent.com/shakur4min/blackfox/main/.github/updates.json` & jsDelivr mirror |
| Release Binary Prefix | `BLACKFOX-VPN-<version>-...` |
| Go Module Path | `github.com/shakur4min/blackfox/core` |
| Go Source Command Paths | `./cmd/blackfox-core`, `./cmd/blackfox-tun` |
| Published Go Binaries | `blackfox-vpn-core(.exe)`, `blackfox-vpn-tun(.exe)` |
| Android `applicationId` & `namespace` | `com.shakur4min.blackfox` (`com/shakur4min/blackfox`) |
| Linux GTK App ID / Desktop File | `com.shakur4min.blackfox` / `com.shakur4min.blackfox.desktop` |
| Linux Systemd Service / User / Install Dir | `blackfox-vpn` / `blackfox-vpn` / `/opt/blackfox` |
| macOS Bundle ID / LaunchAgent / TUN Daemon | `com.shakur4min.blackfox` / `com.shakur4min.blackfox.plist` / `com.shakur4min.blackfox.tun` |
| Per-User Data Folder (macOS / Linux) | `BLACKFOX` (macOS) / `blackfox` (Linux XDG) / `user-data` (Windows / Portable) |
| Default Backup Zip Name | `BLACKFOX-backup.zip` |
| In-App Browser WebChannel Hook | `BlackfoxFxa`, `window.__blackfoxHooked`, `window.__blackfoxReply` |

---

## 3. Legacy Reference Inventory (Observed Code Searches)

### 3.1 `arman_vpn` (22+ search hits; 19/24 files in `app/test/`)
- **`app/test/*.dart` (19 un-migrated files out of 24)**: Only 5 test files were migrated in `ecde6f9`; the remaining 19 (including `app_settings_test.dart`, `core_api_test.dart`, `core_controller_test.dart`, `platform_test.dart`, `settings_search_test.dart`, `update_manifest_test.dart`, `updates_test.dart`, `widget_test.dart`, and 11 others) still use `import 'package:arman_vpn/...';`.
- **Docs & Scripts**: `core/doc/DEVELOPMENT.md`, `core/doc/MULTI-ACCOUNT.md`, `scripts/update-installed-windows.ps1`, `scripts/test-update-macos.sh`.

### 3.2 `arman-vpn` (40 files)
- **Flutter Source**:
  - `app/lib/core/tun_service.dart` (`arman-vpn-tun` binary name & stderr prefix regex `^arman-vpn-tun:\s*`)
  - `app/lib/core/core_api.dart` (`linuxFolder = 'arman-vpn'`, `'Arman-VPN-backup.zip'`)
  - `app/lib/core/models.dart` (comments/identifiers)
  - `app/lib/main.dart` (L20 comment `arman-vpn-core.exe`)
- **Tests**: `app/test/{app_settings,core_api,updates,update_manifest,widget}_test.dart`
- **Linux / Packaging / Docker / Scripts**:
  - `core/scripts/install-systemd.sh` (service name, binary names, user, `/opt/arman-vpn`, download URLs, prompts)
  - `RELEASE/ARCH-LINUX/PKGBUILD/PKGBUILD` (`./cmd/arman-vpn-core`, `./cmd/arman-vpn-tun`, `arman-vpn`, symlink)
  - `scripts/build-arch-linux.sh`, `scripts/update-installed-windows.ps1`, `scripts/test-update-macos.sh`
  - `Dockerfile`, `docker/entrypoint.sh`
  - `.github/ISSUE_TEMPLATE/bug_report.yml`
- **Windows Native / Web Dashboard / Docs**:
  - `app/windows/runner/legacy.cpp` (check legacy mutex/registry vs active)
  - `core/internal/service/web/{index.html,app.js}` (`Arman VPN` / `arman-vpn` UI text & asset/title strings)
  - `docs/{DOCKER,OPENWRT,BROWSER-SIGNIN}.md`, `docs/readme/README_{ru,zh,fa}.md`, `docs/relay/*`, `core/doc/*`, `RELEASE/TEST-REPORT.md`

### 3.3 `armanlife` / `Arman VPN` / `ArmanFxa` (18+ files)
- `armanlife` search hits (18 files): `Dockerfile`, `docker/entrypoint.sh`, `RELEASE/ARCH-LINUX/PKGBUILD/PKGBUILD`, `core/scripts/install-systemd.sh`, `core/internal/service/web/{index.html,app.js}`, `docs/*`, `core/doc/*`, `.github/ISSUE_TEMPLATE/bug_report.yml`, `scripts/update-installed-windows.ps1`.
- `app/lib/core/core_api.dart`: `static const appFolder = 'Arman VPN';`
- `app/lib/ui/browser_signin.dart`: `'ArmanFxa'` JS channel name, `window.__armanHooked`, `window.__armanReply`.

### 3.4 `firefoxvpn` / `Firefox VPN Client` (8 files)
- `app/android/app/proguard-rules.pro` (`-keep class com.arman.firefoxvpn.Tun2Socks { *; }`) — **CRITICAL BUG** (active class is in `com.betelgeuseromaneeconti.blackfox`, target `com.shakur4min.blackfox`).
- `core/doc/OPERATOR.md`, `docs/BLACKFOX_ANDROID_FEATURE_INVENTORY.md`
- `RELEASE/ARCH-LINUX/PKGBUILD/blackfox.desktop`
- `core/internal/tunservice/legacy_windows.go`, `core/internal/update/{legacy_linux_test,process_darwin_test}.go`, `scripts/test-update-macos.sh`

### 3.5 `betelgeuseromaneeconti` (27 non-Go files + ~80 Go files)
- **CI / Repo / Scripts**: `.github/workflows/{build.yml,docker.yml}`, `install.sh`, `scripts/{build-windows.ps1,build-windows-tun.ps1,build-linux.sh,build-linux-core.sh,build-android.ps1,build-macos.sh}`, `README.md`, `app/README.md`.
- **Flutter**: `app/lib/app_info.dart`, `app/lib/core/updates.dart`, `app/lib/ui/about_page.dart` (`Made by @betelgeuseromaneeconti`).
- **Android**: `app/android/app/build.gradle.kts` (`namespace`, `applicationId`, `-DPKGNAME=com/betelgeuseromaneeconti/blackfox`), and 5 Kotlin files (`CoreService.kt`, `MainActivity.kt`, `ConnectWidget.kt`, `QuickTile.kt`, `Tun2Socks.kt`) in `kotlin/com/betelgeuseromaneeconti/blackfox/`.
- **Desktop Runners & Installers**: `app/windows/{runner/Runner.rc,installer/BLACKFOX.iss}`, `app/linux/CMakeLists.txt`, `app/macos/Runner/{Configs/AppInfo.xcconfig,MainFlutterWindow.swift,Runner.xcodeproj/project.pbxproj}`.
- **Go Core (`core/`)**: `core/go.mod`, `core/cmd/blackfox-tun/intro.go` (`projectURL`), `core/internal/update/legacy_linux.go` (`com.betelgeuseromaneeconti.blackfox.desktop`), `core/tools/winres/main.go`, plus Go module imports across `core/cmd/...` and `core/internal/...`.

---

## 4. Separation: Active Dependencies vs. Intentional Legacy Migration Logic

We **must NOT** blindly string-replace legacy strings where they protect user data or upgrade continuity:

| Mechanism | Action | Location | Behavior |
| :--- | :--- | :--- | :--- |
| Windows Inno Setup `AppId` | **RETAIN** `{{6F3A2C1E-9B4D-4E7A-8C21-5D0F7B9E4A63}}` | `app/windows/installer/BLACKFOX.iss` | Keeps Windows Add/Remove Programs & upgrade-in-place identity intact. Change `AppPublisher` / URLs to `Shakur4min` / `shakur4min/blackfox`. |
| Windows Installer Registry Data Lookup | **RETAIN legacy keys as fallback, add `BLACKFOX` primary** | `app/windows/installer/BLACKFOX.iss`, `app/windows/runner/legacy.cpp` | Checks `HKCU\Software\BLACKFOX`, `Arman VPN`, `Firefox VPN` `KeptDataIn` so upgrades never orphan user data. |
| Per-User Data Folder Migration (`Firefox VPN Client`, `Arman VPN` -> `BLACKFOX`; `firefox-vpn-client`, `arman-vpn` -> `blackfox`) | **MIGRATE non-destructively** | `app/lib/core/core_api.dart`, `core/internal/config/` | Only moves legacy directory when the new canonical target directory does not exist (`FileSystemEntityType.notFound`). Never deletes or overwrites existing accounts/settings. |
| Linux Systemd Legacy Migration | **ADD safe migration path** | `core/scripts/install-systemd.sh`, `core/internal/update/legacy_linux.go` | Detect prior `/opt/arman-vpn`, `arman-vpn.service`, or `com.betelgeuseromaneeconti.blackfox.desktop`; stop service cleanly, back up config/state before switching to `/opt/blackfox` & `blackfox-vpn.service`, support rollback on failure. |
| macOS / Windows TUN Legacy Service Cleanup | **RETAIN inside `legacy_*.go` only** | `core/internal/tunservice/legacy_*.go`, `core/internal/update/legacy_darwin.go` | Allows `blackfox-vpn-tun` and updater to replace/stop prior `ArmanVPNTun` / `FirefoxVPNTun` / `com.betelgeuseromaneeconti.blackfox.*` registrations cleanly. |
| Upstream Mozilla VPN Protocol Endpoints | **DO NOT MODIFY** | `core/internal/{fxa,guardian,proxy}/...`, `app/lib/ui/browser_signin.dart` | `accounts.firefox.com`, `vpn.mozilla.org`, Guardian ProxyPass, and Fastly upstream edge nodes are the functional VPN protocol engine, unrelated to ArmanLife branding. |

---

## 5. Android `applicationId` Migration Strategy (`com.betelgeuseromaneeconti.blackfox` -> `com.shakur4min.blackfox`)

> [!WARNING]
> Changing `applicationId` creates a **completely distinct Android application identity** at the operating system level. Android will **not** automatically overwrite or upgrade an already-installed `com.betelgeuseromaneeconti.blackfox` (or `com.arman.firefoxvpn`) package with `com.shakur4min.blackfox`.

### Impact Assessment
1. **Upgrades & Side-by-Side Install**: Installing `com.shakur4min.blackfox` on a device that already has the previous package creates a second app icon side by side; Play/Android PackageInstaller cannot treat it as an in-place update because the application ID differs.
2. **Stored Accounts, Credentials & Settings**: Private app storage (`/data/data/<old_package>/files/core/`) — containing `config.json`, `accounts/`, `secret.key`, `routing/` — and `SharedPreferences` (per-app routing lists, VPN/proxy mode, notification speed, `app-settings.json`) remain isolated in the old package sandbox.
3. **Android Auto-Backup**: Cloud backups (`backup_rules.xml`, `data_extraction_rules.xml`) are keyed by `applicationId` and will not restore automatically into `com.shakur4min.blackfox`.
4. **System Integrations & Permissions**: The system `VpnService.prepare()` consent, persistent notification channels, `QuickTile` Quick Settings tile placement, and `ConnectWidget` home-screen widget instances must be re-granted/re-pinned on the new app ID.

### Safe User-Controlled Migration Path
1. **Step 1 (Old App — Export)**: Open **Accounts -> Menu (`⋮`) -> Export backup** (`BackupMenuButton` -> `GET /api/backup` -> Storage Access Framework `MainActivity.saveFile`) to save `*.zip` containing all accounts, encrypted credentials, and core settings. If using custom split-tunneling, open **Settings -> Routing -> Per-app proxy -> Menu (`⋮`) -> Export app list** (`_exportApps`) to copy the package list to the clipboard.
2. **Step 2 (Install New App)**: Install the `com.shakur4min.blackfox` APK (or Android TV APK).
3. **Step 3 (Restore)**: Complete the initial `WelcomePage`, open **Accounts -> Menu (`⋮`) -> Import backup** (`_import` -> `POST /api/backup/inspect` & `POST /api/backup/import`), optionally import the split-tunneling app list via clipboard (`_importApps`), grant the Android VPN connection prompt, and re-add any Quick Settings Tile or Home Screen Widget before uninstalling the legacy package.
