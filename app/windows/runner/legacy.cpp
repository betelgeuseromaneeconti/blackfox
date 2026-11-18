#include "legacy.h"

#include <windows.h>
#include <shlobj.h>
#include <shobjidl.h>
#include <wrl/client.h>

#include <initializer_list>
#include <thread>
#include <vector>

namespace legacy {

namespace {

constexpr wchar_t kOldExe[] = L"firefox-vpn.exe";
constexpr wchar_t kArmanExe[] = L"arman-vpn.exe";
constexpr wchar_t kNewExe[] = L"BLACKFOX.exe";
constexpr wchar_t kOldShortcut[] = L"Firefox VPN.lnk";
constexpr wchar_t kArmanShortcut[] = L"Arman VPN.lnk";
constexpr wchar_t kNewShortcut[] = L"BLACKFOX.lnk";

bool IsOneOf(const std::wstring& value,
             std::initializer_list<const wchar_t*> names) {
  for (const auto* name : names) {
    if (::CompareStringOrdinal(value.c_str(), -1, name, -1, TRUE) ==
        CSTR_EQUAL) {
      return true;
    }
  }
  return false;
}

// This executable's path, and its folder with a trailing backslash.
std::wstring SelfPath() {
  std::vector<wchar_t> buffer(MAX_PATH);
  for (;;) {
    DWORD n = ::GetModuleFileNameW(nullptr, buffer.data(),
                                   static_cast<DWORD>(buffer.size()));
    if (n == 0) return L"";
    if (n < buffer.size()) return std::wstring(buffer.data(), n);
    buffer.resize(buffer.size() * 2);
  }
}

std::wstring FolderOf(const std::wstring& path) {
  size_t cut = path.find_last_of(L'\\');
  return cut == std::wstring::npos ? L"" : path.substr(0, cut + 1);
}

std::wstring NameOf(const std::wstring& path) {
  size_t cut = path.find_last_of(L'\\');
  return cut == std::wstring::npos ? path : path.substr(cut + 1);
}

bool Exists(const std::wstring& path) {
  return ::GetFileAttributesW(path.c_str()) != INVALID_FILE_ATTRIBUTES;
}

std::wstring KnownFolder(REFKNOWNFOLDERID id) {
  PWSTR path = nullptr;
  std::wstring result;
  if (SUCCEEDED(::SHGetKnownFolderPath(id, 0, nullptr, &path))) {
    result = path;
  }
  ::CoTaskMemFree(path);
  return result;
}

// Retarget a shortcut only when it still points at the expected old binary.
void Retarget(const std::wstring& folder, const wchar_t* file,
              const wchar_t* save_as, const std::wstring& old_exe,
              const std::wstring& new_exe) {
  const std::wstring path = folder + L"\\" + file;
  if (!Exists(path)) return;
  Microsoft::WRL::ComPtr<IShellLinkW> link;
  if (FAILED(::CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER,
                                IID_PPV_ARGS(&link)))) {
    return;
  }
  Microsoft::WRL::ComPtr<IPersistFile> persist;
  if (FAILED(link.As(&persist)) || FAILED(persist->Load(path.c_str(), STGM_READ))) {
    return;
  }
  wchar_t target[MAX_PATH] = {};
  if (FAILED(link->GetPath(target, MAX_PATH, nullptr, SLGP_RAWPATH)) ||
      ::CompareStringOrdinal(target, -1, old_exe.c_str(), -1, TRUE) != CSTR_EQUAL) {
    return;
  }
  link->SetPath(new_exe.c_str());
  wchar_t icon[MAX_PATH] = {};
  int index = 0;
  if (SUCCEEDED(link->GetIconLocation(icon, MAX_PATH, &index)) &&
      ::CompareStringOrdinal(icon, -1, old_exe.c_str(), -1, TRUE) == CSTR_EQUAL) {
    link->SetIconLocation(new_exe.c_str(), index);
  }
  const std::wstring target_path = folder + L"\\" + save_as;
  if (FAILED(persist->Save(target_path.c_str(), TRUE))) return;
  if (::CompareStringOrdinal(file, -1, save_as, -1, TRUE) != CSTR_EQUAL) {
    ::DeleteFileW(path.c_str());
  }
}

void RetargetFolder(const std::wstring& folder,
                    const std::wstring& old_exe,
                    const std::wstring& self,
                    bool keepShortcutNames) {
  if (folder.empty()) return;
  const wchar_t* names[] = {kOldShortcut, kArmanShortcut, kNewShortcut};
  for (const auto* name : names) {
    const wchar_t* destination =
        keepShortcutNames ? name : kNewShortcut;
    Retarget(folder, name, destination, old_exe, self);
  }
}

}  // namespace

bool HandOff(const std::wstring& command_line) {
  const std::wstring self = SelfPath();
  if (!IsOneOf(NameOf(self), {kOldExe, kArmanExe})) return false;
  const std::wstring folder = FolderOf(self);
  const std::wstring next = folder + kNewExe;
  if (!Exists(next)) return false;
  std::wstring command = L"\"" + next + L"\"";
  if (!command_line.empty()) command += L" " + command_line;
  STARTUPINFOW startup = {sizeof(startup)};
  PROCESS_INFORMATION process = {};
  if (!::CreateProcessW(next.c_str(), command.data(), nullptr, nullptr, FALSE,
                        0, nullptr, folder.c_str(), &startup, &process)) {
    return false;
  }
  ::AllowSetForegroundWindow(process.dwProcessId);
  ::CloseHandle(process.hThread);
  ::CloseHandle(process.hProcess);
  return true;
}

void Migrate() {
  const std::wstring self = SelfPath();
  if (!IsOneOf(NameOf(self), {kNewExe})) return;
  const std::wstring folder = FolderOf(self);

  // Upgrade both historical executable names and their Start-menu/Desktop
  // shortcuts to BLACKFOX. Taskbar shortcut filenames are retained so pins
  // are not lost.
  for (const auto* old_name : {kOldExe, kArmanExe}) {
    const std::wstring old_exe = folder + old_name;
    if (!Exists(old_exe)) continue;
    for (const KNOWNFOLDERID* id : {&FOLDERID_Programs, &FOLDERID_Desktop}) {
      RetargetFolder(KnownFolder(*id), old_exe, self, false);
    }
    const std::wstring pinned = KnownFolder(FOLDERID_UserPinned);
    if (!pinned.empty()) {
      RetargetFolder(pinned + L"\\TaskBar", old_exe, self, true);
    }
    std::thread([old_exe] {
      for (int i = 0; i < 50 && Exists(old_exe); ++i) {
        if (::DeleteFileW(old_exe.c_str())) return;
        ::Sleep(200);
      }
    }).detach();
  }
}

}  // namespace legacy
