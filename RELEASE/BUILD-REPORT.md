# BLACKFOX VPN v1.0.3 — Build & Toolchain Report

- **Product:** BLACKFOX
- **Version:** `1.0.3` (`1.0.3+103`)
- **Creator Signature:** `Made by Jackdaw`
- **Build Host OS:** Windows x64 (`Windows NT 10.0`)

---

## 1. Host Environment & Toolchain Audit

Before executing platform builds, `scripts/build-all.ps1` audited the host system for required compilers, SDKs, and packaging tools:

| Toolchain / Component | Status on Host | Details / Path |
| :--- | :--- | :--- |
| **PowerShell & .NET Drawing** | **AVAILABLE** | Windows PowerShell 5.1 + `System.Drawing` (used by `scripts/generate-icons.ps1`) |
| **Android SDK** | **AVAILABLE** | `F:\Android\Sdk` (with `C:\platform-tools\adb.exe`) |
| **Visual Studio C++ BuildTools** | **AVAILABLE** | `C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools` |
| **Git** | **AVAILABLE** | `C:\Program Files\Git\cmd\git.exe` |
| **Node.js** | **AVAILABLE** | `E:\nde\node.exe` |
| **Flutter SDK (`flutter` / `dart`)** | **MISSING ON HOST** | Not installed on `C:\`, `D:\`, `E:\`, or `F:\` |
| **Go Toolchain (`go`)** | **MISSING ON HOST** | Not installed on `C:\`, `D:\`, `E:\`, or `F:\` |
| **`gomobile` / `gobind`** | **MISSING ON HOST** | Requires Go toolchain + `golang.org/x/mobile/cmd/gomobile` |
| **Inno Setup 6 (`ISCC.exe`)** | **MISSING ON HOST** | Not installed on host |
| **WSL / Arch Linux (`makepkg`)** | **MISSING ON HOST** | `wsl.exe --status` reports Windows Subsystem for Linux is not installed |

---

## 2. Artifacts Generated & Verified on This Host

### 2.1 Monochrome Kitsune Icons, Logos, Banners & Tray Assets (`PASS`)
Generated deterministically via `scripts/generate-icons.ps1` (and supported in `app/tool/app_icons.py`):
- `docs/images/logo.png` (`512x512` monochrome Kitsune character logo)
- `app/assets/logo.png` (`256x256` monochrome Kitsune character logo)
- `app/windows/runner/resources/app_icon.ico` (multi-size Windows executable icon: `16, 20, 24, 32, 40, 48, 64, 128, 256` px)
- `core/internal/desktop/appicon.ico` (multi-size Core executable icon)
- `core/internal/service/web/icon.png` (`192x192` Web Dashboard icon)
- `app/linux/runner/resources/app_icon.png` (`256x256` Linux icon)
- `app/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png` (`16` through `1024` px)
- `app/android/app/src/main/res/mipmap-*/ic_launcher.png`, `ic_launcher_foreground.png`, `ic_launcher_background.png` (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`)
- `app/android/app/src/main/res/drawable-xhdpi/banner.png` (`320x180` monochrome Android TV Leanback banner)
- `app/android/app/src/main/res/drawable/ic_stat_logo.xml`, `widget_button_on.xml`, `widget_button_off.xml`, `widget_button_connecting.xml` (monochrome Kitsune vector drawables)
- `app/assets/tray/*.ico` & `*.png` (`off`, `on`, `idle`, `error`, `busy1`..`busy4`)
- `core/internal/desktop/tray/*.ico` & `*.png` (`running`, `set`, `running-asleep`, `set-asleep`, `waiting`, `error`, `off`)

### 2.2 Arch Linux Packaging Specification (`PASS`)
- `RELEASE/ARCH-LINUX/PKGBUILD/PKGBUILD` (`pkgname=blackfox`, `pkgver=1.0.3`, `arch=('x86_64' 'aarch64')`)
- `RELEASE/ARCH-LINUX/PKGBUILD/blackfox.desktop`
- `scripts/build-arch-linux.sh`

