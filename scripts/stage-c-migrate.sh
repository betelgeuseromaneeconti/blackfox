#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f "core/go.mod" || ! -f "app/pubspec.yaml" ]]; then
  echo "ERROR: Run from the repository root (core/go.mod and app/pubspec.yaml must exist)." >&2
  exit 1
fi

REF_NAME="${GITHUB_REF_NAME:-}"
if [[ -n "${GITHUB_ACTIONS:-}" && "$REF_NAME" != redesign/* ]]; then
  echo "ERROR: Refusing to push Stage C migration on non-redesign branch: '$REF_NAME'" >&2
  exit 1
fi

echo "=== Starting Stage C atomic repository migration on ref '${REF_NAME:-local}' ==="

python3 - <<'PYEOF'
import os
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(".").resolve()
changed_files = []


def read_text_utf8(path: pathlib.Path) -> tuple[str, bool] | tuple[None, bool]:
    try:
        raw = path.read_bytes().decode("utf-8")
    except UnicodeDecodeError:
        return None, False
    is_crlf = "\r\n" in raw
    if is_crlf:
        raw = raw.replace("\r\n", "\n")
    return raw, is_crlf


def write_if_changed(path: pathlib.Path, new_text: str, old_text: str, is_crlf: bool = False) -> bool:
    if new_text == old_text:
        return False
    out = new_text.replace("\n", "\r\n") if is_crlf else new_text
    path.write_bytes(out.encode("utf-8"))
    rel = path.relative_to(ROOT).as_posix()
    changed_files.append(rel)
    print(f"UPDATED: {rel}")
    return True


def replace_pairs(text: str, pairs: list[tuple[str, str]]) -> str:
    for old, new in pairs:
        text = text.replace(old, new)
    return text


def apply_to_file(rel_path: str, pairs: list[tuple[str, str]], required: bool = False) -> None:
    p = ROOT / rel_path
    if not p.exists():
        if required:
            raise FileNotFoundError(f"Missing required file: {rel_path}")
        print(f"SKIP (not found): {rel_path}")
        return
    old, is_crlf = read_text_utf8(p)
    if old is None:
        print(f"SKIP (binary/non-utf8): {rel_path}")
        return
    new = replace_pairs(old, pairs)
    write_if_changed(p, new, old, is_crlf)


# ---------------------------------------------------------------------------
# 1. core/go.mod and all .go files under core/
# ---------------------------------------------------------------------------
apply_to_file(
    "core/go.mod",
    [
        ("github.com/betelgeuseromaneeconti/blackfox/core", "github.com/shakur4min/blackfox/core"),
        ("github.com/armanlife/arman-vpn-client/core", "github.com/shakur4min/blackfox/core"),
    ],
    required=True,
)

for go_file in sorted((ROOT / "core").rglob("*.go")):
    old, is_crlf = read_text_utf8(go_file)
    if old is None:
        continue
    new = replace_pairs(
        old,
        [
            ("github.com/betelgeuseromaneeconti/blackfox", "github.com/shakur4min/blackfox"),
            ("com.betelgeuseromaneeconti.blackfox", "com.shakur4min.blackfox"),
            ("https://github.com/armanlife/arman-vpn-client", "https://github.com/shakur4min/blackfox"),
            ("armanlife/arman-vpn-client", "shakur4min/blackfox"),
        ],
    )
    write_if_changed(go_file, new, old, is_crlf)

# Log non-import Go changes & legacy files for audit clarity
for inspect_go in [
    "core/cmd/blackfox-core/commands.go",
    "core/cmd/blackfox-tun/intro.go",
    "core/internal/service/tun.go",
    "core/internal/tunapi/socket_darwin.go",
    "core/internal/tunservice/service_linux.go",
    "core/internal/tunservice/legacy_windows.go",
    "core/internal/update/legacy_linux.go",
    "core/internal/update/legacy_linux_test.go",
    "core/internal/update/process_darwin_test.go",
    "core/internal/update/update.go",
]:
    p = ROOT / inspect_go
    if p.exists():
        print(f"--- Audit {inspect_go} ---")
        for i, line in enumerate(p.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            if any(k in line.lower() for k in ("shakur4min", "betelgeuse", "arman", "firefox", "blackfox")):
                print(f"  L{i}: {line}")

# ---------------------------------------------------------------------------
# 2. Web Dashboard (core/internal/service/web/)
# ---------------------------------------------------------------------------
web_dir = ROOT / "core/internal/service/web"
if web_dir.exists():
    for web_file in sorted(web_dir.rglob("*")):
        if not web_file.is_file() or web_file.suffix.lower() not in {".html", ".js", ".css", ".json", ".svg", ".txt"}:
            continue
        old, is_crlf = read_text_utf8(web_file)
        if old is None:
            continue
        new = replace_pairs(
            old,
            [
                (
                    "https://github.com/armanlife/arman-vpn-client/blob/main/docs/BROWSER-SIGNIN.md",
                    "https://github.com/shakur4min/blackfox/blob/main/docs/BROWSER-SIGNIN.md",
                ),
                ("https://github.com/armanlife/arman-vpn-client", "https://github.com/shakur4min/blackfox"),
                ("armanlife/arman-vpn-client", "shakur4min/blackfox"),
                ("github.com/betelgeuseromaneeconti/blackfox", "github.com/shakur4min/blackfox"),
                ("arman-vpn-core", "blackfox-vpn-core"),
                ("Arman-VPN-backup.zip", "BLACKFOX-backup.zip"),
            ],
        )
        write_if_changed(web_file, new, old, is_crlf)

# ---------------------------------------------------------------------------
# 3. Android (app/android/)
# ---------------------------------------------------------------------------
apply_to_file(
    "app/android/app/proguard-rules.pro",
    [
        ("com.arman.firefoxvpn.Tun2Socks", "com.shakur4min.blackfox.Tun2Socks"),
        ("com.betelgeuseromaneeconti.blackfox", "com.shakur4min.blackfox"),
    ],
)

android_exts = {".kt", ".java", ".kts", ".gradle", ".xml", ".pro", ".properties", ".c", ".h", ".cpp", ".mk", ".txt"}
for f in sorted((ROOT / "app/android").rglob("*")):
    if not f.is_file() or f.suffix.lower() not in android_exts:
        continue
    if "/build/" in f.as_posix():
        continue
    old, is_crlf = read_text_utf8(f)
    if old is None:
        continue
    new = replace_pairs(
        old,
        [
            ("com.betelgeuseromaneeconti.blackfox", "com.shakur4min.blackfox"),
            ("com/betelgeuseromaneeconti/blackfox", "com/shakur4min/blackfox"),
        ],
    )
    write_if_changed(f, new, old, is_crlf)

old_kt_dir = ROOT / "app/android/app/src/main/kotlin/com/betelgeuseromaneeconti/blackfox"
new_kt_dir = ROOT / "app/android/app/src/main/kotlin/com/shakur4min/blackfox"
if old_kt_dir.exists():
    new_kt_dir.mkdir(parents=True, exist_ok=True)
    for item in sorted(old_kt_dir.iterdir()):
        dst = new_kt_dir / item.name
        subprocess.run(["git", "mv", str(item), str(dst)], check=True)
        print(f"MOVED: {item.relative_to(ROOT).as_posix()} -> {dst.relative_to(ROOT).as_posix()}")
    # Remove empty old directory tree cleanly
    for parent in [old_kt_dir, old_kt_dir.parent]:
        try:
            parent.rmdir()
        except OSError:
            pass

# ---------------------------------------------------------------------------
# 4. Windows (app/windows/)
# ---------------------------------------------------------------------------
apply_to_file(
    "app/windows/runner/Runner.rc",
    [
        ('"CompanyName", "betelgeuseromaneeconti"', '"CompanyName", "shakur4min"'),
        ('"LegalCopyright", "Copyright (C) 2026 Jackdaw (GPL-3.0)"', '"LegalCopyright", "Copyright (C) 2026 shakur4min (GPL-3.0)"'),
        ('"OriginalFilename", "BLACKFOX.exe"', '"OriginalFilename", "blackfox-vpn.exe"'),
        ("betelgeuseromaneeconti", "shakur4min"),
    ],
)

apply_to_file(
    "app/windows/installer/BLACKFOX.iss",
    [
        ("https://github.com/betelgeuseromaneeconti/blackfox", "https://github.com/shakur4min/blackfox"),
        ("betelgeuseromaneeconti", "shakur4min"),
        ("https://github.com/armanlife/arman-vpn-client", "https://github.com/shakur4min/blackfox"),
    ],
)

# Audit Windows executable names (CMakeLists.txt + BLACKFOX.iss + legacy.cpp)
for win_audit in ["app/windows/CMakeLists.txt", "app/windows/installer/BLACKFOX.iss"]:
    p = ROOT / win_audit
    if p.exists():
        print(f"--- Audit {win_audit} ---")
        for i, line in enumerate(p.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            if any(k in line.lower() for k in ("binary_name", "myappexe", "shakur4min", "betelgeuse", "arman", "blackfox")):
                print(f"  L{i}: {line}")

# Update legacy.cpp active target constants carefully while keeping old Firefox/Arman cleanup intact if structured cleanly
legacy_cpp = ROOT / "app/windows/runner/legacy.cpp"
if legacy_cpp.exists():
    old, is_crlf = read_text_utf8(legacy_cpp)
    if old is not None:
        print("--- Audit app/windows/runner/legacy.cpp (before) ---")
        for i, line in enumerate(old.splitlines()[:45], 1):
            print(f"  L{i}: {line}")
        new = replace_pairs(
            old,
            [
                ('kNewExe = L"arman-vpn.exe"', 'kNewExe = L"blackfox-vpn.exe"'),
                ('kNewShortcut = L"Arman VPN.lnk"', 'kNewShortcut = L"BLACKFOX.lnk"'),
                ('betelgeuseromaneeconti', 'shakur4min'),
            ],
        )
        write_if_changed(legacy_cpp, new, old, is_crlf)

for win_f in sorted((ROOT / "app/windows").rglob("*")):
    if not win_f.is_file() or win_f.suffix.lower() not in {".cpp", ".h", ".rc", ".iss", ".txt", ".cmake", ".manifest"}:
        continue
    old, is_crlf = read_text_utf8(win_f)
    if old is None:
        continue
    new = replace_pairs(
        old,
        [
            ("github.com/betelgeuseromaneeconti/blackfox", "github.com/shakur4min/blackfox"),
            ("com.betelgeuseromaneeconti.blackfox", "com.shakur4min.blackfox"),
            ("betelgeuseromaneeconti", "shakur4min"),
        ],
    )
    write_if_changed(win_f, new, old, is_crlf)

# ---------------------------------------------------------------------------
# 5. Linux desktop, Arch PKGBUILD, install.sh, core/scripts/install-systemd.sh
# ---------------------------------------------------------------------------
apply_to_file(
    "app/linux/CMakeLists.txt",
    [
        ("com.betelgeuseromaneeconti.blackfox", "com.shakur4min.blackfox"),
        ("betelgeuseromaneeconti", "shakur4min"),
    ],
)

apply_to_file(
    "app/linux/runner/my_application.cc",
    [
        ("com.betelgeuseromaneeconti.blackfox", "com.shakur4min.blackfox"),
        ("betelgeuseromaneeconti", "shakur4min"),
    ],
)

apply_to_file(
    "RELEASE/ARCH-LINUX/PKGBUILD/PKGBUILD",
    [
        ("https://github.com/betelgeuseromaneeconti/blackfox", "https://github.com/shakur4min/blackfox"),
        ("https://github.com/armanlife/arman-vpn-client", "https://github.com/shakur4min/blackfox"),
        ("github.com/armanlife/arman-vpn-client", "github.com/shakur4min/blackfox"),
        ("github.com/armanlife/firefox-vpn-client", "github.com/shakur4min/blackfox"),
        ("github.com/shakur4min/arman-vpn-client", "github.com/shakur4min/blackfox"),
        ("betelgeuseromaneeconti", "shakur4min"),
        ("armanlife", "shakur4min"),
        ("Jackdaw", "shakur4min"),
        ("./cmd/arman-vpn-core", "./cmd/blackfox-core"),
        ("./cmd/arman-vpn-tun", "./cmd/blackfox-tun"),
        ("arman-vpn-core", "blackfox-vpn-core"),
        ("arman-vpn-tun", "blackfox-vpn-tun"),
    ],
)

# Point PKGBUILD at the real Linux Flutter binary name from app/linux/CMakeLists.txt
linux_cmake = ROOT / "app/linux/CMakeLists.txt"
linux_binary = None
if linux_cmake.exists():
    mm = re.search(r'set\(BINARY_NAME\s+"([^"]+)"\)', linux_cmake.read_text(encoding="utf-8", errors="replace"))
    if mm:
        linux_binary = mm.group(1)
print(f"Linux BINARY_NAME = {linux_binary}")
if linux_binary:
    apply_to_file(
        "RELEASE/ARCH-LINUX/PKGBUILD/PKGBUILD",
        [
            ("/opt/blackfox/arman-vpn\"", f"/opt/blackfox/{linux_binary}\""),
            ("/opt/blackfox/arman-vpn ", f"/opt/blackfox/{linux_binary} "),
            ("/opt/blackfox/arman-vpn\n", f"/opt/blackfox/{linux_binary}\n"),
            ("/opt/blackfox/arman-vpn'", f"/opt/blackfox/{linux_binary}'"),
        ],
    )

# Normalize pkgver in PKGBUILD to 2.0.69 if outdated
pkgbuild_path = ROOT / "RELEASE/ARCH-LINUX/PKGBUILD/PKGBUILD"
if pkgbuild_path.exists():
    old, is_crlf = read_text_utf8(pkgbuild_path)
    if old is not None:
        new = re.sub(r"^pkgver=.*$", "pkgver=2.0.69", old, flags=re.MULTILINE)
        write_if_changed(pkgbuild_path, new, old, is_crlf)
    print("--- PKGBUILD after migration ---")
    print(pkgbuild_path.read_text(encoding="utf-8", errors="replace"))

apply_to_file(
    "RELEASE/ARCH-LINUX/PKGBUILD/blackfox.desktop",
    [
        ("StartupWMClass=com.betelgeuseromaneeconti.blackfox", "StartupWMClass=com.shakur4min.blackfox"),
        ("StartupWMClass=com.arman.firefoxvpn", "StartupWMClass=com.shakur4min.blackfox"),
        ("com.betelgeuseromaneeconti.blackfox", "com.shakur4min.blackfox"),
        ("Jackdaw", "shakur4min"),
    ],
)

# .gitignore: ignore the current build outputs instead of the old Arman ones
apply_to_file(
    ".gitignore",
    [
        ("/core/cmd/arman-vpn-core/", "/core/cmd/blackfox-core/"),
        ("/core/cmd/arman-vpn-tun/", "/core/cmd/blackfox-tun/"),
        ("/core/arman-vpn-core", "/core/blackfox-vpn-core"),
        ("/core/arman-vpn-tun", "/core/blackfox-vpn-tun"),
        ("arman-vpn-core", "blackfox-vpn-core"),
        ("arman-vpn-tun", "blackfox-vpn-tun"),
    ],
)

# Also check any other files in RELEASE/
for rel_f in sorted((ROOT / "RELEASE").rglob("*")):
    if not rel_f.is_file() or rel_f.suffix.lower() not in {".sh", ".desktop", ".service", ".md", ".txt", ""}:
        continue
    old, is_crlf = read_text_utf8(rel_f)
    if old is None:
        continue
    new = replace_pairs(
        old,
        [
            ("github.com/betelgeuseromaneeconti/blackfox", "github.com/shakur4min/blackfox"),
            ("com.betelgeuseromaneeconti.blackfox", "com.shakur4min.blackfox"),
            ("betelgeuseromaneeconti", "shakur4min"),
        ],
    )
    write_if_changed(rel_f, new, old, is_crlf)

# install.sh: preserve explicit legacy migration while updating active branding/repo/IDs
install_sh = ROOT / "install.sh"
if install_sh.exists():
    old, is_crlf = read_text_utf8(install_sh)
    if old is not None:
        new = replace_pairs(
            old,
            [
                ("github.com/betelgeuseromaneeconti/blackfox", "github.com/shakur4min/blackfox"),
                ("betelgeuseromaneeconti/blackfox", "shakur4min/blackfox"),
                ("com.betelgeuseromaneeconti.blackfox", "com.shakur4min.blackfox"),
                ("https://github.com/armanlife/arman-vpn-client", "https://github.com/shakur4min/blackfox"),
                ("armanlife/arman-vpn-client", "shakur4min/blackfox"),
            ],
        )
        write_if_changed(install_sh, new, old, is_crlf)

# core/scripts/install-systemd.sh: migrate active branding/paths while keeping/extending legacy migration
systemd_sh = ROOT / "core/scripts/install-systemd.sh"
if systemd_sh.exists():
    old, is_crlf = read_text_utf8(systemd_sh)
    if old is not None:
        print("--- Audit core/scripts/install-systemd.sh ---")
        # Locate migrate_legacy() function if present so we don't clobber legacy unit/user/dir probes
        m = re.search(r"(migrate_legacy\s*\(\)\s*\{.*?\n\})", old, flags=re.DOTALL)
        if m:
            before_fn = old[: m.start()]
            fn_body = m.group(1)
            after_fn = old[m.end() :]

            active_pairs = [
                ("https://github.com/armanlife/arman-vpn-client", "https://github.com/shakur4min/blackfox"),
                ("armanlife/arman-vpn-client", "shakur4min/blackfox"),
                ("github.com/betelgeuseromaneeconti/blackfox", "github.com/shakur4min/blackfox"),
                ("betelgeuseromaneeconti/blackfox", "shakur4min/blackfox"),
                ("./cmd/arman-vpn-core", "./cmd/blackfox-core"),
                ("./cmd/arman-vpn-tun", "./cmd/blackfox-tun"),
                ("arman-vpn-core", "blackfox-vpn-core"),
                ("arman-vpn-tun", "blackfox-vpn-tun"),
                ("/opt/arman-vpn", "/opt/blackfox"),
                ("/etc/arman-vpn", "/etc/blackfox"),
                ("/var/lib/arman-vpn", "/var/lib/blackfox"),
                ("/var/log/arman-vpn", "/var/log/blackfox"),
                ("arman-vpn", "blackfox-vpn"),
                ("Arman VPN", "BLACKFOX"),
                ("ArmanVPN", "BLACKFOX"),
            ]

            new_before = replace_pairs(before_fn, active_pairs)
            new_after = replace_pairs(after_fn, active_pairs)

            new_fn = fn_body.replace('for old in firefox-vpn', 'for old in firefox-vpn arman-vpn')
            if 'arman-vpn' not in new_fn:
                print("NOTE: migrate_legacy() did not match 'for old in firefox-vpn'; inspect printed body:")
                print(new_fn)
            else:
                print("Extended migrate_legacy() loop to include arman-vpn alongside firefox-vpn.")

            new = new_before + new_fn + new_after
        else:
            print("WARNING: migrate_legacy() not found by regex in install-systemd.sh; applying active replacements only.")
            new = replace_pairs(
                old,
                [
                    ("https://github.com/armanlife/arman-vpn-client", "https://github.com/shakur4min/blackfox"),
                    ("armanlife/arman-vpn-client", "shakur4min/blackfox"),
                    ("github.com/betelgeuseromaneeconti/blackfox", "github.com/shakur4min/blackfox"),
                    ("betelgeuseromaneeconti/blackfox", "shakur4min/blackfox"),
                    ("./cmd/arman-vpn-core", "./cmd/blackfox-core"),
                    ("./cmd/arman-vpn-tun", "./cmd/blackfox-tun"),
                    ("arman-vpn-core", "blackfox-vpn-core"),
                    ("arman-vpn-tun", "blackfox-vpn-tun"),
                    ("/opt/arman-vpn", "/opt/blackfox"),
                    ("/etc/arman-vpn", "/etc/blackfox"),
                    ("/var/lib/arman-vpn", "/var/lib/blackfox"),
                    ("/var/log/arman-vpn", "/var/log/blackfox"),
                    ("arman-vpn", "blackfox-vpn"),
                    ("Arman VPN", "BLACKFOX"),
                ],
            )
        write_if_changed(systemd_sh, new, old, is_crlf)

# ---------------------------------------------------------------------------
# 6. macOS (app/macos/)
# ---------------------------------------------------------------------------
apply_to_file(
    "app/macos/Runner/Configs/AppInfo.xcconfig",
    [
        ("com.betelgeuseromaneeconti.blackfox", "com.shakur4min.blackfox"),
        ("Jackdaw", "shakur4min"),
        ("betelgeuseromaneeconti", "shakur4min"),
    ],
)

apply_to_file(
    "app/macos/Runner/MainFlutterWindow.swift",
    [
        ("com.betelgeuseromaneeconti.blackfox", "com.shakur4min.blackfox"),
        ("betelgeuseromaneeconti", "shakur4min"),
    ],
)

mac_exts = {".plist", ".xcscheme", ".pbxproj", ".swift", ".xcconfig", ".entitlements", ".strings", ".sh"}
for mac_f in sorted((ROOT / "app/macos").rglob("*")):
    if not mac_f.is_file() or mac_f.suffix.lower() not in mac_exts:
        continue
    old, is_crlf = read_text_utf8(mac_f)
    if old is None:
        continue
    new = replace_pairs(
        old,
        [
            ("com.betelgeuseromaneeconti.blackfox", "com.shakur4min.blackfox"),
            ("betelgeuseromaneeconti", "shakur4min"),
            ("Arman VPN.app", "BLACKFOX.app"),
            ("Arman VPN", "BLACKFOX"),
            ("arman-vpn-core", "blackfox-vpn-core"),
            ("arman-vpn-tun", "blackfox-vpn-tun"),
        ],
    )
    write_if_changed(mac_f, new, old, is_crlf)

# ---------------------------------------------------------------------------
# 7. Docker, GitHub workflows, actions & issue templates
# ---------------------------------------------------------------------------
apply_to_file(
    "Dockerfile",
    [
        ("https://github.com/armanlife/arman-vpn-client", "https://github.com/shakur4min/blackfox"),
        ("https://github.com/betelgeuseromaneeconti/blackfox", "https://github.com/shakur4min/blackfox"),
        ("github.com/armanlife/arman-vpn-client", "github.com/shakur4min/blackfox"),
        ("github.com/betelgeuseromaneeconti/blackfox", "github.com/shakur4min/blackfox"),
        ("armanlife/arman-vpn-client", "shakur4min/blackfox"),
        ("betelgeuseromaneeconti/blackfox", "shakur4min/blackfox"),
        ("./cmd/arman-vpn-core", "./cmd/blackfox-core"),
        ("arman-vpn-core", "blackfox-vpn-core"),
        ("/var/lib/arman-vpn", "/var/lib/blackfox"),
        ("/usr/local/share/arman-vpn", "/usr/local/share/blackfox"),
        ("arman-vpn", "blackfox-vpn"),
        ("Arman VPN", "BLACKFOX"),
    ],
)

# docker/entrypoint.sh: preserve/add legacy fallback from /var/lib/arman-vpn/config.json -> /var/lib/blackfox/config.json
entrypoint_path = ROOT / "docker/entrypoint.sh"
if entrypoint_path.exists():
    old, is_crlf = read_text_utf8(entrypoint_path)
    if old is not None:
        new = replace_pairs(
            old,
            [
                ("arman-vpn-core", "blackfox-vpn-core"),
                ("/var/lib/arman-vpn", "/var/lib/blackfox"),
                ("Arman VPN", "BLACKFOX"),
            ],
        )
        legacy_fallback = (
            'if [ ! -f /var/lib/blackfox/config.json ] && [ -f /var/lib/arman-vpn/config.json ]; then\n'
            '  mkdir -p /var/lib/blackfox\n'
            '  cp -a /var/lib/arman-vpn/. /var/lib/blackfox/\n'
            'fi\n'
        )
        if "/var/lib/arman-vpn/config.json" not in new:
            lines = new.splitlines(keepends=True)
            if lines and lines[0].startswith("#!"):
                insert_idx = 2 if len(lines) > 1 and lines[1].strip().startswith("set ") else 1
                lines.insert(insert_idx, legacy_fallback)
                new = "".join(lines)
            else:
                new = legacy_fallback + new
        write_if_changed(entrypoint_path, new, old, is_crlf)

for gh_file in [
    # NOTE: .github/workflows/* cannot be pushed by GITHUB_TOKEN (no `workflows` permission);
    # docker.yml is updated separately through the GitHub web UI.
    ".github/actions/build-profile/action.yml",
    ".github/ISSUE_TEMPLATE/bug_report.yml",
    ".github/ISSUE_TEMPLATE/feature_request.yml",
]:
    apply_to_file(
        gh_file,
        [
            ("https://github.com/betelgeuseromaneeconti/blackfox", "https://github.com/shakur4min/blackfox"),
            ("https://github.com/armanlife/arman-vpn-client", "https://github.com/shakur4min/blackfox"),
            ("github.com/betelgeuseromaneeconti/blackfox", "github.com/shakur4min/blackfox"),
            ("github.com/armanlife/arman-vpn-client", "github.com/shakur4min/blackfox"),
            ("betelgeuseromaneeconti/blackfox", "shakur4min/blackfox"),
            ("armanlife/arman-vpn-client", "shakur4min/blackfox"),
            ("arman-vpn-core", "blackfox-vpn-core"),
            ("Arman VPN", "BLACKFOX"),
        ],
    )

# ---------------------------------------------------------------------------
# 8. scripts/*.ps1 & scripts/*.sh (excluding scripts/stage-c-migrate.sh)
# ---------------------------------------------------------------------------
for script_f in sorted((ROOT / "scripts").rglob("*")):
    if not script_f.is_file() or script_f.name == "stage-c-migrate.sh":
        continue
    if script_f.suffix.lower() not in {".ps1", ".sh", ".py", ".txt", ".md"}:
        continue
    old, is_crlf = read_text_utf8(script_f)
    if old is None:
        continue
    new = replace_pairs(
        old,
        [
            ("github.com/betelgeuseromaneeconti/blackfox", "github.com/shakur4min/blackfox"),
            ("betelgeuseromaneeconti/blackfox", "shakur4min/blackfox"),
            ("com.betelgeuseromaneeconti.blackfox", "com.shakur4min.blackfox"),
            ("betelgeuseromaneeconti", "shakur4min"),
            ("https://github.com/armanlife/arman-vpn-client", "https://github.com/shakur4min/blackfox"),
            ("github.com/armanlife/arman-vpn-client", "github.com/shakur4min/blackfox"),
            ("armanlife/arman-vpn-client", "shakur4min/blackfox"),
            ("./cmd/arman-vpn-core", "./cmd/blackfox-core"),
            ("./cmd/arman-vpn-tun", "./cmd/blackfox-tun"),
            ("arman-vpn-core", "blackfox-vpn-core"),
            ("arman-vpn-tun", "blackfox-vpn-tun"),
            ("arman-vpn", "blackfox-vpn"),
            ("Arman VPN", "BLACKFOX"),
            ("ArmanVPN", "BLACKFOX"),
            ("Jackdaw", "shakur4min"),
        ],
    )
    write_if_changed(script_f, new, old, is_crlf)

print(f"\nTotal files updated: {len(changed_files)}")
PYEOF

# Remove this one-shot migration script before staging
rm -f scripts/stage-c-migrate.sh

echo "=== Audit diff for non-Go files ==="
git diff -- . ':!*.go' || true
git status --short

echo "=== Sanity grep for remaining old identifiers (excluding docs/, core/scripts/install-systemd.sh migrate_legacy, legacy*.go, legacy.cpp) ==="
python3 - <<'PYEOF'
import pathlib
import re
import sys

ROOT = pathlib.Path(".").resolve()
PAT = re.compile(r"betelgeuseromaneeconti|armanlife|arman-vpn|Arman\s*VPN|ArmanVPN|Jackdaw|com\.arman\.firefoxvpn", re.IGNORECASE)
HARD_FAIL_PAT = re.compile(r"betelgeuseromaneeconti|armanlife|com\.arman\.firefoxvpn", re.IGNORECASE)

TEXT_EXTS = {
    ".go", ".mod", ".dart", ".yaml", ".yml", ".sh", ".ps1", ".py",
    ".kt", ".java", ".kts", ".gradle", ".xml", ".pro", ".properties",
    ".c", ".h", ".cpp", ".cc", ".swift", ".plist", ".xcconfig",
    ".xcscheme", ".pbxproj", ".iss", ".rc", ".cmake", ".html", ".js",
    ".css", ".json", ".desktop", ".service", "",
}

hard_failures = []
for p in sorted(ROOT.rglob("*")):
    if not p.is_file():
        continue
    rel = p.relative_to(ROOT).as_posix()
    if rel.startswith(".git/") or rel.startswith(".github/workflows/") or rel.startswith("docs/") or "/build/" in rel or rel.endswith(".png") or rel.endswith(".ico"):
        continue
    if p.suffix.lower() not in TEXT_EXTS and p.name not in {"Dockerfile", "PKGBUILD", "CMakeLists.txt", "Makefile"}:
        continue
    try:
        content = p.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue
    for lineno, line in enumerate(content.splitlines(), 1):
        if PAT.search(line):
            print(f"AUDIT {rel}:{lineno}: {line.strip()[:160]}")
            # Explicit legacy-upgrade fixtures (testing updates FROM old installs) are allowed.
            legacy_fixture = rel == "scripts/test-update-macos.sh" and (
                line.strip().startswith("old_module=") or line.strip().startswith("label=com.arman.firefoxvpn")
            )
            if HARD_FAIL_PAT.search(line) and not legacy_fixture:
                hard_failures.append(f"{rel}:{lineno}: {line.strip()[:160]}")

if hard_failures:
    print("\nERROR: Hard-fail legacy identifiers still present:", file=sys.stderr)
    for item in hard_failures:
        print(f"  {item}", file=sys.stderr)
    sys.exit(1)
PYEOF

if [[ -n "$(git status --porcelain)" ]]; then
  if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    # GITHUB_TOKEN may not touch workflow files; keep them out of this commit.
    git checkout -- .github/workflows 2>/dev/null || true
    git config user.name "shakur4min"
    git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
    git add -A
    git commit -m "chore(stage-c): complete shakur4min/blackfox identity migration"
    echo "=== Commit diff summary ==="
    git diff --stat HEAD~1..HEAD
    echo "=== Pushing to origin HEAD:${REF_NAME} ==="
    git push origin "HEAD:${REF_NAME}"
    echo "Migrated HEAD SHA: $(git rev-parse HEAD)"
  else
    echo "Non-CI run: changes staged in working tree only."
  fi
else
  echo "No Stage C changes to commit."
fi
