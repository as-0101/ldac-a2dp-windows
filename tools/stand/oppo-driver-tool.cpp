#define UNICODE
#define _UNICODE
#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0A00
#include <windows.h>
#include <setupapi.h>
#include <newdev.h>
#include <cfgmgr32.h>
#include <winternl.h>
#include <sddl.h>
#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <cwctype>
#include <cwchar>
#include <iterator>

#pragma comment(lib, "Setupapi.lib")
#pragma comment(lib, "Newdev.lib")
#pragma comment(lib, "Cfgmgr32.lib")
#pragma comment(lib, "Advapi32.lib")

static const wchar_t* kEnumerator = L"BTHENUM";
static const wchar_t* kA2dpUuid = L"{0000110B-0000-1000-8000-00805F9B34FB}";
static const wchar_t* kTargetMac = L"840F2A13E3E2";
static const wchar_t* kDeviceDescription = L"LDAC A2DP Source";

static std::wstring Upper(std::wstring value) {
    std::transform(value.begin(), value.end(), value.begin(),
        [](wchar_t c) { return static_cast<wchar_t>(towupper(c)); });
    return value;
}
static bool ContainsNoCase(const std::wstring& value, const std::wstring& part) {
    return Upper(value).find(Upper(part)) != std::wstring::npos;
}
static std::wstring BaseName(const std::wstring& path) {
    const size_t p = path.find_last_of(L"\\/");
    return p == std::wstring::npos ? path : path.substr(p + 1);
}
static bool IsAdministrator() {
    BOOL member = FALSE;
    PSID adminSid = nullptr;
    SID_IDENTIFIER_AUTHORITY ntAuthority = SECURITY_NT_AUTHORITY;
    if (!AllocateAndInitializeSid(&ntAuthority, 2, SECURITY_BUILTIN_DOMAIN_RID,
        DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0, &adminSid)) return false;
    const BOOL ok = CheckTokenMembership(nullptr, adminSid, &member);
    FreeSid(adminSid);
    return ok && member;
}
static bool IsSupportedOs() {
    using RtlGetVersionFn = LONG(WINAPI*)(PRTL_OSVERSIONINFOW);
    auto fn = reinterpret_cast<RtlGetVersionFn>(
        GetProcAddress(GetModuleHandleW(L"ntdll.dll"), "RtlGetVersion"));
    if (!fn) return false;
    RTL_OSVERSIONINFOW v{};
    v.dwOSVersionInfoSize = sizeof(v);
    return fn(&v) == 0 && v.dwMajorVersion == 10 && v.dwBuildNumber == 20348;
}
static bool IsVmware() {
    HKEY key = nullptr;
    if (RegOpenKeyExW(HKEY_LOCAL_MACHINE,
        L"HARDWARE\\DESCRIPTION\\System\\BIOS", 0, KEY_QUERY_VALUE, &key) != ERROR_SUCCESS)
        return false;
    wchar_t manufacturer[256]{};
    DWORD type = 0, bytes = sizeof(manufacturer);
    const LONG rc = RegQueryValueExW(key, L"SystemManufacturer", nullptr, &type,
        reinterpret_cast<BYTE*>(manufacturer), &bytes);
    RegCloseKey(key);
    return rc == ERROR_SUCCESS && type == REG_SZ &&
        ContainsNoCase(manufacturer, L"VMware");
}
static bool GetDriverInfPath(HDEVINFO set, SP_DEVINFO_DATA& dev, std::wstring& value) {
    HKEY key = SetupDiOpenDevRegKey(set, &dev, DICS_FLAG_GLOBAL, 0, DIREG_DRV, KEY_QUERY_VALUE);
    if (key == INVALID_HANDLE_VALUE) return false;
    wchar_t infPath[MAX_PATH]{};
    DWORD type = 0, bytes = sizeof(infPath);
    const LONG rc = RegQueryValueExW(key, L"InfPath", nullptr, &type,
        reinterpret_cast<BYTE*>(infPath), &bytes);
    RegCloseKey(key);
    if (rc != ERROR_SUCCESS || type != REG_SZ || bytes < sizeof(wchar_t)) return false;
    value.assign(infPath);
    return true;
}
static bool GetInstanceId(HDEVINFO set, SP_DEVINFO_DATA& dev, std::wstring& id) {
    DWORD needed = 0;
    SetupDiGetDeviceInstanceIdW(set, &dev, nullptr, 0, &needed);
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER || needed == 0 || needed > 4096)
        return false;
    std::vector<wchar_t> buffer(needed + 1, L'\0');
    if (!SetupDiGetDeviceInstanceIdW(set, &dev, buffer.data(),
        static_cast<DWORD>(buffer.size()), &needed)) return false;
    id.assign(buffer.data());
    return true;
}
struct TargetDevice {
    HDEVINFO set = INVALID_HANDLE_VALUE;
    SP_DEVINFO_DATA data{};
    std::wstring instanceId;
    std::wstring infPath;
    unsigned int a2dpCount = 0;
    bool found = false;
};
static bool FindTarget(TargetDevice& target, bool requireSingleA2dp = true) {
    target.set = SetupDiGetClassDevsW(nullptr, kEnumerator, nullptr,
        DIGCF_ALLCLASSES | DIGCF_PRESENT);
    if (target.set == INVALID_HANDLE_VALUE) {
        std::wcerr << L"SetupDiGetClassDevs failed: " << GetLastError() << L"\n";
        return false;
    }
    for (DWORD index = 0;; ++index) {
        SP_DEVINFO_DATA dev{};
        dev.cbSize = sizeof(dev);
        if (!SetupDiEnumDeviceInfo(target.set, index, &dev)) {
            if (GetLastError() != ERROR_NO_MORE_ITEMS)
                std::wcerr << L"SetupDiEnumDeviceInfo failed: " << GetLastError() << L"\n";
            break;
        }
        std::wstring id;
        if (!GetInstanceId(target.set, dev, id)) continue;
        if (!ContainsNoCase(id, kA2dpUuid)) continue;
        ++target.a2dpCount;
        if (ContainsNoCase(id, kTargetMac)) {
            target.data = dev;
            target.instanceId = id;
            target.found = true;
        }
    }
    if (!target.found) {
        std::wcerr << L"Target OPPO A2DP devnode not found. Expected peer MAC "
                   << kTargetMac << L".\n";
        return false;
    }
    if (requireSingleA2dp && target.a2dpCount != 1) {
        std::wcerr << L"Refusing install: found " << target.a2dpCount
                   << L" present A2DP devnodes. This test package requires the OPPO "
                      L"to be the only paired/present A2DP sink in the test VM.\n";
        return false;
    }
    GetDriverInfPath(target.set, target.data, target.infPath);
    return true;
}
static bool IsA2dpCompatible(HDEVINFO set, SP_DEVINFO_DATA& dev) {
    DWORD type = 0, required = 0;
    SetupDiGetDeviceRegistryPropertyW(set, &dev, SPDRP_COMPATIBLEIDS,
        &type, nullptr, 0, &required);
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER || required == 0 || required > 65536)
        return false;
    std::vector<wchar_t> ids(required / sizeof(wchar_t) + 2, L'\0');
    if (!SetupDiGetDeviceRegistryPropertyW(set, &dev, SPDRP_COMPATIBLEIDS,
        &type, reinterpret_cast<PBYTE>(ids.data()), required, &required)) return false;
    for (const wchar_t* p = ids.data(); *p; p += wcslen(p) + 1)
        if (ContainsNoCase(p, kA2dpUuid)) return true;
    return false;
}
static bool FindDriver(HDEVINFO set, SP_DEVINFO_DATA& dev,
    const std::wstring& wantedInf, bool rollback, SP_DRVINFO_DATA_W& selected) {
    if (!SetupDiBuildDriverInfoList(set, &dev, SPDIT_COMPATDRIVER)) {
        std::wcerr << L"SetupDiBuildDriverInfoList failed: " << GetLastError() << L"\n";
        return false;
    }
    for (DWORD index = 0;; ++index) {
        SP_DRVINFO_DATA_W info{};
        info.cbSize = sizeof(info);
        if (!SetupDiEnumDriverInfoW(set, &dev, SPDIT_COMPATDRIVER, index, &info)) {
            if (GetLastError() != ERROR_NO_MORE_ITEMS)
                std::wcerr << L"SetupDiEnumDriverInfo failed: " << GetLastError() << L"\n";
            break;
        }
        SP_DRVINFO_DETAIL_DATA_W detail{};
        detail.cbSize = sizeof(detail);
        DWORD required = 0;
        const BOOL detailOk = SetupDiGetDriverInfoDetailW(set, &dev, &info,
            &detail, sizeof(detail), &required);
        if (!detailOk && GetLastError() != ERROR_INSUFFICIENT_BUFFER) continue;
        const std::wstring infName = BaseName(detail.InfFileName);
        const bool match = rollback
            ? (_wcsicmp(infName.c_str(), L"bth.inf") == 0 &&
               ContainsNoCase(info.Description, L"Audio Sink Service"))
            : (_wcsicmp(infName.c_str(), wantedInf.c_str()) == 0 &&
               _wcsicmp(info.Description, kDeviceDescription) == 0);
        if (match) { selected = info; return true; }
    }
    std::wcerr << (rollback
        ? L"Could not find inbox bth.inf / Audio Sink Service in the compatible driver list.\n"
        : L"Could not find the staged LDAC A2DP package in the target's compatible driver list.\n");
    return false;
}
static bool ApplyDriver(TargetDevice& target, bool rollback,
    const std::wstring& wantedInf, bool& reboot) {
    if (!IsA2dpCompatible(target.set, target.data)) {
        std::wcerr << L"Target devnode does not expose the expected A2DP compatible ID.\n";
        return false;
    }
    SP_DRVINFO_DATA_W driver{};
    driver.cbSize = sizeof(driver);
    if (!FindDriver(target.set, target.data, wantedInf, rollback, driver)) return false;
    if (!SetupDiSetSelectedDevice(target.set, &target.data)) {
        std::wcerr << L"SetupDiSetSelectedDevice failed: " << GetLastError() << L"\n";
        return false;
    }
    if (!SetupDiSetSelectedDriverW(target.set, &target.data, &driver)) {
        std::wcerr << L"SetupDiSetSelectedDriver failed: " << GetLastError() << L"\n";
        return false;
    }
    BOOL needReboot = FALSE;
    if (!DiInstallDevice(nullptr, target.set, &target.data, &driver, 0, &needReboot)) {
        std::wcerr << L"DiInstallDevice failed: " << GetLastError() << L"\n";
        return false;
    }
    reboot = needReboot != FALSE;
    std::wcout << (rollback ? L"Inbox bth.inf selected for OPPO devnode.\n"
                            : L"LDAC A2DP selected for the exact OPPO devnode.\n");
    return true;
}
static std::wstring ModuleDirectory() {
    wchar_t path[32768]{};
    DWORD n = GetModuleFileNameW(nullptr, path, static_cast<DWORD>(std::size(path)));
    if (n == 0 || n >= std::size(path)) return {};
    std::wstring p(path, n);
    const size_t slash = p.find_last_of(L"\\/");
    if (slash == std::wstring::npos) return {};
    return p.substr(0, slash);
}
static bool StageInf(const std::wstring& infPath, std::wstring& publishedInf) {
    wchar_t destination[MAX_PATH]{};
    DWORD required = 0;
    if (!SetupCopyOEMInfW(infPath.c_str(), nullptr, SPOST_PATH, 0,
        destination, static_cast<DWORD>(std::size(destination)), &required, nullptr)) {
        std::wcerr << L"SetupCopyOEMInf failed: " << GetLastError() << L"\n";
        return false;
    }
    publishedInf = BaseName(destination);
    std::wcout << L"Staged test INF as " << publishedInf << L"\n";
    return true;
}
static int Status() {
    TargetDevice target;
    if (!FindTarget(target)) {
        if (target.set != INVALID_HANDLE_VALUE) SetupDiDestroyDeviceInfoList(target.set);
        return 2;
    }
    std::wcout << L"Instance ID: " << target.instanceId << L"\n"
               << L"Current INF: " << (target.infPath.empty() ? L"(unavailable)" : target.infPath) << L"\n"
               << L"Present A2DP devnodes: " << target.a2dpCount << L"\n";
    SetupDiDestroyDeviceInfoList(target.set);
    return 0;
}
static int Install() {
    if (!IsAdministrator()) { std::wcerr << L"Run elevated as Administrator.\n"; return 10; }
    if (!IsSupportedOs()) { std::wcerr << L"This test package is restricted to Windows Server 2022 build 20348.\n"; return 11; }
    if (!IsVmware()) { std::wcerr << L"Safety gate: VMware virtual machine not detected. Refusing test-driver installation.\n"; return 12; }
    TargetDevice target;
    if (!FindTarget(target)) {
        if (target.set != INVALID_HANDLE_VALUE) SetupDiDestroyDeviceInfoList(target.set);
        return 13;
    }
    if (_wcsicmp(BaseName(target.infPath).c_str(), L"bth.inf") != 0) {
        std::wcerr << L"Safety gate: expected current inbox driver bth.inf, found "
                   << target.infPath << L". Refusing to overwrite an unexpected driver.\n";
        SetupDiDestroyDeviceInfoList(target.set);
        return 14;
    }
    std::wcout << L"\nTEST VM ONLY. Confirm that this VM has a restorable snapshot and that "
                  L"the OPPO earbuds are the only present A2DP sink.\n"
                  L"Type I_HAVE_A_SNAPSHOT_TO_CONTINUE: ";
    std::wstring confirmation;
    std::getline(std::wcin, confirmation);
    if (confirmation != L"I_HAVE_A_SNAPSHOT_TO_CONTINUE") {
        std::wcerr << L"Confirmation not received. No changes made.\n";
        SetupDiDestroyDeviceInfoList(target.set);
        return 15;
    }
    const std::wstring dir = ModuleDirectory();
    const std::wstring infPath = dir + L"\\LdacA2dp.inf";
    const DWORD attrs = GetFileAttributesW(infPath.c_str());
    if (dir.empty() || attrs == INVALID_FILE_ATTRIBUTES || (attrs & FILE_ATTRIBUTE_DIRECTORY)) {
        std::wcerr << L"LdacA2dp.inf must be beside this tool.\n";
        SetupDiDestroyDeviceInfoList(target.set);
        return 16;
    }
    std::wstring publishedInf;
    if (!StageInf(infPath, publishedInf)) {
        SetupDiDestroyDeviceInfoList(target.set);
        return 17;
    }
    bool reboot = false;
    const bool ok = ApplyDriver(target, false, publishedInf, reboot);
    SetupDiDestroyDriverInfoList(target.set, &target.data, SPDIT_COMPATDRIVER);
    SetupDiDestroyDeviceInfoList(target.set);
    if (!ok) return 18;
    std::wcout << (reboot ? L"Restart required to complete installation.\n"
                          : L"Installation completed; restart is still recommended before playback testing.\n");
    return 0;
}
static int Rollback() {
    if (!IsAdministrator()) { std::wcerr << L"Run elevated as Administrator.\n"; return 20; }
    if (!IsSupportedOs() || !IsVmware()) {
        std::wcerr << L"Rollback tool is restricted to the Windows Server 2022 VMware test VM.\n";
        return 21;
    }
    TargetDevice target;
    if (!FindTarget(target, false)) {
        if (target.set != INVALID_HANDLE_VALUE) SetupDiDestroyDeviceInfoList(target.set);
        return 22;
    }
    bool reboot = false;
    const bool ok = ApplyDriver(target, true, L"", reboot);
    SetupDiDestroyDriverInfoList(target.set, &target.data, SPDIT_COMPATDRIVER);
    SetupDiDestroyDeviceInfoList(target.set);
    if (!ok) return 23;
    std::wcout << (reboot ? L"Rollback selected; restart required.\n"
                          : L"Rollback selected; restart recommended.\n");
    return 0;
}
int wmain(int argc, wchar_t** argv) {
    if (argc != 2) {
        std::wcout << L"Usage: oppo-driver-tool.exe status|install|rollback\n";
        return 1;
    }
    if (_wcsicmp(argv[1], L"status") == 0) return Status();
    if (_wcsicmp(argv[1], L"install") == 0) return Install();
    if (_wcsicmp(argv[1], L"rollback") == 0) return Rollback();
    std::wcerr << L"Unknown command.\n";
    return 1;
}
