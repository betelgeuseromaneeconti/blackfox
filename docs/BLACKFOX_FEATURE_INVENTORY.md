# BLACKFOX VPN — Complete Feature Inventory & Source Audit

This document provides the complete source-code audit of the existing VPN client (`Arman VPN` -> `BLACKFOX` v1.0.3) across the Flutter UI (`app/`) and Go VPN Core (`core/`). Every user-facing feature, API endpoint, platform integration, dependency, limitation, and verification test is cataloged below.

> **Legal & Architectural Notice:** BLACKFOX is an independent UI and product-brand redesign licensed under GPL-3.0. It is not affiliated with Mozilla. The underlying Go VPN Core (Firefox Account OAuth/FxA, Guardian integration, ProxyPass management, Fastly HTTP/1.1, HTTP/2, and HTTP/3 transport, SOCKS5/HTTP proxy, DNS resolver, routing engine, and TUN networking) remains intact.

---

## 1. Core Lifecycle & Process Management

| Property | Details |
| :--- | :--- |
| **Feature Name** | Core Process Supervision & Loopback API Discovery |
| **Current Implementation** | On desktop (`Windows`, `Linux`, `macOS`), `CoreProcess` spawns `core/arman-vpn-core(.exe) -app -data-dir <dir>` with a piped `stdin` so the Core exits automatically if the UI crashes or quits. `CoreLocator` reads `local-api.token` (`X-Local-Token`) and `dashboard.listen` from `config.json` (default `127.0.0.1:10820`). If the dashboard port is taken (`app-error: dashboard_port_in_use`), `CoreProcess` automatically moves `dashboard.listen` up to 3 times before prompting the user. On Android, `AndroidCore` starts `CoreService` (`mobile.Mobile.start`) in-process via MethodChannel `app/android`. |
| **Source Files** | `app/lib/main.dart`, `app/lib/core/core_process.dart`, `app/lib/core/core_api.dart`, `app/lib/core/core_controller.dart`, `core/cmd/arman-vpn-core/main.go`, `core/internal/service/dashboard.go` |
| **API / Core Method** | `GET /api/status`, `POST /api/app/exit`, `POST /api/retry`, `X-Local-Token` header |
| **Platform Availability** | Windows, Linux, macOS, Android, Android TV |
| **Required UI Controls** | Core starting spinner, Core unreachable/exited error screen (`_NoCore`), Lost connection banner (`_LostBanner`), Change App Port dialog (`showPortDialog`), Retry button |
| **Dependencies & Limitations** | Requires `arman-vpn-core.exe` in `core/` beside the desktop executable (or `libs/core.aar` on Android). Loopback connections bypass system proxy (`DIRECT`). |
| **Verification Test** | `app/test/core_api_test.dart`, `app/test/core_controller_test.dart`, `app/test/widget_test.dart` (`explains a missing core`, port conflict dialog, retry behavior) |

---

## 2. Overview / Dashboard Features

### 2.1 Main Power Toggle (Connect / Disconnect)
| Property | Details |
| :--- | :--- |
| **Feature Name** | VPN / Proxy Power Control & Auto-Confirmation |
| **Current Implementation** | Toggles the proxy engine (`POST /api/power` with `{"on": bool}` on desktop, or `AndroidCore.setOn` on Android). When turned on with 0 accounts, redirects to Accounts/Sign-in. Shows `Connecting…` while `connectPending`, `starting`, or until `confirmedBy(lastTest)` passes. Automatically re-tests unconfirmed connections with exponential backoff (5s to 60s). |
| **Source Files** | `app/lib/ui/overview_page.dart`, `app/lib/core/core_controller.dart`, `core/internal/service/dashboard_api.go` |
| **API / Core Method** | `POST /api/power` (`{"on": true/false}`), `POST /api/power` (`{"on": true, "auto": true}`) |
| **Platform Availability** | Windows, Linux, macOS, Android, Android TV |
| **Required UI Controls** | Primary Connect / Disconnect control, status label (`Connected`, `Connecting…`, `Waiting`, `Error`, `Disconnected`), status hint/failure box |
| **Dependencies & Limitations** | Requires at least one ready Firefox Account to establish an upstream tunnel. |
| **Verification Test** | `app/test/widget_test.dart` (connect, disconnect, connecting ring, unconfirmed retest) |

