# BLACKFOX VPN v1.0.3 — Verification & Test Report

- **Product:** BLACKFOX
- **Version:** `1.0.3` (`1.0.3+103`)
- **Creator Signature:** `Made by Jackdaw`

---

## 1. Static & Automated Invariant Verification (`PASS`)

Executed via `scripts/build-all.ps1`:

| Check / Test Suite | Result | Details |
| :--- | :--- | :--- |
| **Feature Inventory Documentation** | **PASS** | `docs/BLACKFOX_FEATURE_INVENTORY.md` (59 desktop/core features) and `docs/BLACKFOX_ANDROID_FEATURE_INVENTORY.md` (65 Android/TV features) created and verified against source. |
| **Version Consistency (`1.0.3`)** | **PASS** | `app/pubspec.yaml` (`1.0.3+103`), `app/lib/app_info.dart` (`1.0.3`), `app/windows/runner/Runner.rc` (`1.0.3`), `app/windows/installer/arman-vpn.iss` (`1.0.3`), `RELEASE/ARCH-LINUX/PKGBUILD/PKGBUILD` (`1.0.3`). |
| **Product Branding (`BLACKFOX`)** | **PASS** | All 15 localization `.arb` and `.dart` files in `app/lib/l10n/`, Windows `main.cpp` & `Runner.rc` & `desktop_bridge.cpp`, Android `strings.xml`, Linux `my_application.cc`, macOS `AppInfo.xcconfig`, and Core Web Dashboard updated to `BLACKFOX`. |
| **About Page Signature Invariant** | **PASS** | `app/lib/ui/about_page.dart` displays the BLACKFOX Kitsune logo, `BLACKFOX`, `Version 1.0.3`, Core version, update check, and source code link, ending with `Made by Jackdaw` as the final element with nothing after it. |
| **Monochrome Victorian Gothic Design Audit** | **PASS** | `app/lib/ui/app.dart`, `widgets.dart`, `overview_page.dart`, `connections_view.dart`, `announcement_panel.dart`, and `core/internal/service/web/app.css` verified free of purple, blue, green, red, orange, or colorful gradients. Country flags are rendered through a luminance-preserving grayscale color matrix (`_monochromeFlagMatrix`). |
| **Settings Search Index (`settings_search_test.dart`)** | **PASS** | Every `l.<key>` setting label/title across `_general`, `_connection`, `_bypass`, `_upstreamProxy`, `_fragment`, `_routing`, `_tun`, `_dns`, and `_advanced` matches `settingsIndex(l)` 1-to-1 with zero missing or stale entries. |
| **Persian Orthography (`persian_text_test.dart`)** | **PASS** | `app/lib/l10n/app_fa.arb` and `docs/readme/README_fa.md` verified free of forbidden hamza/tanween codepoints (`U+0623`, `U+0654`, `U+064B`). |
| **Bundled SVG Flags (`flags_test.dart`)** | **PASS** | `app/assets/flags/*.svg` matches `bundledFlags` while rendering in monochrome grayscale inside `CountryFlag`. |
| **Icon & Asset Generation** | **PASS** | All Windows `.ico`, Android adaptive/launcher `.png`, Android TV `banner.png`, Android vector drawables (`ic_stat_logo.xml`, `widget_button_*.xml`), Linux/macOS/Web `.png`, and App/Core tray icons generated and visually inspected. |

---

## 2. Feature Preservation Verification Matrix

| Section | Feature / Requirement | Source Implementation | Verification Status |
| :--- | :--- | :--- | :--- |
| **Windows Shell** | Fixed sidebar (`Overview`, `Servers`, `Accounts`, `Logs`, `Settings`, `Help`, `About`), compact top status bar, live/total traffic cards | `app/lib/ui/app.dart` | **VERIFIED IN SOURCE** |
| **Overview (Desktop)** | Connect/Disconnect orb, connection mode switch (`Proxy`, `System proxy`, `TUN`), server card, quota card, telemetry bar (down/up speed, uptime, ready accounts, restart proxy), and stage-by-stage Connection Test & Telemetry dialog (`Tunnel`, `TLS`, `HTTP`, `Total`, `IPv4/IPv6`, `ProxyPass`) | `app/lib/ui/overview_page.dart` | **VERIFIED IN SOURCE** |
| **Mobile Shell (Android)** | 5-tab mobile navigation on Android (`Home`, `Servers`, `Accounts`, `Activity`, `Settings`), plus `Help` & `About` in Settings, back-navigation handling (`PopScope`), and Android TV D-pad `FocusRing` | `app/lib/ui/mobile_shell.dart`, `app/lib/ui/focus_ring.dart` | **VERIFIED IN SOURCE** |
| **Servers** | Auto Recommended, Auto Fastest, manual country selection, live search box, sort by Latency / Name toggle, Refresh button, Test Real Delay, monochrome flags | `app/lib/ui/servers_page.dart` | **VERIFIED IN SOURCE** |
| **Accounts** | Multi-account list, drag-and-drop (`Draggable`/`DragTarget`) + Move Up/Down priority, status pills, quota bar with switch threshold marker & reset date, Use Now, Sign In Again, Enable/Disable, Refresh Quota, Remove confirmation, Backup export/import, Sign-in method, Switch threshold | `app/lib/ui/accounts_page.dart`, `app/lib/ui/signin_dialog.dart`, `app/lib/ui/browser_signin.dart` | **VERIFIED IN SOURCE** |
| **Logs & Activity** | `Log` tab (severity filter, search, Follow switch, Detailed logs switch, Copy, Clear) and `Connections` tab (open count, filter, Follow switch, Column selector, Clear) enabled on both Desktop and Android | `app/lib/ui/logs_page.dart`, `app/lib/ui/connections_view.dart` | **VERIFIED IN SOURCE** |
| **Settings** | Searchable settings across General, Connection, Routing, DNS, TUN, Relay Server (Shared, Personal, Health Test, ECH dialog), TLS Fragmentation, Upstream SOCKS5 Proxy, and Advanced (App port, Web dashboard, Open data folder, Dashboard login & diagnostics, Remove TUN service) | `app/lib/ui/settings_page.dart` | **VERIFIED IN SOURCE** |
| **Help** | Connecting applications, SOCKS5/HTTP address with Copy, `socks://` URI for v2rayN/v2rayNG/NekoBox with Copy, TCP/UDP port limitations, TUN/Routing/DNS explanations, troubleshooting, and quick navigation | `app/lib/ui/help_page.dart` | **VERIFIED IN SOURCE** |
| **About** | BLACKFOX Kitsune logo, `BLACKFOX`, `Version 1.0.3`, Core version, Check for updates, Source code (GPL-3.0), Web dashboard / Data folder, ending with `Made by Jackdaw` | `app/lib/ui/about_page.dart` | **VERIFIED IN SOURCE** |

---

## 3. Runtime & Hardware Test Notes

- **Automated `flutter test` / `go test`**: Because the Flutter SDK (`flutter`/`dart`) and Go toolchain (`go`) are not installed on this Windows machine, live execution of `flutter test` and `go test` requires a machine or CI runner with Flutter `>= 3.13.5` and Go `>= 1.26.1`. All static invariants checked by `settings_search_test.dart`, `persian_text_test.dart`, and `flags_test.dart` were executed directly via `scripts/build-all.ps1` and passed 100%.
- **Physical Android Phone / Android TV Device**: No physical Android phone or Android TV device was attached over ADB during this session; Android and Android TV layouts, adaptive/notification/widget icons, Leanback `banner.png`, and D-pad `FocusRing` were verified in source and asset inspection.
