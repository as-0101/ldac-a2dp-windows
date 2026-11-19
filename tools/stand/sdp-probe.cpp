#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0601
#include <winsock2.h>
#include <ws2bth.h>
#include <windows.h>
#include <bluetoothapis.h>
#include <cstdio>
#include <cstring>
#include <vector>

#pragma comment(lib, "Ws2_32.lib")
#pragma comment(lib, "Bthprops.lib")

static const GUID kDeviceIdService =
{ 0x00001200, 0x0000, 0x1000, { 0x80, 0x00, 0x00, 0x80, 0x5F, 0x9B, 0x34, 0xFB } };

static bool ParseAddress(const char* text, BTH_ADDR* address)
{
    unsigned int b[6]{};
    if (std::sscanf(text, "%2x:%2x:%2x:%2x:%2x:%2x",
        &b[0], &b[1], &b[2], &b[3], &b[4], &b[5]) != 6)
        return false;
    for (unsigned int v : b) if (v > 0xFF) return false;
    *address = 0;
    for (unsigned int v : b) *address = (*address << 8) | v;
    return true;
}

static bool ReadU16(const BYTE* record, ULONG length, USHORT id, USHORT* value)
{
    SDP_ELEMENT_DATA data{};
    DWORD error = BluetoothSdpGetAttributeValue(
        const_cast<LPBYTE>(record), length, id, &data);
    if (error != ERROR_SUCCESS || data.type != SDP_TYPE_UINT)
        return false;
    if (data.specificType == SDP_ST_UINT16) {
        *value = data.data.uint16;
        return true;
    }
    if (data.specificType == SDP_ST_UINT8) {
        *value = data.data.uint8;
        return true;
    }
    return false;
}

static void PrintAttribute(const BYTE* record, ULONG length,
                           USHORT id, const char* label)
{
    USHORT value = 0;
    if (ReadU16(record, length, id, &value))
        std::printf("  %-18s 0x%04X (%u)\n", label, value, value);
    else
        std::printf("  %-18s not present / unsupported type\n", label);
}

int main(int argc, char** argv)
{
    const char* addressText = argc > 1 ? argv[1] : "84:0F:2A:13:E3:E2";
    BTH_ADDR address = 0;
    if (!ParseAddress(addressText, &address)) {
        std::fprintf(stderr, "Invalid Bluetooth address. Expected XX:XX:XX:XX:XX:XX\n");
        return 2;
    }

    WSADATA wsa{};
    int rc = WSAStartup(MAKEWORD(2, 2), &wsa);
    if (rc != 0) {
        std::fprintf(stderr, "WSAStartup failed: %d\n", rc);
        return 3;
    }

    SOCKADDR_BTH peer{};
    peer.addressFamily = AF_BTH;
    peer.btAddr = address;
    peer.serviceClassId = GUID_NULL;
    peer.port = BT_PORT_ANY;
    char context[128]{};
    DWORD contextLength = sizeof(context);
    rc = WSAAddressToStringA(reinterpret_cast<LPSOCKADDR>(&peer),
        sizeof(peer), nullptr, context, &contextLength);
    if (rc == SOCKET_ERROR) {
        std::fprintf(stderr, "WSAAddressToString failed: %d\n", WSAGetLastError());
        WSACleanup();
        return 4;
    }

    WSAQUERYSETA query{};
    query.dwSize = sizeof(query);
    query.lpServiceClassId = const_cast<LPGUID>(&kDeviceIdService);
    query.dwNameSpace = NS_BTH;
    query.dwNumberOfCsAddrs = 0;
    query.lpszContext = context;

    HANDLE lookup = nullptr;
    DWORD flags = LUP_FLUSHCACHE | LUP_RETURN_BLOB | LUP_RETURN_NAME;
    if (WSALookupServiceBeginA(&query, flags, &lookup) == SOCKET_ERROR) {
        const int error = WSAGetLastError();
        std::fprintf(stderr, "WSALookupServiceBegin failed: %d\n", error);
        WSACleanup();
        return error == WSASERVICE_NOT_FOUND ? 5 : 6;
    }

    std::printf("Bluetooth SDP Device ID query\nPeer: %s\nContext: %s\n", addressText, context);
    unsigned int records = 0;
    bool foundIdentity = false;
    for (;;) {
        std::vector<BYTE> storage(4096);
        auto* result = reinterpret_cast<WSAQUERYSETA*>(storage.data());
        result->dwSize = static_cast<DWORD>(storage.size());
        DWORD bytes = static_cast<DWORD>(storage.size());

        if (WSALookupServiceNextA(lookup, flags, &bytes, result) == SOCKET_ERROR) {
            int error = WSAGetLastError();
            if (error == WSA_E_NO_MORE || error == WSAENOMORE) break;
            if (error != WSAEFAULT || bytes < sizeof(WSAQUERYSETA)) {
                std::fprintf(stderr, "WSALookupServiceNext failed: %d (required=%lu)\n", error, bytes);
                break;
            }

            storage.resize(bytes);
            result = reinterpret_cast<WSAQUERYSETA*>(storage.data());
            std::memset(result, 0, storage.size());
            result->dwSize = static_cast<DWORD>(storage.size());
            if (WSALookupServiceNextA(lookup, flags, &bytes, result) == SOCKET_ERROR) {
                error = WSAGetLastError();
                if (error == WSA_E_NO_MORE || error == WSAENOMORE) break;
                std::fprintf(stderr, "WSALookupServiceNext retry failed: %d\n", error);
                break;
            }
        }

        ++records;
        std::printf("\nRecord %u: %s\n", records,
            result->lpszServiceInstanceName ? result->lpszServiceInstanceName : "(unnamed)");
        if (result->lpBlob && result->lpBlob->pBlobData && result->lpBlob->cbSize) {
            const BYTE* blob = result->lpBlob->pBlobData;
            ULONG len = result->lpBlob->cbSize;
            USHORT vendor = 0, product = 0, version = 0, source = 0;
            bool hasVendor = ReadU16(blob, len, 0x0201, &vendor);
            bool hasProduct = ReadU16(blob, len, 0x0202, &product);
            bool hasVersion = ReadU16(blob, len, 0x0203, &version);
            bool hasSource = ReadU16(blob, len, 0x0205, &source);
            PrintAttribute(blob, len, 0x0201, "Vendor ID");
            PrintAttribute(blob, len, 0x0202, "Product ID");
            PrintAttribute(blob, len, 0x0203, "Version");
            PrintAttribute(blob, len, 0x0205, "Vendor ID source");
            if (hasVendor && hasProduct && hasSource) {
                foundIdentity = true;
                std::printf("  Identity tuple     %04X:%04X (source=%u)\n", vendor, product, source);
                if (hasVersion)
                    std::printf("  Device ID version  %u.%u\n", version >> 8, version & 0xFF);
            }
        } else {
            std::printf("  SDP record blob unavailable\n");
        }
    }

    WSALookupServiceEnd(lookup);
    WSACleanup();
    if (!records) {
        std::printf("No Device ID SDP record returned. This does not prove the headset lacks VID/PID.\n");
        return 7;
    }
    if (!foundIdentity) {
        std::printf("Device ID service returned, but its standard identity tuple was incomplete.\n");
        return 8;
    }
    std::printf("\nIdentity retrieved from SDP. It is not yet a verified Windows PnP hardware ID.\n");
    return 0;
}
