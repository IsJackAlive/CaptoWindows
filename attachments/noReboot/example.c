/*
 * Autor: Grzegorz Tworek
 * Data modyfikacji: 14.12.2023
*  Opis: Jest to zmodyfikowana wersja programu NoReboot.c
*  Link do kodu: https://github.com/gtworek/PSBits/blob/master/NoRebootSvc/NoReboot.c
 */
#include <windows.h>
#include <stdio.h>

#define SVCNAME TEXT("NoRebootSvc")
SERVICE_STATUS gSvcStatus;
SERVICE_STATUS_HANDLE gSvcStatusHandle;
wchar_t gDbgBuf[512];
DWORD gDwCheckPoint = 0;
const DWORD DW_TIMEOUT = 10 * 1000; //10s in ms

typedef RPC_STATUS(*WMSG_WMSGPOSTNOTIFYMESSAGE)(
	__in DWORD dwSessionID,
	__in DWORD dwMessage,
	__in DWORD dwMessageHint,
	__in LPCWSTR pszMessage
	);

// Wyswietla wiadomosc przed zamknieciem systemu. Taki sam typ jak "Instalowanie aktualizacji X z Y".
DWORD PreshutdownMsg(
	LPCWSTR msg
)
{
	static HMODULE hWMsgApiModule = NULL;
	static WMSG_WMSGPOSTNOTIFYMESSAGE pfnWmsgPostNotifyMessage = NULL;

	if (NULL == hWMsgApiModule)
	{
		// Ladowanie modulu API
		hWMsgApiModule = LoadLibraryEx(L"WMsgApi.dll", NULL, LOAD_LIBRARY_SEARCH_SYSTEM32);
		if (NULL == hWMsgApiModule)
		{
			return GetLastError();
		}
		// Pobieranie adresu funkcji
		pfnWmsgPostNotifyMessage = (WMSG_WMSGPOSTNOTIFYMESSAGE)GetProcAddress(hWMsgApiModule, "WmsgPostNotifyMessage");
		if (NULL == pfnWmsgPostNotifyMessage)
		{
			return GetLastError();
		}
	}
	if (NULL == pfnWmsgPostNotifyMessage)
	{
		return ERROR_PROC_NOT_FOUND;
	}

	// Wysylanie wiadomosci
	return pfnWmsgPostNotifyMessage(0, 0x300, 0, msg); // Musi byc 0x300, aby wiadomosc trafiła na ekran przed zamknieciem
} //PreshutdownMsg

// Funkcja do raportowania statusu uslugi
VOID NoRebootReportSvcStatus(
	DWORD dwCurrentState,
	DWORD dwWin32ExitCode,
	DWORD dwWaitHint
)
{
	swprintf_s(gDbgBuf, 512, L"%ws - %hs(dwCurrentState: %lu, dwWin32ExitCode: %lu, dwWaitHint: %lu) .\n", SVCNAME, __FUNCTION__, dwCurrentState, dwWin32ExitCode, dwWaitHint);
	OutputDebugString((LPCWSTR)gDbgBuf);

	gSvcStatus.dwCurrentState = dwCurrentState;
	gSvcStatus.dwControlsAccepted = SERVICE_ACCEPT_STOP | SERVICE_ACCEPT_PRESHUTDOWN;
	gSvcStatus.dwWin32ExitCode = dwWin32ExitCode;
	gSvcStatus.dwServiceSpecificExitCode = NO_ERROR;
	gSvcStatus.dwCheckPoint = gDwCheckPoint++;
	gSvcStatus.dwWaitHint = dwWaitHint;

	// Ustawienie statusu uslugi
	SetServiceStatus(gSvcStatusHandle, &gSvcStatus);
} //NoRebootReportSvcStatus


