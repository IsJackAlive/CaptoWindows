/*
 * Opis: Biblioteka po dolaczeniu do serwisu svchost wykonuje polecenie PowerShell w sesji 0
 * Data: 14.12.2023
 *
 * Jest to zmodyfikowana wersja programu svc.c
 * Link do svc.c https://github.com/gtworek/PSBits/blob/master/Services/sekurak/svc.c
 */

#include <Windows.h>
#include <tchar.h>

#define MAXDBGLEN 256
#define SERVICENAME _T("CaptoPs")
#define SLEEPDELAYMS 10000

 /*
 * Komunikat debugowania dot. wejscia do funkcji
 * __FUNCTION__ reprezentuje nazwe aktualnej funkcji
 */
#define DBGFUNCSTART { \
	TCHAR strMsg[MAXDBGLEN] = { 0 }; \
	_stprintf_s(strMsg, _countof(strMsg), _T("[CaptoPs] Entering %hs()"), __FUNCTION__); \
	OutputDebugString(strMsg); \
}

 /*
 * Deklaracje zmiennych i struktury, która przechowuje informacje o statusie serwisu
 * https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_status
 */
HANDLE hTimer = NULL;
SERVICE_STATUS_HANDLE g_serviceStatusHandle = NULL;
SERVICE_STATUS g_serviceStatus =
{
	SERVICE_WIN32_SHARE_PROCESS,
	SERVICE_START_PENDING,
	SERVICE_ACCEPT_STOP | SERVICE_ACCEPT_SHUTDOWN | SERVICE_ACCEPT_PAUSE_CONTINUE,
	0,
	0,
	0,
	0
};

DWORD PowerShellService() {
	static HANDLE hPowerShellProcess = NULL;
	PROCESS_INFORMATION pi;
	TCHAR strMsg[MAXDBGLEN] = { 0 };

	DBGFUNCSTART;

	if (!hPowerShellProcess) {
		STARTUPINFO si = { sizeof(si) };
		
		if (!CreateProcess(
			_T("C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe"),
			_T("-NoProfile -Command \"Start-Service -Name 'CertService'\""),
			NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi)) {

				DWORD dwError = GetLastError();
				_stprintf_s(strMsg, _countof(strMsg), _T("[CaptoPs] CreateProcess failed, error: %d\r\n"), dwError);
				OutputDebugString(strMsg);
				return dwError;
		}
	} 

	// Oczekaj na zakończenie procesu
	WaitForSingleObject(pi.hProcess, INFINITE);

	// Zabij proces PowerShell po zakończeniu zadania
	TerminateProcess(pi.hProcess, 0);

	// Zwolnij 'uchwyty' do procesu
	CloseHandle(pi.hProcess);
	CloseHandle(pi.hThread);

	// Odczytaj dane wyjściowe standardowe i błędy
	DWORD dwRead;
	char buffer[4096];
	ZeroMemory(buffer, sizeof(buffer));
	if (ReadFile(GetStdHandle(STD_OUTPUT_HANDLE), buffer, sizeof(buffer) - 1, &dwRead, NULL)) {
		buffer[dwRead] = '\0';
		_stprintf_s(strMsg, _countof(strMsg), _T("[CaptoPs] PowerShell output:\r\n%s\r\n"), buffer);
		OutputDebugString(strMsg);
	}

	return 0; // Sukces
}

/*
* Uzywane do inicjalizacji modulu DLL
* Funkcja wylacza powiadomienia watków i zwraca TRUE po udanej inicjalizacji
*/
BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
	DBGFUNCSTART;
	DisableThreadLibraryCalls(hModule);
	return TRUE;
}

/*
* Funkcja obsluguje cyklicznosc serwisu przez czas.
* Wysyla komunikat debugowania, odczytuje polecenia z pliku i usypia watek na okreslony czas.
*/
unsigned long CALLBACK SvcTimer(void* param)
{
	DBGFUNCSTART;
	while (TRUE)
	{
		TCHAR strMsg[MAXDBGLEN] = { 0 };
		DWORD dwResult;
		_stprintf_s(strMsg, _countof(strMsg), _T("[CaptoPs] tick"));
		OutputDebugString(strMsg);

		dwResult = PowerShellService();
		_stprintf_s(strMsg, _countof(strMsg), _T("[CaptoPs] PowerShellService() returned %d"), dwResult);
		OutputDebugString(strMsg);

		Sleep(SLEEPDELAYMS);
	}
}

/*
* Funkcja obsluguje zdarzenia zwiazane z kontrola nad usluga
* Reaguje na rozne polecenia kontrolne, STOP, PAUSE, CONTINUE
* Aktualizuje status uslugi i informuje system operacyjny o zmianach
*/
DWORD WINAPI SvcHandlerFunc(DWORD dwControl, DWORD dwEventType, LPVOID lpEventData, LPVOID lpContext)
{
	DBGFUNCSTART;

	switch (dwControl)
	{
	case SERVICE_CONTROL_STOP:
	case SERVICE_CONTROL_SHUTDOWN:
		g_serviceStatus.dwCurrentState = SERVICE_STOPPED;	// Zatrzymuje usluge
		break;
	case SERVICE_CONTROL_PAUSE:
		g_serviceStatus.dwCurrentState = SERVICE_PAUSED;	// Wstrzymuje uslusluge
		break;
	case SERVICE_CONTROL_CONTINUE:
		g_serviceStatus.dwCurrentState = SERVICE_RUNNING;	// Wznawia usluge
		break;
	case SERVICE_CONTROL_INTERROGATE:	// Obsluguje zapytanie o biezacy stan uslugi
		break;
	default:
		break;
	}

	SetServiceStatus(g_serviceStatusHandle, &g_serviceStatus);	// Informuje system o zmianie stanu uslugi

	return NO_ERROR;
}

/*
* Funkcja glowna uslugi, która jest wywolywana, przy uruchomieniu - przez svchost
* Ustala funkcje obslugi zdarzen `SvcHandlerFunc`
* Ustawia stan uslugi na SERVICE_RUNNING
*/
__declspec(dllexport) VOID WINAPI ServiceMain(DWORD dwArgc, LPCWSTR* lpszArgv)
{
	DBGFUNCSTART;
	g_serviceStatusHandle = RegisterServiceCtrlHandlerEx(SERVICENAME, SvcHandlerFunc, NULL);
	if (!g_serviceStatusHandle)
	{
		return;
	}

	DWORD dwTid;
	hTimer = CreateEvent(NULL, FALSE, FALSE, NULL);
	CreateThread(NULL, 0, SvcTimer, NULL, 0, &dwTid);

	g_serviceStatus.dwCurrentState = SERVICE_RUNNING;
	SetServiceStatus(g_serviceStatusHandle, &g_serviceStatus);
}
