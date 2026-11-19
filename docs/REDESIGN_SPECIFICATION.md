# BLACKFOX — Multi-Platform UI/UX & Identity Redesign Specification

**Version:** `2.0.69`  
**Branch:** `redesign/blackfox-independence`  
**Owner:** `@shakur4min` (`https://github.com/shakur4min/blackfox`)

---

## 1. Visual Brand Identity & Emblem (Stage D)

### 1.1 Kitsune Mask Emblem Specification
- **Concept**: Symmetrical, crisp, minimalist **Japanese Kitsune fox mask** rendered from procedural vector geometry in both `app/tool/app_icons.py` (master icon generator) and synchronized in `scripts/generate-icons.ps1`.
- **Composition Rules**:
  - Centered, bilateral symmetry across the vertical axis.
  - Pure geometric silhouette & crimson ritual accents (**white ceramic mask body `#FAFAFA`**, **bold red `#DC2626` / `#EF4444` traditional Kitsune ear tips, slit eyes, forehead/cheek markings & dark obsidian outlines `#0A0A0A`**).
  - **Strict exclusions**: No human figure, no hair, no collar/clothing, and **no embedded text** inside app icons (`app_icon.ico`, macOS `AppIcon`, Android `ic_launcher`, tray icons, `logo.png`, `web/icon.png`). Only the Android TV `banner.png` (`320x180`) pairs the Kitsune mask cleanly beside a crisp horizontal `"BLACKFOX"` wordmark.
  - **Background**: Transparent alpha canvas on `assets/logo.png`, `web/icon.png`, and `ic_launcher_foreground.png`; adaptive Android background uses pure obsidian `#080808` (`BLACK` in `app_icons.py`).
- **Tray Icons**:
  - `assets/tray/*.{png,ico}` and `core/internal/desktop/tray/*.{png,ico}` derive from the crisp monochrome/red-accent Kitsune silhouette on dark `#0F0F0F` medallion with clear state dot / 4-frame busy orbit (`off`, `on`, `idle`, `error`, `busy1..4`, plus Go Core desktop tray names `running`, `set`, `running-asleep`, `set-asleep`, `waiting`).

---

## 2. Design System & Color Tokens (Stage E)

### 2.1 Monochrome Surface Hierarchy
Replace all bluish-slate colors (`#090C12`, `#080B10`, `#0D1118`, `#141923`, `#1B2230`, `#252D3B`) and heavy `BackdropFilter` blurs with high-contrast monochrome surfaces:

| Token | Dark Mode (Default) | Light Mode | Usage |
| :--- | :--- | :--- | :--- |
| Primary Background (`bg`) | `#000000` | `#FAFAFA` | Scaffold, page canvas, OLED pure black |
| Secondary / Chrome (`bgSecondary`) | `#080808` | `#F4F4F5` | Navigation rail, mobile bottom bar, top status strip, adaptive icon backdrop |
| Card / Surface (`surface`) | `#0D0D0D` | `#FFFFFF` | `Panel`, `_HomeCard`, server/account cards, dialogs |
| Elevated / Hover (`surfaceElevated`) | `#141414` | `#F0F0F2` | Selected list tiles, active rail pill, hover/focus fill, `_ModeSwitch` track |
| Border (`border`) | `#252525` | `#D4D4D8` | Crisp `1px` borders, `GothicDivider`, input outlines |
| Primary Text (`ink`) | `#FFFFFF` | `#0A0A0A` | Headings, active labels, primary stats |
| Secondary Text (`inkMuted`) | `#A0A0A0` | `#52525B` | Captions, hints, metadata, axis labels |
| Tertiary / Disabled Text | `#666666` | `#A1A1AA` | Disabled labels, separators |
| Semantic State Colors | Connected `#34D399` · Busy `#F59E0B` · Error `#F87171` | Connected `#16A34A` · Busy `#D97706` · Error `#DC2626` | Restrained strictly to status dots, orb ring, latency/quota badges, alert banners |

### 2.2 Typography & Localization Preservation
- Preserve `Inter` for Latin text (`en`) and `Vazirmatn` for Persian/Arabic (`fa`, `ar`), keeping platform fallbacks for `zh`, `zh_Hant`, `ru`, `tr`, `az`, `id`, `es`, `fr`, `hu`, `pt`, `vi`, `bn`.
- Preserve `Consolas` / `Menlo` / `DejaVu Sans Mono` monospace with `FontFeature.tabularFigures()` for live speed rates, latencies, IP addresses, ports, logs, and connections.
- Preserve `ltr()` Unicode isolates and Jalali calendar formatting (`formatDate`, `formatDateTime`).