// Funkcja obsługi kontrolerów uslugi
DWORD WINAPI NoRebootSvcCtrlHandlerEx(
	DWORD dwControl,
	DWORD dwEventType,
	LPVOID lpEventData,
	LPVOID lpContext
)
{
	swprintf_s(gDbgBuf, 512, L"%ws - %hs(dwControl: %d) entered.\n", SVCNAME, __FUNCTION__, dwControl);
	OutputDebugString((LPCWSTR)gDbgBuf);

	switch (dwControl)
	{
	case SERVICE_CONTROL_STOP:
		NoRebootReportSvcStatus(SERVICE_STOPPED, NO_ERROR, DW_TIMEOUT); // Raport statusu: usluga zatrzymana, brak błędu
		break;
	case SERVICE_CONTROL_PRESHUTDOWN:
	{
		DWORD dwTimeoutRemaining = DW_TIMEOUT / 1000; // Przelicz czas na sekundy

		while (dwTimeoutRemaining > 0) // Pętla odliczajaca czas do wyłączenia uslugi
		{
			NoRebootReportSvcStatus(SERVICE_STOP_PENDING, NO_ERROR, DW_TIMEOUT); // Informuj SCM, ze usluga jest w trakcie zatrzymywania

			swprintf_s(gDbgBuf, 512, L"NoRebootService pozostało %d sekund.", dwTimeoutRemaining); // Wyswietlaj komunikat z odliczaniem
			PreshutdownMsg((LPCWSTR)gDbgBuf);

			Sleep(1000);
			dwTimeoutRemaining--; // Zmniejsz pozostały czas
		}

		NoRebootReportSvcStatus(SERVICE_STOPPED, NO_ERROR, DW_TIMEOUT); // Po zakonczeniu odliczania zakoncz petle, a nastepnie zatrzymaj usluge
		break;
	}

	default:
		break;
	}
	return NO_ERROR;
} //NoRebootSvcCtrlHandlerEx


// Funkcja konfigurująca czas przed wylaczeniem uslugi
VOID ConfigurePreshutdownTimeout(DWORD dwPreshutdownTimeout)  
{
	swprintf_s(gDbgBuf, 512, L"%ws - %hs(dwPreshutdownTimeout: %d) entered.\n", SVCNAME, __FUNCTION__, dwPreshutdownTimeout);
	OutputDebugString((LPCWSTR)gDbgBuf);

	SC_HANDLE hScManager;
	SC_HANDLE hService;
	BOOL bRes;
	SERVICE_PRESHUTDOWN_INFO svpi;
	LPSERVICE_PRESHUTDOWN_INFO lppi;
	DWORD dwBytesNeeded;
	DWORD err = 0;
	svpi.dwPreshutdownTimeout = dwPreshutdownTimeout;  // Ustawienie czasu przed wylaczeniem uslugi
	hScManager = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS); // Otwarcie menedzera uslug
	if (NULL == hScManager) // Jezeli otwarcie menedżera uslug nie powiodło sie
	{
		// Wyswietlanie informacji o błędzie
		swprintf_s(gDbgBuf, 512, L"%ws - OpenSCManager() failed with an error code %d.\n", SVCNAME, GetLastError());
		OutputDebugString((LPCWSTR)gDbgBuf);
	}
	else // Jeżeli otwarcie menedżera usług powiodło sie
	{
		// Otwarcie uslugi
		hService = OpenService(hScManager, SVCNAME, SERVICE_ALL_ACCESS);
		if (NULL == hService) // Jeżeli otwarcie uslugi nie powiodło sie
		{
			// Wyswietlanie informacji o bledzie
			swprintf_s(gDbgBuf, 512, L"%ws - OpenService() failed with an error code %d.\n", SVCNAME, GetLastError());
			OutputDebugString((LPCWSTR)gDbgBuf);
		}
		else // Jeżeli otwarcie uslugi powiodło sie
		{
			// Zmiana konfiguracji uslugi
			bRes = ChangeServiceConfig2(hService, SERVICE_CONFIG_PRESHUTDOWN_INFO, &svpi);
			if (!bRes) // Jeżeli zmiana konfiguracji uslugi nie powiodła się
			{
				// Wyswietlanie informacji o błędzie
				swprintf_s(gDbgBuf, 512, L"%ws - ChangeServiceConfig2() failed with an error code %d.\n", SVCNAME, GetLastError());
				OutputDebugString((LPCWSTR)gDbgBuf);
			}
			else // Jeżeli zmiana konfiguracji uslugi powiodła się
			{
				// Sprawdzenie konfiguracji uslugi
				lppi = (LPSERVICE_PRESHUTDOWN_INFO)LocalAlloc(LMEM_FIXED, sizeof(SERVICE_PRESHUTDOWN_INFO)); //not checking result here
				bRes = QueryServiceConfig2(hService, SERVICE_CONFIG_PRESHUTDOWN_INFO, (LPBYTE)lppi, sizeof(SERVICE_PRESHUTDOWN_INFO), &dwBytesNeeded);
				if (!bRes) // Jeżeli sprawdzenie konfiguracji uslugi nie powiodło sie
				{ 
					swprintf_s(gDbgBuf, 512, L"%ws - QueryServiceConfig2() failed with an error code %d.\n", SVCNAME, GetLastError());
					OutputDebugString((LPCWSTR)gDbgBuf);
				}
				else // Jeżeli sprawdzenie konfiguracji uslugi powiodło sie
				{
					// Wyswietlanie informacji o zmianie konfiguracji uslugi
					swprintf_s(gDbgBuf, 512, L"%ws - dwPreshutdownTimeout changed to %lu.\n", SVCNAME, lppi->dwPreshutdownTimeout);
					OutputDebugString((LPCWSTR)gDbgBuf);
				}
			}
		}
	}
} //ConfigurePreshutdownTimeout