### 2.3 Legal & License Bundle (`PASS`)
- `RELEASE/LICENSES/LICENSE-GPL-3.0.txt`
- `RELEASE/LICENSES/THIRD-PARTY-NOTICES.md`
- `RELEASE/LICENSES/Inter-OFL.txt`
- `RELEASE/LICENSES/Vazirmatn-OFL.txt`
- `RELEASE/LICENSES/flag-icons-MIT-LICENSE.txt`

### 2.4 Reproducible Build Scripts (`PASS`)
- `scripts/build-all.ps1`
- `scripts/generate-icons.ps1`
- `scripts/build-windows.ps1`
- `scripts/build-android.ps1`
- `scripts/build-android-tv.ps1`
- `scripts/build-arch-linux.sh`

---

## 3. Target Platform Binary Status & Toolchain Blockers

In strict compliance with **Section 3 (Release Directory)** and **Section 7 (Important Build Limitations)** (*"Do not claim that Antigravity can build a platform if the required operating system, SDK, or compiler is unavailable. Do not create empty directories or fake release files. Only include an artifact after a successful build."*):

| Target Platform | Architecture | Build Status | Reason / Blocker on Current Host |
| :--- | :--- | :--- | :--- |
| **Windows Installer & Portable** | `x64` (`amd64`) | **BLOCKED (Missing SDK)** | Requires `flutter` SDK (`>= 3.13.5`), `go` compiler (`>= 1.26.1`), and Inno Setup 6 (`ISCC.exe`), which are not installed on this Windows host. `scripts/build-windows.ps1` is ready and configured for `BLACKFOX` v1.0.3. |
| **Windows 32-bit** | `x86` (`ia32`) | **UNSUPPORTED BY FLUTTER** | Flutter Windows desktop target officially supports `x64` and `arm64` only; 32-bit `x86` Windows desktop targets are not supported by the Flutter engine. |
| **Windows ARM** | `arm64` | **BLOCKED (Missing SDK)** | Requires `flutter` SDK, `go` (`GOARCH=arm64`), and Visual Studio ARM64 C++ build tools. |
| **Android Phone / Tablet APKs** | `armeabi-v7a`, `arm64-v8a`, `x86_64`, `universal` | **BLOCKED (Missing SDK)** | Android SDK (`F:\Android\Sdk`) is present, but `flutter` SDK, `go` compiler, and `gomobile` (`core.aar` binder) are not installed on this host. `scripts/build-android.ps1` is ready to build all APKs once Flutter and Go are installed. |
| **Android 32-bit x86** | `x86` | **UNSUPPORTED BY FLUTTER** | Modern Flutter stable releases deprecated and removed 32-bit `x86` Android JIT/AOT engine binaries (`flutter build apk` supports `armeabi-v7a`, `arm64-v8a`, and `x86_64`). Note that `x86_64` Android emulators and devices run `x86_64` and `universal` APKs natively. |
| **Android TV APK** | `universal` / `arm64-v8a` / `armeabi-v7a` | **BLOCKED (Missing SDK)** | Leanback launcher manifest, monochrome TV banner (`banner.png`), and D-pad focus ring (`FocusRing`) are fully implemented in source; binary compilation requires `flutter` + `go` + `gomobile` via `scripts/build-android-tv.ps1`. |
| **Arch Linux Package & Portable** | `x86_64`, `aarch64` | **BLOCKED (Missing OS/Toolchain)** | Host is Windows without WSL or Linux `flutter`/`go`/`makepkg` toolchain. Native `PKGBUILD`, `blackfox.desktop`, and `scripts/build-arch-linux.sh` are provided in `RELEASE/ARCH-LINUX/PKGBUILD/`. |
| **Arch Linux 32-bit** | `i686` / `armv7h` | **UNSUPPORTED BY FLUTTER** | Arch Linux and the Flutter Linux GTK engine only support 64-bit `x86_64` and `aarch64` targets. |