### 2.2 Connection Mode Switch (Desktop: Proxy / System Proxy / TUN; Android: All Apps / Selected Apps / Proxy)
| Property | Details |
| :--- | :--- |
| **Feature Name** | Connection Mode Selection |
| **Current Implementation** | On Windows/desktop, switches `system_proxy.mode` between `clear` (Proxy service only), `set` (System proxy), and `tun` (TUN mode for all apps). Switching modes does not disconnect the proxy. Selecting `tun` when the TUN service is not installed prompts for administrator permission via `TunService.install()`. On Android, switches between `vpn` (All apps or Selected apps) and `proxy` (Proxy only). |
| **Source Files** | `app/lib/ui/overview_page.dart`, `app/lib/ui/connection_mode.dart`, `app/lib/core/tun_service.dart`, `core/internal/service/tun.go` |
| **API / Core Method** | `POST /api/system-proxy` (`{"mode": "clear" | "set" | "tun"}`), Android MethodChannel `setConnectionMode`, `setRoutingEnabled` |
| **Platform Availability** | Windows, Linux, macOS (Proxy / System proxy / TUN); Android (VPN All Apps / Selected Apps / Proxy) |
| **Required UI Controls** | Segmented mode selector, mode hint text, TUN status/install note (`TunNote`), System proxy hijacked warning (`_SystemProxyTakenNote` with "Set it again" action) |
| **Dependencies & Limitations** | TUN mode on Windows requires `arman-vpn-tun.exe` service (`ArmanVPNTun`). System proxy on Windows modifies `HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings` and saves previous proxy settings to restore on stop/exit. |
| **Verification Test** | `app/test/widget_test.dart` (mode switch, TUN install prompt handling, system proxy retake) |

### 2.3 Server & Location Summary Card
| Property | Details |
| :--- | :--- |
| **Feature Name** | Selected Server, Country, City & Exit Mismatch Display |
| **Current Implementation** | Displays the active or selected location (`homeLocation`), selection mode (`Recommended location`, `Fastest`, or manual country), country code/monochrome indicator, city name, server hostname, and transport (`HTTP/1.1`, `HTTP/2`, `HTTP/3`). Displays a soft warning (`_ExitMismatchNote`) if the user chose a specific country but the exit probe IP is in another country. |
| **Source Files** | `app/lib/ui/overview_page.dart`, `app/lib/ui/widgets.dart`, `app/lib/core/models.dart` |
| **API / Core Method** | `GET /api/status` (`proxy`, `exit`, `exit_mismatch`, `selection`, `selection_name`) |
| **Platform Availability** | All platforms |
| **Required UI Controls** | Location card with navigation shortcut to Servers page, exit mismatch warning banner, "Use the recommended location" quick-fix button on `location_refused` |
| **Dependencies & Limitations** | Exit country/city for `REC` is populated once the exit probe completes. |
| **Verification Test** | `app/test/widget_test.dart` (location display, recommended exit resolution, exit mismatch warning) |

### 2.4 Active Account, Quota Usage & Ready Account Count
| Property | Details |
| :--- | :--- |
| **Feature Name** | Active Account & Monthly Quota Telemetry |
| **Current Implementation** | Displays active account name/email, quota ring/bar (`usedBytes` / `limitBytes` or `Unlimited`), percentage used, switch threshold marker (`switch_threshold_percent`), quota reset date (`resetAt`), and ready/total account counts (`accountCounts`). Shows `_LowQuotaNotice` when remaining data is below 5 GiB and no spare ready account exists. |
| **Source Files** | `app/lib/ui/overview_page.dart`, `app/lib/ui/widgets.dart`, `app/lib/core/models.dart` |
| **API / Core Method** | `GET /api/status` (`active_account`, `accounts`, `switch_threshold_percent`) |
| **Platform Availability** | All platforms |
| **Required UI Controls** | Quota usage gauge/card with shortcut to Accounts page, low-quota dismissible notice with "Add account" button |
| **Dependencies & Limitations** | Quota values come from Mozilla Guardian headers (`X-Quota-*`). |
| **Verification Test** | `app/test/widget_test.dart` (quota card, unlimited quota, low quota notice) |