// Funkcja inicjalizująca usluge
VOID NoRebootSvcInit(DWORD dwArgc, LPTSTR* lpszArgv)
{
	// Wyswietlanie informacji o wejsciu do funkcji
	swprintf_s(gDbgBuf, 512, L"%ws - %hs()\n", SVCNAME, __FUNCTION__);
	OutputDebugString((LPCWSTR)gDbgBuf);

	ConfigurePreshutdownTimeout(DW_TIMEOUT); // Konfiguracja czasu przed wylaczeniem uslugi

	NoRebootReportSvcStatus(SERVICE_RUNNING, NO_ERROR, 0);
	Sleep(INFINITE);
} //NoRebootSvcInit


VOID WINAPI NoRebootSvcMain(DWORD dwArgc, LPTSTR* lpszArgv)
{
	swprintf_s(gDbgBuf, 512, L"%ws - %hs() entered.\n", SVCNAME, __FUNCTION__);
	OutputDebugString((LPCWSTR)gDbgBuf);

	// Rejestruje funkcje obslugi dla uslugi
	gSvcStatusHandle = RegisterServiceCtrlHandlerEx(SVCNAME, (LPHANDLER_FUNCTION_EX)NoRebootSvcCtrlHandlerEx, NULL);
	if (!gSvcStatusHandle)
	{
		swprintf_s(gDbgBuf, 512, L"%ws - RegisterServiceCtrlHandlerEx() failed with an error code %d.\n", SVCNAME, GetLastError());
		OutputDebugString((LPCWSTR)gDbgBuf);
		return;
	}

	gSvcStatus.dwServiceType = SERVICE_WIN32_OWN_PROCESS;
	gSvcStatus.dwServiceSpecificExitCode = 0;

	NoRebootReportSvcStatus(SERVICE_START_PENDING, NO_ERROR, 3000); // Zglasza status uslugi jako oczekujący na uruchomienie
	NoRebootSvcInit(dwArgc, lpszArgv); // Inicjalizuje usługe
} //NoRebootSvcMain


int wmain(int argc, wchar_t* argv[], wchar_t* envp[])
{
	swprintf_s(gDbgBuf, 512, L"%ws - %hs() entered.\n", SVCNAME, __FUNCTION__);
	OutputDebugString((LPCWSTR)gDbgBuf);

	// Tworzy tablice z funkcją glowną uslugi
	SERVICE_TABLE_ENTRY dispatchTable[] =
	{
		{SVCNAME, (LPSERVICE_MAIN_FUNCTION)NoRebootSvcMain},
		{NULL, NULL} // koniec tablicy
	};

	// Uruchamia kontroler uslug
	if (!StartServiceCtrlDispatcher(dispatchTable))
	{
		DWORD le;
		le = GetLastError();
		swprintf_s(gDbgBuf, 512, L"%ws - StartServiceCtrlDispatcher() failed with error code %d.\n", SVCNAME, le);
		OutputDebugString((LPCWSTR)gDbgBuf);

		// Wyświetla komunikat dla użytkownika uruchamiającego binarny plik uslugi z cmd.exe
		if (ERROR_FAILED_SERVICE_CONTROLLER_CONNECT == le)
		{
			wchar_t ownPath[MAX_PATH];
			GetModuleFileName(GetModuleHandle(NULL), ownPath, (sizeof(ownPath)));  // Pobiera pełną ścieżkę do pliku wykonywalnego usługi
			wprintf(L"This is %ws service executable. Install it with: sc.exe create %ws binpath= \"%ws\"\n", SVCNAME, SVCNAME, ownPath);
		}
		return le;
	}
} //wmain