### 2.3 Component & Animation Refinements
- **`Panel` (`app/lib/ui/widgets.dart`)**: Replace `BackdropFilter` + blue gradient with a crisp `#0D0D0D` (`#FFFFFF` light) container, `BorderRadius.circular(14)`–`16`, `1px` `#252525` (`#D4D4D8` light) border, and subtle elevation in light mode only.
- **`AppLogo`**: Uses regenerated symmetrical red-and-white Kitsune mask emblem cleanly alongside crisp `BLACKFOX` title lockups where branded headers appear.
- **Test-Invariance Guarantees**:
  - `overview_page.dart` **must continue exporting** `int get debugContourPaints`, keeping its drift/contour layer Paint count constant across 60 frames, and keeping `_ConnectingRing` (`w.runtimeType.toString() == '_ConnectingRing'`) on the power orb while connecting.
  - `focus_ring.dart` **must retain** `ValueKey('focus-ring')`.
  - `announcement_panel.dart` **must retain** `ValueKey('announcement-card')`.
  - `settings_page.dart` **must retain** `Widget _<section>(AppLocalizations l` builders for `_general`, `_connection`, `_bypass`, `_upstreamProxy`, `_fragment`, `_routing`, `_tun`, `_dns`, `_advanced` with every setting represented in `settingsIndex(l)` to pass `settings_search_test.dart`.

---

## 3. Platform-Specific UI Specifications (Stages F, G, H)

### 3.1 Windows & macOS Desktop Layout (`app.dart`, `overview_page.dart`, `settings_page.dart`)
- **Left Navigation Rail / Sidebar** (`#080808` canvas, `1px` `#252525` right divider): Compact BLACKFOX Kitsune brand header, primary tabs (`Overview`, `Servers`, `Accounts`, `Logs & Connections`), secondary utility tabs (`Settings`, `Help`, `About`), plus bottom live core-connection & mode indicator pill.
- **Overview (`_DesktopHome`)**:
  - Top status header (`_DesktopStatusBar`) + pure black `#000000` background with crisp monochrome geometric contour overlay.
  - Tactile obsidian power orb (`#141414` -> `#080808`, `1px` `#252525` / accent ring when connecting/connected), state heading, delay pill + public IP pill + upstream proxy pill, seamless `_ModeSwitch` (`Proxy only` / `System proxy` / `TUN`).
  - Dual high-contrast summary cards (`_PlaceCard`, `_HomeData`) aligned side-by-side (`>=560dp`) + `_DesktopTelemetryBar` (`↓ downRate`, `↑ upRate`, uptime, ready accounts, Diagnostics modal trigger, Reload button).
- **Tray & Close UX**: Matches pure monochrome `#000000` / `#0D0D0D` theme in `close_dialog.dart`.

### 3.2 Linux Desktop Layout
- Shares the desktop sidebar shell while adapting seamlessly to X11/Wayland scaling (`app/linux/runner/my_application.cc`), headless/systemd service configurations (`blackfox-vpn`), GTK desktop ID `com.shakur4min.blackfox`, and Linux TUN bypass/removal UX when running on systems with `tunSupported` & `programsSupported`.

### 3.3 Android Mobile & Android TV Layout (`mobile_shell.dart`, `_PhoneHome`, `bypass_apps_page.dart`)
- **Mobile Navigation (`MobileShell`)**: Pure `#080808` bottom `NavigationBar` with crisp `1px` `#252525` top hairline, active monochrome white indicator pill, 5 destinations (`Home`, `Servers`, `Accounts`, `Logs`, `Settings`), edge/hardware Back -> Home (`PopScope`).
- **Phone Home (`_PhoneHome`)**:
  - Compact top header with `AppLogo`, `BLACKFOX` wordmark, quick Diagnostics (`Icons.analytics_outlined`) & Reload (`Icons.restart_alt_rounded`) buttons, plus optional Help shortcut if exposed.
  - Central power orb (`scale: 0.68` when height `<700` such as `960x540` Android TV), connection label, delay / public IP / upstream / LAN chips, optional 3-segment Android quick mode switch (`All apps` / `Selected apps` / `Proxy`) when `settings.showAppModeSwitch` is enabled, notices, and Location + Data cards.
- **Android TV (`AndroidCore.isTv`)**:
  - High-contrast white `FocusRing` D-pad outline visible from launch, `autofocus` on primary controls (`Start`, `_PowerOrb`), TV remote phrasing (`Press OK to connect`), and copyable `showLink` dialogs for URLs when no browser exists.

### 3.4 Secondary Pages & Embedded Web Dashboard
- **`ServersPage`**, **`AccountsPage`**, **`LogsPage`**, **`ConnectionsView`**, **`HelpPage`**, **`AboutPage`**, **`BypassAppsPage`**, **`WelcomePage`**: Styled uniformly with `#000000` background, `#0D0D0D` cards, `#252525` hairline borders, monochrome flag filters, tabular numbers, and zero feature loss (preserving all tooltips, validations, drag-and-drop handles, and dialogs).
- **`AboutPage` Attribution**: `Made by @shakur4min` as the final line on the About card (replacing `@betelgeuseromaneeconti`), pointing Source Code button to `https://github.com/shakur4min/blackfox`.
- **Web Dashboard (`core/internal/service/web/`)**: Refreshed `index.html`, CSS tokens, and `app.js` using matching `#000000` / `#0D0D0D` / `#252525` dark monochrome design, `BLACKFOX` title & icon, and `https://github.com/shakur4min/blackfox` links without altering API contracts or DOM functionality.