### 2.5 Connection Test, Latency, Public IP, Uptime, ProxyPass & Restart Proxy
| Property | Details |
| :--- | :--- |
| **Feature Name** | Live Telemetry, Stage-by-Stage Connection Test & Proxy Restart |
| **Current Implementation** | Displays real-time download/upload speed (`traffic.downRate`, `traffic.upRate`), total transferred (`traffic.down`, `traffic.up`, plus direct traffic), connection uptime (`proxy.startedAt`), ProxyPass renewal/expiry (`pass.expiresAt`, `pass.secondsUntilExpiry`), public IPv4/IPv6 (`exit.ipv4`, `exit.ipv6` when `showPublicIp` is enabled or in test details), LAN address chip when listening on `0.0.0.0`, upstream proxy pill when `upstreamProxy` is active, connection test stages (`tunnelMs`, `tlsMs`, `responseMs`, `totalMs`, `httpStatus`), and Restart Proxy action (`POST /api/proxy/restart`). |
| **Source Files** | `app/lib/ui/overview_page.dart`, `app/lib/ui/app.dart`, `app/lib/core/core_controller.dart`, `core/internal/proxy/conntest.go` |
| **API / Core Method** | `POST /api/test`, `POST /api/delay`, `POST /api/proxy/restart`, `GET /api/status` |
| **Platform Availability** | All platforms |
| **Required UI Controls** | Latency / Test Connection control, stage breakdown (Tunnel opening, TLS handshake, HTTP response, Total time, Public IPv4/IPv6), Restart Proxy button, Download/Upload speed & Total traffic cards, Uptime & ProxyPass renewal display |
| **Dependencies & Limitations** | `POST /api/test` requires the proxy to be running (returns 409 otherwise). |
| **Verification Test** | `app/test/widget_test.dart`, `app/test/core_controller_test.dart` |

### 2.6 Refused Port / Command Notices & UDP Refusal Warnings
| Property | Details |
| :--- | :--- |
| **Feature Name** | Protocol Limitation Notices & TUN UDP Refusal Notice |
| **Current Implementation** | Displays dismissible notices (`status.notices`) when a client requests a TCP port Mozilla refuses (`kind == 'port'`) or an unsupported SOCKS command (`kind == 'command'`), with count, relative time, and up to 3 hosts. In TUN mode, displays `_UdpNotice` when a program's non-carried UDP traffic was refused (`tun.refusedUdp`), with "Don't show again" toggle (`settings.udpNotice`). |
| **Source Files** | `app/lib/ui/overview_page.dart`, `app/lib/core/models_more.dart` |
| **API / Core Method** | `GET /api/status` (`notices`, `tun.refused_udp`) |
| **Platform Availability** | All platforms (`notices`); Windows/Linux (`tun.refused_udp`) |
| **Required UI Controls** | Dismissible warning cards for port/command refusals and TUN UDP refusal |
| **Dependencies & Limitations** | Notices expire after 5 minutes in Core; `_UdpNotice` auto-hides after 60 seconds of screen visibility. |
| **Verification Test** | `app/test/widget_test.dart` (UDP notice, port/command notices) |

---

## 3. Servers Page Features

