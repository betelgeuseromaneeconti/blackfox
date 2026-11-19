# BLACKFOX — Architecture Review & Technical Defect Analysis

**Version:** `2.0.69`  
**Audit Scope:** Flutter Frontend (`app/`), Go VPN Core (`core/`), Platform Runners (Windows, Android/TV, Linux, macOS), Web Dashboard (`core/internal/service/web/`), Installers, and GitHub Actions CI.

---

## 1. System Architecture

BLACKFOX uses a split **UI + Local Control-Plane Engine** architecture across every supported platform:

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Flutter Application (app/)                                              │
│  - CoreController (2s status poll, 6s accounts poll, unconfirmed retest)│
│  - CoreApi (Loopback HTTP + X-Local-Token + JSON Content-Type guard)    │
│  - AppSettings (app-settings.json beside Core data folder)              │
│  - Platform Bridges: app/desktop (Win32/GTK/Swift), app/android (Kotlin)│
└───────────────────────────────┬───────────────────────────────┬─────────┘
                                │ HTTP 127.0.0.1:<dashPort>     │ IPC / Elevation
                                ▼                               ▼
┌──────────────────────────────────────────┐   ┌──────────────────────────┐
│ Go VPN Core (core/)                      │   │ Desktop TUN Daemon       │
│  - Desktop: blackfox-vpn-core(.exe) -app │   │  - blackfox-vpn-tun(.exe)│
│  - Android: core.aar (gomobile)          │   │  - cmd/blackfox-tun/     │
│  - Engine: FxA auth, Guardian ProxyPass, │   │  - Named pipe (Win) /    │
│    Fastly H1/H2/H3, SOCKS5+HTTP proxy,   │   │    Unix socket (Lin/Mac) │
│    DoH/DoT DNS, GeoSite/GeoIP router,    │   └──────────────────────────┘
│    Relay + ECH + TLS split, Upstream     │
│  - Embedded Web Dashboard (web/)         │
└──────────────────────────────────────────┘
```

### 1.1 Process & Service Lifecycles
- **Windows / Linux / macOS**:
  - `CoreProcess.connect()` binds-checks the Core dashboard port (`127.0.0.1:10820` default from `config.json`) via `isFree(port)` to avoid Windows' ~2s TCP connect-refused timeout.
  - Spawns `core/blackfox-vpn-core(.exe)` (or `blackfox-vpn-core` inside `Contents/MacOS/` on macOS) with `-app -data-dir <dir>` and keeps `stdin` open so the Core exits cleanly if the UI crashes or quits.
  - If another process occupies `dashboard.listen` (`app-error: dashboard_port_in_use`), `CoreProcess` relocates the port automatically up to 3 times before surfacing `CoreProblem.portInUse` (`showPortDialog`).
  - Native shell chrome, system tray (`setTray` / `onTrayMenu`), autostart (`Run` registry key / XDG `.desktop` / macOS LaunchAgent), toast/desktop notifications, file picker (`pickProgram`), and single-instance wake-up (`shown`) travel over `MethodChannel('app/desktop')`.
- **Android & Android TV**:
  - `CoreService.kt` runs inside the Android process and hosts `mobile.Mobile` (`core.aar` built by `gomobile`).
  - **VPN Mode (`MODE_VPN`)**: Calls `VpnService.prepare`, opens a TUN fd (`172.19.0.1/30`, DNS `172.19.0.2`, IPv6 `fdfe:dcba:9876::1/126`, default MTU `1500`), excludes its own app package, applies per-app `disallow` / `allow` routing lists, and drives `Tun2Socks.kt` (`libhev-socks5-tunnel.so` JNI) into the Go SOCKS5 loopback listener.
  - **Proxy-Only Mode (`MODE_PROXY`)**: Runs foreground service + local SOCKS5/HTTP proxy (`127.0.0.1:<port>` or `0.0.0.0:<port>`).
  - **Network Roaming**: `CoreService.watchNetwork` tracks `NET_CAPABILITY_INTERNET + NET_CAPABILITY_NOT_VPN`, calls `setUnderlyingNetworks`, and notifies `mobile.Mobile.networkChanged(...)`.
  - **System Entry Points**: Ongoing notification (`ACTION_STOP`), `QuickTile.kt` (`ACTION_QS_TILE_PREFERENCES` -> `openHome`), `ConnectWidget.kt`, `BrowserSignInPage` proxy (`ProxyController`).
  - **TV Support**: Detects `UI_MODE_TYPE_TELEVISION`, keeps landscape/unrestricted orientation (`MainActivity.kt`), locks `<600dp` phones to portrait, activates `FocusRing` D-pad indicator on startup, and opens `showLink` copyable URL dialogs when TV firmware lacks a browser (`com.android.tv.frameworkpackagestubs` filtered).

### 1.2 Data Directory Resolution & Security Controls
- **Data Directory (`CoreLocator.dataDir`)**:
  - Override flag `--data-dir=<path>`; else `user-data/` beside executable on Windows or when `portable` file exists beside executable; otherwise per-user XDG (`~/.local/share/<linuxFolder>`) on Linux, `~/Library/Application Support/<appFolder>` on macOS, or app-private files dir on Android.
- **API Security**:
  - All API requests require `X-Local-Token` matching `<dataDir>/local-api.token` (401 rejected -> `_refused` UI state).
  - Mutating methods (`POST`, `PUT`, `DELETE`) require `Content-Type: application/json` (415 rejected).
  - Accounts and FxA credentials are stored encrypted on disk in `<dataDir>/accounts/` using `secret.key` and never returned in status/settings APIs or logs.

---

## 2. Dashboard HTTP API Surface

Observed across `app/lib/core/core_api.dart`, `app/tool/fake_core.dart`, and `core/internal/service/`:

| Group | Endpoints |
| :--- | :--- |
| Telemetry & Control | `GET /api/status`, `POST /api/power`, `POST /api/retry`, `POST /api/proxy/restart`, `POST /api/test`, `POST /api/delay`, `POST /api/system-proxy`, `POST /api/app/exit`, `POST /api/open-folder`, `POST /api/session/link` |
| Settings | `GET /api/settings`, `PUT /api/settings` |
| Accounts & Auth | `GET /api/accounts`, `POST /api/accounts/order`, `POST /api/accounts/{id}/activate`, `POST /api/accounts/{id}/enabled`, `POST /api/accounts/{id}/refresh`, `DELETE /api/accounts/{id}`, `POST /api/signin`, `POST /api/signin/browser`, `GET / POST / DELETE /api/signin/{id}`, `POST / DELETE /api/signin/browser/proxy` |
| Backup & Flags | `GET /api/backup`, `POST /api/backup/inspect`, `POST /api/backup/import`, `GET /flags/{code}.svg` |
| Locations & Routing | `GET /api/locations`, `POST /api/locations/ping`, `POST /api/location`, `GET /api/routing`, `POST /api/routing/update`, `POST /api/routing/test` |
| Diagnostics & TUN | `POST /api/dns/test`, `POST /api/relay/test` (streaming events), `GET /api/tun/programs` |
| Logs & Connections | `GET /api/logs?after=<id>`, `GET /api/connections`, `DELETE /api/connections` |
| Self-Update | `POST /api/update/download`, `POST /api/update/install` |

---

## 3. Architectural Defects & Refactoring Plan

### Defect 1 — Flutter Package Import Split (`package:arman_vpn` vs `package:blackfox`)
- **Severity**: **Critical (CI Blocker)**. Build #112 (`run 44328760175`) failed during `flutter analyze` with 879 issues because commit `ecde6f9` renamed `pubspec.yaml` `name: blackfox` and updated only 5 of 24 test files.
- **Fix**: Update the remaining 19 files in `app/test/` to `package:blackfox/...` after verifying each target source file path exists, and align stale assertions in `app_settings_test.dart` (`blackfox-vpn-core`), `updates_test.dart` (`BLACKFOX-VPN-*`), `core_api_test.dart` (`BLACKFOX`/`blackfox` + legacy migration tests), and `widget_test.dart`.

### Defect 2 — Go Module & Binary Naming Drift
- **Severity**: **Critical (Wrong binary invocation & broken module import authority)**.
- `core/go.mod` uses `module github.com/betelgeuseromaneeconti/blackfox/core` and `docker.yml` injects `-X github.com/betelgeuseromaneeconti/.../version.Current`.
- `app/lib/core/tun_service.dart` looks for `arman-vpn-tun(.exe)`, whereas all build scripts build `blackfox-vpn-tun(.exe)` (`cmd/blackfox-tun`).
- `core/scripts/install-systemd.sh` & `RELEASE/ARCH-LINUX/PKGBUILD/PKGBUILD` reference non-existent `./cmd/arman-vpn-core` / `armanlife/arman-vpn-client`.
- **Fix**: Normalize `core/go.mod` and every Go import across `core/` to `github.com/shakur4min/blackfox/core`, update `tun_service.dart` to `blackfox-vpn-tun`, and migrate installers/PKGBUILDs/CI cleanly while keeping legacy cleanup paths.

### Defect 3 — Android ProGuard / R8 JNI Rule Bug & Package ID Migration
- **Severity**: **High (Release build crash risk if R8 minification shrinks `Tun2Socks`)**.
- `app/android/app/proguard-rules.pro` currently specifies `-keep class com.arman.firefoxvpn.Tun2Socks { *; }`, which no longer matches the Kotlin package!
- `build.gradle.kts` (`namespace`, `applicationId`, `cFlags -DPKGNAME=...`) and the 5 Kotlin files under `com/betelgeuseromaneeconti/blackfox/` must move to `com/shakur4min/blackfox` (`com.shakur4min.blackfox`) with updated `proguard-rules.pro`.

### Defect 4 — CI Workflow Coverage Gap
- **Severity**: **High**. `.github/workflows/build.yml` only triggers on `branches: [main]` and gates release builds cleanly, meaning work on `redesign/blackfox-independence` would not run CI automatically unless added to `on.push.branches` / `pull_request.branches`.
- **Fix**: Trigger `test` and build jobs on `['main', 'redesign/**']` (keeping actual GitHub Release publishing strictly on tags/manual dispatch as designed) and update macOS launchd test strings.

### Defect 5 — UI Rendering Overhead & Mixed Palette
- **Severity**: **Medium (GPU/frame-time & visual cohesion)**.
- `Panel` (`app/lib/ui/widgets.dart` L655) wraps every card in `BackdropFilter(filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14))` over opaque backgrounds — wasting fill-rate on software/low-power GPUs and Android TV while muddying dark surfaces.
- `app.dart`, `widgets.dart`, and `overview_page.dart` use cool blue-slate dark tokens (`#090C12`, `#080B10`, `#0D1118`, `#141923`, `#1B2230`, `#252D3B`) instead of the crisp pure OLED black `#000000` / `#080808` / `#0D0D0D` / `#252525` BLACKFOX identity.
- **Fix**: Remove heavy `BackdropFilter` from `Panel`, replace slate-blue colors with pure neutral monochrome `#000000` surfaces + crisp `1px` `#252525` borders across Flutter and the Web Dashboard (`core/internal/service/web/`), while keeping `_ConnectingRing` and `debugContourPaints` animation architecture compliant with `widget_test.dart`.
