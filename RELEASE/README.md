# BLACKFOX VPN — Release Documentation

- **Product Name:** BLACKFOX
- **Version:** 2.0.69 (`2.0.69+103`)
- **Design System:** Minimal Victorian Gothic (Monochrome Obsidian, Charcoal, Silver, Frosted Glass)
- **Creator Signature:** Made by Jackdaw
- **License:** GNU General Public License v3.0 (GPL-3.0)

---

## 1. Overview

**BLACKFOX** is a complete product-brand and user-interface redesign of the cross-platform VPN client for Windows Desktop, Android Mobile, Android Tablets/Foldables, Android TV, and Arch Linux.

It preserves 100% of the underlying Go VPN Core capabilities (`core/`):
- HTTP/1.1, HTTP/2, and HTTP/3 (MASQUE / QUIC) edge tunnels using Firefox's uTLS fingerprint (`uTLS`).
- Multi-account management with automatic quota threshold switching, priority ordering (drag-and-drop and up/down controls), backup export/import, and full authentication verification flows (email code, TOTP, unblock code, confirmation link, and in-app browser sign-in).
- Auto Recommended, Auto Fastest, and manual country server selection with real end-to-end HTTP delay measurement, search, and latency/name sorting.
- Smart regional routing (`Iran`, `China`, `Russia`, `Afghanistan`, `Turkey`, `Indonesia`, `Brazil`), custom direct/block domain/IP/CIDR/geosite/geoip rules, ad blocking, and destination routing tester.
- Encrypted DNS (System, Auto DoH, Cloudflare DoH/DoT, Google DoH, Quad9 DoH, Custom DoH/DoT) with side-by-side DNS leak/filtering test.
- Censorship circumvention: Shared API Relay, Personal API Relay with live health diagnostics, Encrypted Client Hello (ECH), TLS ClientHello fragmentation (`off`, `auto`, `first-byte`, `sni`, `record`), and Upstream SOCKS5 Proxy.
- Windows Wintun service (`TUN` mode) with per-program and UDP-only bypass, plus Android `VpnService` (`hev-socks5-tunnel`) with per-app include/exclude routing, Quick Settings Tile, Home Screen Widget, and Android TV D-pad navigation.

---

## 2. Reproducible Build Instructions

### Prerequisites
To compile all native binary targets from source, ensure the following toolchains are installed and in `PATH`:
1. **Flutter SDK** (`>= 3.13.5`)
2. **Go Toolchain** (`>= 1.26.1`)
3. **Windows Target**:
   - Visual Studio 2022/2026 C++ Desktop Development workload & Windows 10/11 SDK (`d3dcompiler_47.dll`)
   - Inno Setup 6 (`ISCC.exe`) for building `BLACKFOX-VPN-Setup.exe` / `BLACKFOX-Setup.exe`
4. **Android & Android TV Targets**:
   - Android SDK (`ANDROID_HOME`) with NDK `28.2.13676358`
   - JDK 17+ (`JAVA_HOME`)
   - `gomobile` and `gobind` (`golang.org/x/mobile/cmd/gomobile`)
5. **Arch Linux Target**:
   - Arch Linux environment with `base-devel`, `flutter`, `go`, `cmake`, `ninja`, `gtk3`, `libayatana-appindicator`, and `makepkg`

### Running the Automated Build Pipeline
From the repository root in PowerShell:

```powershell
# Run full verification, icon generation, license staging, and all available platform builds:
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build-all.ps1

# Or build individual platforms directly:
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build-windows.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build-android.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build-android-tv.ps1
```

On Arch Linux:
```bash
bash scripts/build-arch-linux.sh
```

---

## 3. Target Release Structure

When all platform toolchains are present and executed, artifacts are placed in:

```text
RELEASE/
├── README.md
├── BUILD-REPORT.md
├── TEST-REPORT.md
├── LICENSES/
│   ├── LICENSE-GPL-3.0.txt
│   ├── THIRD-PARTY-NOTICES.md
│   ├── Inter-OFL.txt
│   ├── Vazirmatn-OFL.txt
│   └── flag-icons-MIT-LICENSE.txt
├── ARCH-LINUX/
│   ├── PKGBUILD/
│   │   ├── PKGBUILD
│   │   └── blackfox.desktop
│   └── x86_64/                  (populated by scripts/build-arch-linux.sh on Arch Linux)
│       ├── BLACKFOX-2.0.69-1-x86_64.pkg.tar.zst
│       └── Portable/
├── WINDOWS/
│   └── x64/                     (populated by scripts/build-windows.ps1 when Flutter + Go + Inno Setup are installed)
│       ├── BLACKFOX-Setup.exe
│       ├── BLACKFOX-VPN-Setup.exe
│       └── Portable/
│           ├── BLACKFOX.exe
│           ├── blackfox.exe
│           └── core/
├── ANDROID/                     (populated by scripts/build-android.ps1 when Flutter + Go + gomobile + NDK are installed)
│   ├── armeabi-v7a/BLACKFOX-armeabi-v7a.apk
│   ├── arm64-v8a/BLACKFOX-arm64-v8a.apk
│   ├── x86_64/BLACKFOX-x86_64.apk
│   └── universal/BLACKFOX-universal.apk
└── ANDROID-TV/                  (populated by scripts/build-android-tv.ps1)
    └── BLACKFOX-AndroidTV.apk
```

> **Note:** In accordance with release engineering policy, empty target directories and placeholder binaries are never created when a compiler/SDK is absent on the build host. See [BUILD-REPORT.md](file:///c:/Users/Betelgeuse/Documents/BlackFox-version2.0.69/RELEASE/BUILD-REPORT.md) for the exact host toolchain report.

---

## 4. Legal & Non-Affiliation Notice

- **GPL-3.0:** BLACKFOX is free and open-source software licensed under the GNU General Public License v3.0. See `LICENSES/LICENSE-GPL-3.0.txt`.
- **Mozilla Non-Affiliation:** BLACKFOX is an independent project and is **not** affiliated with, endorsed by, sponsored by, or owned by Mozilla Corporation or Firefox.
- **Engine Attribution:** The Go VPN Core engine (`core/`) is derived from the original open-source project under GPL-3.0; original copyright notices and third-party licenses are preserved in `LICENSES/`.

Made by Jackdaw