| Property | Details |
| :--- | :--- |
| **Feature Name** | Server Selection, Search, Sorting & Real Delay Testing |
| **Current Implementation** | Offers `Auto (Recommended)` (`""`), `Auto (Fastest)` (`"fastest"`), and manual selection of any country exposed by the Core (`GET /api/locations`, including locations marked `locked` in Mozilla's Remote Settings). Supports real-delay testing (`POST /api/locations/ping` with `fresh: true/false`), auto-retesting when measurements are >10 minutes old, search filtering (`foldForSearch`), sorting by real latency (`pingMs`) or localized country name (`nameSortKey`), and displaying country, city, server hostname, active indicator, and cached/error badges. |
| **Source Files** | `app/lib/ui/servers_page.dart`, `app/lib/ui/widgets.dart`, `core/internal/service/dashboard_api.go` |
| **API / Core Method** | `GET /api/locations`, `POST /api/locations/ping`, `POST /api/location`, `GET /api/settings` |
| **Platform Availability** | All platforms |
| **Required UI Controls** | Auto Recommended option, Auto Fastest option, Search input, Sort selector (Latency / Name), Test Real Delay button, Refresh action, Server rows/cards with monochrome country badge, city, server hostname, latency badge, and selection indicator |
| **Dependencies & Limitations** | Real-delay measurement requires at least one account (`_noAccounts` check shows `NoAccountsPanel`). Can take up to 2 minutes. |
| **Verification Test** | `app/test/widget_test.dart`, `app/test/country_names_test.dart` |

---

## 4. Accounts Page & Authentication Features

### 4.1 Multi-Account Management & Priority Ordering
| Property | Details |
| :--- | :--- |
| **Feature Name** | Multi-Account Rotation, Quota Tracking, Reordering & Backup |
| **Current Implementation** | Lists all stored Firefox Accounts in priority order (`GET /api/accounts`). Automatically refreshes quotas older than 24 hours on page open (`refreshStaleQuotas`). Supports: Add Account (`startAddAccount`), Use Now (`POST /api/accounts/{id}/activate`), Enable/Disable (`POST /api/accounts/{id}/enabled`), Refresh Quota (`POST /api/accounts/{id}/refresh`), Sign In Again (`POST /api/signin` with `account_id`), Remove Account (`DELETE /api/accounts/{id}` with confirmation dialog), Reorder via Move Up / Move Down buttons and Drag-and-Drop (`POST /api/accounts/order`), Account Switch Threshold setting (`accounts.switch_threshold_percent`, 1–100%), Sign-In Method selection (`SignInMethod.api` vs `SignInMethod.browser`), and Export/Import Backup ZIP (`GET /api/backup`, `POST /api/backup/inspect`, `POST /api/backup/import`). |
| **Source Files** | `app/lib/ui/accounts_page.dart`, `app/lib/ui/backup.dart`, `app/lib/core/core_controller.dart`, `core/internal/accounts/manager.go` |
| **API / Core Method** | `GET /api/accounts`, `POST /api/accounts/order`, `POST /api/accounts/{id}/activate`, `POST /api/accounts/{id}/enabled`, `POST /api/accounts/{id}/refresh`, `DELETE /api/accounts/{id}`, `GET /api/backup`, `POST /api/backup/inspect`, `POST /api/backup/import` |
| **Platform Availability** | All platforms |
| **Required UI Controls** | Add Account button, Backup Export/Import menu, Account cards (priority number, drag handle, move up/down, status pill, email/name, quota bar with threshold tick, reset date, Use Now / Sign In Again, Enable switch, Refresh quota, Remove), Sign-in method selector, Switch threshold dialog, Create Firefox Account link |
| **Dependencies & Limitations** | Passwords and OAuth tokens are stored encrypted in `user-data/accounts/` and never exposed in logs or API responses. |
| **Verification Test** | `app/test/widget_test.dart`, `app/test/core_api_test.dart`, `app/test/languages_test.dart` |

### 4.2 Complete Authentication & Verification Flow
| Property | Details |
| :--- | :--- |
| **Feature Name** | Direct & In-App Browser Firefox Account Sign-In |
| **Current Implementation** | Supports both direct API sign-in (`_SignInDialog`) and in-app WebView sign-in (`BrowserSignInPage` using `FxaWebChannel` over `POST /api/signin/browser/proxy`). Handles all Mozilla FxA verification steps: `need_email_code`, `need_totp` (2FA authenticator), `need_unblock_code`, `need_email_link`, and `need_captcha` (base64 image CAPTCHA display and answer input). Supports password manager autofill (`AutofillGroup`) and converts Persian/Arabic-Indic digits in verification codes to ASCII digits. |
| **Source Files** | `app/lib/ui/signin_dialog.dart`, `app/lib/ui/browser_signin.dart`, `core/internal/service/signin_flow.go` |
| **API / Core Method** | `POST /api/signin`, `POST /api/signin/browser`, `POST /api/signin/browser/proxy`, `DELETE /api/signin/browser/proxy`, `GET /api/signin/{id}`, `POST /api/signin/{id}`, `DELETE /api/signin/{id}` |
| **Platform Availability** | Direct sign-in: All platforms; Browser sign-in: Windows (`webview_windows`), Android & macOS (`webview_flutter`) |
| **Required UI Controls** | Email/Password form with show/hide password, verification code input, CAPTCHA image viewer, confirmation link waiting state, localized error messages (`no_account`, `wrong_password`, `no_password` with Set Password link, `too_many_attempts`, `blocked`, `token_blocked`), fallback from browser sign-in to direct form |
| **Dependencies & Limitations** | Browser sign-in on Windows requires WebView2 runtime (gracefully offers direct form fallback if unavailable). |
| **Verification Test** | `app/test/widget_test.dart`, `app/test/browser_signin_test.dart` |

---

## 5. Logs & Connections Viewer

| Property | Details |
| :--- | :--- |
| **Feature Name** | Live Log Viewer & Active/Recent Connections Inspector |
| **Current Implementation** | Two tabs: **Log** (`GET /api/logs?after=N` polled every 1s) with severity filter (`All/DEBUG`, `INFO`, `WARN`, `ERROR`), text search, auto-scroll (`Follow`), Pause following, Detailed/Verbose logs toggle (`logging.verbose`), Copy all visible logs, and Clear; **Connections** (`ConnectionsView`, `GET /api/connections` polled every 1s) showing Time, Destination, Client (in tooltip/row), Rule (`Proxy`, `Direct`, `Blocked`, `Port refused`, `Failed`), Inbound (`SOCKS5`, `HTTP`, `TUN`), Protocol (`TCP`/`UDP`), Traffic (`↑ / ↓`), and Duration, with text filter, open count, Follow switch, customizable column visibility (`hiddenConnectionColumns`), and Clear (`DELETE /api/connections`). |
| **Source Files** | `app/lib/ui/logs_page.dart`, `app/lib/ui/connections_view.dart`, `core/internal/logx/loghub.go` |
| **API / Core Method** | `GET /api/logs?after=N`, `GET /api/connections`, `DELETE /api/connections`, `PUT /api/settings` (`logging.verbose`) |
| **Platform Availability** | All platforms (Connections tab available on both desktop and mobile Activity/Logs) |
| **Required UI Controls** | Log / Connections tab switch, severity selector, search/filter box, Follow switch, Detailed logs switch, column picker, Copy button, Clear button, selectable monospace log list, connections table/list |
| **Dependencies & Limitations** | Destinations in logs are redacted unless `logging.verbose` is enabled. |
| **Verification Test** | `app/test/widget_test.dart` (logs filtering, clearing, connections view, verbose toggle) |

---

## 6. Settings Features (All Categories)

### 6.1 General Settings
| Property | Details |
| :--- | :--- |
| **Feature Name** | Application Preferences & Startup Behavior |
| **Current Implementation** | Stored in `app-settings.json` (`AppSettings`). Includes: Language (`System default` + 15 languages: `en`, `fa`, `zh`, `zh_Hant`, `ru`, `tr`, `ar`, `az`, `id`, `es`, `fr`, `hu`, `pt`, `vi`, `bn`), Theme (`System`, `Light`, `Dark` — monochrome BlackFox palettes), Show public IP (`showPublicIp`), Close behavior on desktop (`Ask every time`, `Minimize to the tray`, `Quit the app`), Start on boot (`autostart`), Show the app's window on startup (`autostartShowsWindow`), Connect on startup (`autoConnect`), and on Android: Quick VPN mode switch (`showAppModeSwitch`) and Show speed in notification (`AndroidCore.showSpeed`). |
| **Source Files** | `app/lib/ui/settings_page.dart`, `app/lib/app_settings.dart`, `app/lib/desktop/desktop_integration.dart` |
| **API / Core Method** | `app-settings.json`, DesktopBridge `setAutostart`, Android MethodChannel `setShowSpeed` |
| **Platform Availability** | All platforms (platform-specific items gated by `Platform.isAndroid` / desktop) |
| **Required UI Controls** | Searchable settings index (`settingsIndex`), Language selector (with desktop routing region suggestion), Theme selector, Close behavior selector, switches for public IP, autostart, start minimized/show window, connect on startup, notification speed |
| **Dependencies & Limitations** | `test/settings_search_test.dart` enforces that every setting shown in `SettingsPage` is indexed in `settingsIndex`. |
| **Verification Test** | `app/test/settings_search_test.dart`, `app/test/app_settings_test.dart`, `app/test/widget_test.dart` |

### 6.2 Connection & Local Proxy Settings
| Property | Details |
| :--- | :--- |
| **Feature Name** | Transport Protocol, IP Version, MTU, Idle Sleep & Local Proxy Configuration |
| **Current Implementation** | Edits `config.json` via `PUT /api/settings`: Transport protocol (`h1` HTTP/1.1, `h2` HTTP/2, `h3` HTTP/3), IP version (`auto`, `dual`, `ipv6_first`, `ipv4`, `ipv6`), TUN MTU (`tun.mtu`, 1280–9000 or 0/empty for default), Sleep when idle (`proxy.idle_sleep`: `0s`, `5m`, `15m`, `30m`, `1h` on desktop), Connection mode (`clear`, `set`, `tun` on desktop; `vpn`, `proxy` on Android), Proxy port (`proxy.listen` port), Listen address (`127.0.0.1` local vs `0.0.0.0` LAN), and SOCKS5/HTTP Proxy Login (`proxy.username`, `proxy.password`, both or neither). |
| **Source Files** | `app/lib/ui/settings_page.dart`, `core/internal/config/config.go` |
| **API / Core Method** | `GET /api/settings`, `PUT /api/settings`, `POST /api/system-proxy` |
| **Platform Availability** | All platforms (`idle_sleep` desktop only) |
| **Required UI Controls** | Protocol selector, IP version selector, MTU input with Save, Idle sleep selector, Connection mode selector, Proxy port row/dialog, Listen address selector, expandable Proxy Login username/password fields with show/hide & Save |
| **Dependencies & Limitations** | Proxy username and password must be set together or both left empty. |
| **Verification Test** | `app/test/widget_test.dart`, `app/test/ports_test.dart` |

### 6.3 DNS Settings & DNS Diagnostic Test
| Property | Details |
| :--- | :--- |
| **Feature Name** | Encrypted DNS Presets, Custom DNS, System Fallback & Live DNS Test |
| **Current Implementation** | Configures `dns.servers` and `dns.fallback_to_system`: Presets (`system`, `auto` DoH Cloudflare+Google+Quad9, `cloudflare` DoH, `google` DoH, `quad9` DoH, `cloudflare_dot` DoT `tls://1.1.1.1`, and `custom` multiline editor), Fall back to system DNS switch, and Test DNS button (`POST /api/dns/test`) comparing configured DNS vs network DNS and highlighting DNS filtering/hijacking (`filtered`). |
| **Source Files** | `app/lib/ui/settings_page.dart`, `core/internal/resolver/resolver.go` |
| **API / Core Method** | `PUT /api/settings` (`dns`), `POST /api/dns/test` |
| **Platform Availability** | All platforms |
| **Required UI Controls** | DNS preset selector, Custom DNS multiline input with Save, Fallback switch, Test DNS button and results panel |
| **Dependencies & Limitations** | Custom servers must be valid `https://`, `tls://`, or IP[:port] entries. |
| **Verification Test** | `app/test/widget_test.dart` |

### 6.4 Routing Settings, Geo Lists, Ad-Blocking, Per-App Proxy & Destination Test
| Property | Details |
| :--- | :--- |
| **Feature Name** | Smart Routing, Regional Presets, Rules Editor, Geo Files & Destination Tester |
| **Current Implementation** | Configures `routing`: Enable routing (`routing.enabled`), Country preset (`ir`, `cn`, `ru`, `af`, `tr`, `id`, `br`, `""` none), Block ads shortcut (`geosite:category-ads-all` in `routing.block`), Per-app proxy on Android (`BypassAppsPage`: exclude/include modes, search, system apps toggle, regional suggested apps, clipboard import/export), Direct rules multiline editor (`routing.direct`), Restore regional rules button (`_restoreRegionRules`), Block rules multiline editor (`routing.block`), Rule syntax guide (`_RuleSyntax`), Resolve domains for IP rules (`routing.resolve_domains`), Geo list source selector (`Chocolate4U` / `Loyalsoldier` / custom), Update geo files now (`POST /api/routing/update`), and Test a destination (`POST /api/routing/test`). |
| **Source Files** | `app/lib/ui/settings_page.dart`, `app/lib/ui/bypass_apps_page.dart`, `core/internal/routing/router.go` |
| **API / Core Method** | `GET /api/routing`, `POST /api/routing/update`, `POST /api/routing/test`, `PUT /api/settings` (`routing`), Android MethodChannel `installedApps`, `appRouting`, `setAppRouting` |
| **Platform Availability** | All platforms (`BypassAppsPage` on Android) |
| **Required UI Controls** | Region selector, Routing switch, Block ads switch, Direct/Block rule editors with Save, Restore rules button, Rule syntax reference, Resolve domains switch, Geo list source & Update button, Destination test input & result pills |
| **Dependencies & Limitations** | Destination lookup with `resolve_domains` uses DoH through the tunnel when running. |
| **Verification Test** | `app/test/widget_test.dart`, `app/test/app_routing_test.dart`, `app/test/bypass_apps_clipboard_test.dart`, `app/test/android_routing_country_test.dart` |

### 6.5 TUN Settings (Desktop)
| Property | Details |
| :--- | :--- |
| **Feature Name** | Windows / Linux TUN Service & Program Bypass Management |
| **Current Implementation** | Configures `tun.programs` and `settings.udpNotice`: Notice when UDP is blocked switch, list of bypassed programs with mode selector (`All traffic` vs `UDP only`) and remove button, Add Program menu with 3 options: `From running programs` (`GET /api/tun/programs` with search dialog), `Choose a file…` (native file picker via `DesktopBridge.pickProgram`), and `Type a name…` (supports `*` and `?` wildcards). Also provides `Remove the TUN service` in Advanced settings (`TunService.uninstall()`). |
| **Source Files** | `app/lib/ui/settings_page.dart`, `app/lib/core/tun_service.dart`, `core/cmd/arman-vpn-tun/main.go` |
| **API / Core Method** | `GET /api/tun/programs`, `PUT /api/settings` (`tun.programs`), `arman-vpn-tun install | uninstall` |
| **Platform Availability** | Windows, Linux |
| **Required UI Controls** | UDP notice switch, Program bypass list, per-program All traffic / UDP only toggle, Remove program button, Add program menu & dialogs, Remove TUN service confirmation dialog |
| **Dependencies & Limitations** | Max 200 programs (`config.MaxTunPrograms`). |
| **Verification Test** | `app/test/widget_test.dart` (TUN programs add/remove/mode, running programs search, remove TUN service) |

### 6.6 Relay, ECH, TLS Fragmentation & Upstream SOCKS5 Proxy
| Property | Details |
| :--- | :--- |
| **Feature Name** | Censorship Circumvention (Personal/Shared Relay, ECH, ClientHello Split, Upstream Proxy) |
| **Current Implementation** | Configures `network`: Shared relay switch (`network.shared_relay_enabled`), Personal relay switch (`network.api_relay_enabled`), Personal relay URL (`network.api_relay`, `https://` required), ECH mode & config (`network.api_relay_ech`: `on`, `require`, `off`; `network.api_relay_ech_config`), Live streaming Relay Health Test dialog (`POST /api/relay/test` with `stream: true`), TLS fragmentation (`network.hello_split`: `off`, `auto`, `first-byte`, `sni`, `record`), and Upstream SOCKS5 proxy (`network.upstream_proxy_enabled`, `network.upstream_proxy` host & port, `network.upstream_proxy_username`, `network.upstream_proxy_password`). |
| **Source Files** | `app/lib/ui/settings_page.dart`, `app/lib/ui/relay_test_dialog.dart`, `app/lib/core/relay_test.dart` |
| **API / Core Method** | `PUT /api/settings` (`network`), `POST /api/relay/test` |
| **Platform Availability** | All platforms |
| **Required UI Controls** | Shared relay switch, Personal relay switch & URL field, ECH settings, Test relay health button & streaming log dialog, TLS fragmentation radio options, Upstream proxy switch, host/port/username/password fields with validation |
| **Dependencies & Limitations** | Upstream proxy cannot point to the app's own `proxy.listen` port. HTTP/3 is disabled while upstream proxy is active. |
| **Verification Test** | `app/test/widget_test.dart`, `app/test/core_api_test.dart` |

### 6.7 Advanced Settings
| Property | Details |
| :--- | :--- |
| **Feature Name** | App API Port, Web Dashboard Access, Diagnostics & TUN Service Removal |
| **Current Implementation** | Displays and changes the local API / Dashboard port (`dashboard.listen`), opens the embedded Web Dashboard signed-in (`POST /api/session/link`), provides access to Logs / Detailed logs (`logging.verbose`), Data folder (`POST /api/open-folder`), and Remove TUN Service when installed. |
| **Source Files** | `app/lib/ui/settings_page.dart`, `app/lib/ui/about_page.dart` |
| **API / Core Method** | `POST /api/session/link`, `POST /api/open-folder`, `PUT /api/settings` |
| **Platform Availability** | Desktop (App port, Data folder, Remove TUN service); Web dashboard link on both Desktop and Android |
| **Required UI Controls** | App port row & dialog, Web dashboard open button, Data folder open button, Remove TUN service button |
| **Dependencies & Limitations** | Web dashboard sign-in links expire in 15 minutes and are single-use. |
| **Verification Test** | `app/test/widget_test.dart` |

---

## 7. Help & Troubleshooting Features

| Property | Details |
| :--- | :--- |
| **Feature Name** | In-App Help, Proxy Connection Guide, URI Copy & Technical Limitations |
| **Current Implementation** | Explains how to connect applications via SOCKS5 and HTTP proxy (`127.0.0.1:10810` or LAN IP), provides one-click copy for the SOCKS5 address and the `socks://base64(user:pass)@host:port#BLACKFOX` URI (for v2rayN, v2rayNG, NekoBox), documents TCP port limitations (`80, 443, 8080, 8443` only, plus Git SSH over 443), UDP port limitations (`80, 443, 3478, 8080, 8443, 49152-65534` only, QUIC fallback to TCP), Smart Routing explanation, TUN mode explanation & per-program bypass, Common Errors & Troubleshooting (loopback proxy loops, DNS filtering, region blocks), and Log access. |
| **Source Files** | `core/internal/service/web/index.html`, `app/lib/ui/help_page.dart` (to be integrated into Desktop Sidebar & Mobile Settings/Help) |
| **API / Core Method** | Reads live `status.proxy.listen` and `config['proxy']` credentials to construct accurate copyable proxy addresses and `socks://` URIs |
| **Platform Availability** | All platforms |
| **Required UI Controls** | Dedicated Help navigation item on Desktop and expandable Help screen on Android, Copy SOCKS5 address button, Copy `socks://` URI button, expandable/structured technical guides |
| **Dependencies & Limitations** | Never displays the raw proxy password on screen in Help; only copies the encoded `socks://` URI on user action. |
| **Verification Test** | Widget test verifying Help navigation, SOCKS5 address display, URI copy, and limitation sections |

---

## 8. About Page, Updates & Announcements

| Property | Details |
| :--- | :--- |
| **Feature Name** | Product Identity, Version Info, Signed Self-Updater & Announcements |
| **Current Implementation** | Displays the BLACKFOX Kitsune logo, product name (`BLACKFOX`), app version (`1.0.3`), live Core version (`status.version`), manual & automatic update checking (`Updates`, `checkForUpdate`), in-app signed update download/install on desktop (`POST /api/update/download`, `POST /api/update/install`), browser APK download on Android, Source Code link, Web Dashboard link (Android), Data folder button (desktop), and the final creator signature `Made by Jackdaw` (with nothing appearing after it). Also supports `AnnouncementOverlay` for manifest announcements. |
| **Source Files** | `app/lib/ui/about_page.dart`, `app/lib/core/updates.dart`, `app/lib/app_info.dart`, `app/lib/ui/announcement_panel.dart` |
| **API / Core Method** | `POST /api/update/download`, `POST /api/update/install`, `POST /api/session/link`, `POST /api/open-folder` |
| **Platform Availability** | All platforms |
| **Required UI Controls** | BLACKFOX Kitsune logo, `BLACKFOX` title, App version `1.0.3`, Core version, Check for updates button, Update / Download button with progress bar, Source code button, Data folder / Web dashboard buttons, final `Made by Jackdaw` signature |
| **Dependencies & Limitations** | Nothing may appear after `Made by Jackdaw` on the About page. Core version must report the actual version from `status.version`. |
| **Verification Test** | `app/test/updates_test.dart`, `app/test/update_manifest_test.dart`, `app/test/announcement_panel_test.dart`, `app/test/widget_test.dart` |

---

## 9. Data Folder & Branding Migration Strategy

1. **Zero Data Loss Guarantee:**
   - On Windows, user data (`config.json`, `app-settings.json`, `state.json`, `selection.json`, `servers.json`, `accounts/<id>/account.json`, `accounts/<id>/credentials.json`, `accounts/secret.key`, `routing/`, `logs/`) resides in `user-data` beside the executable.
   - `CoreLocator.moveLegacyDataDir` preserves compatibility with legacy installations (`Firefox VPN Client` / `Arman VPN` -> `BLACKFOX`) by migrating existing data folders only when the target folder does not yet exist, never overwriting or deleting existing accounts, credentials, or settings.
2. **Installer & Registry Compatibility:**
   - The Windows installer (`app/windows/installer/arman-vpn.iss`) checks `HKCU\Software\BLACKFOX`, `HKCU\Software\Arman VPN`, and `HKCU\Software\Firefox VPN` (`KeptDataIn`) so reinstalling or upgrading into an existing directory preserves `user-data` seamlessly.
   - Previous Windows system proxy settings (`PreviousProxy`) and single-instance mutex handoffs remain intact.
