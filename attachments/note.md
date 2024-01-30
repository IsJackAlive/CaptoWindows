# notatka z Windows Internals 7ed. Part 2

### Service characteristics //786

Wybrane parametry rejestru usług i sterowników

> Można tworzyć kombinacje typów, np. <br>
> Type: 0x00000110 = 0x10 + 0x100 <br>
>
> **Połączenie 0x1 + 0x10 nie ma sensu** <br>
> (SERVICE_KERNEL_DRIVER + SERVICE_WIN32_OWN_PROCESS) ponieważ SERVICE_KERNEL_DRIVER wskazuje na sterownik jądra, który nie działa w procesie użytkownika.

| Wartość Uruchamiania | Nazwa Wartości | Opis Ustawienia Wartości |
| - | - | - |
| Start                | SERVICE_BOOT_START(0x0)    | Winload wczytuje sterownik, aby był w pamięci podczas uruchamiania systemu. Te sterowniki są inicjowane tuż przed sterownikami SERVICE_SYSTEM_START. |
|                     | SERVICE_SYSTEM_START(0x1)  | Sterownik ładowany i inicjowany podczas inicjalizacji jądra po tym, jak sterowniki SERVICE_BOOT_START zostały zainicjowane. |
|                     | SERVICE_AUTO_START(0x2)    | SCM uruchamia sterownik lub usługę po uruchomieniu procesu SCM, Services.exe. |
|                     | SERVICE_DEMAND_START(0x3)  | SCM uruchamia sterownik lub usługę na żądanie (gdy klient wywołuje StartService na niej, jest uruchamiany przez określony wyzwalacz lub gdy inna usługa jest od niej zależna.) |
| - | - | - |
| Typ                | SERVICE_KERNEL_DRIVER(0x1)    | Sterownik urządzenia. |
|                     | SERVICE_FILE_SYSTEM_DRIVER(0x2)  | Sterownik systemu plików w trybie jądra. |
|                     | SERVICE_ADAPTER(0x4)    | Przestarzały. |
|                     | SERVICE_RECOGNIZER_DRIVER(0x8)  | Sterownik rozpoznawania systemu plików. |
|                     | SERVICE_WIN32_OWN_PROCESS(0x10)    | Usługa działa w procesie, który hostuje tylko jedną usługę. |
|                     | SERVICE_WIN32_SHARE_PROCESS(0x20)  | Usługa działa w procesie, który hostuje wiele usług. |
|                     | SERVICE_USER_OWN_PROCESS(0x50)    | Usługa działa z tożsamością bezpieczeństwa zalogowanego użytkownika w własnym procesie. |
|                     | SERVICE_USER_SHARE_PROCESS(0x60)  | Usługa działa z tożsamością bezpieczeństwa zalogowanego użytkownika w procesie, który hostuje wiele usług. |
|                     | SERVICE_INTERACTIVE_PROCESS(0x100) | Usługa ma prawo wyświetlać okna na konsoli i odbierać wejście od użytkownika, ale tylko w sesji konsoli (0), aby zapobiec interakcji z użytkownikem/aplikacjami konsolowymi w innych sesjach. Ta opcja jest przestarzała. |
| - | - | - |
| Grupa              | Grupa o nazwie | Sterownik lub usługa inicjalizuje się, gdy jej grupa jest inicjowana. |
| - | - | - |
| ImagePath          | Ścieżka do pliku wykonywalnego usługi lub sterownika | Jeśli ImagePath nie jest określony, menedżer wejścia-wyjścia szuka sterowników w %SystemRoot%\System32\Drivers. Wymagane dla usług systemu Windows. |
| - | - | - |
| DeleteFlag         | 0 lub 1 (TRUE lub FALSE)   | Tymczasowa flaga ustawiana przez SCM, gdy usługa jest oznaczona do usunięcia. |
| - | - | - |
| ServiceSidType     | SERVICE_SID_TYPE_NONE(0x0)| Ustawienie zgodności wstecznej. |
|                     | SERVICE_SID_TYPE_UNRESTRICTED (0x1) | SCM dodaje identyfikator SID usługi jako właściciela grupy do tokena procesu usługi podczas jego tworzenia. |
|                     | SERVICE_SID_TYPE_RESTRICTED (0x3) | SCM uruchamia usługę za pomocą tokena z ograniczeniami zapisu, dodając identyfikator SID usługi do listy ograniczonych SID procesu usługi, razem z SIDami świata, logowania i z ograniczonymi zapisami. |
| - | - | - |
| LaunchProtected    | SERVICE_LAUNCH_PROTECTED_NONE(0x0) | SCM uruchamia usługę bez ochrony (wartość domyślna). |
|                     | SERVICE_LAUNCH_PROTECTED_WINDOWS(0x1) | SCM uruchamia usługę w chronionym procesie systemowym Windows. |
|                     | SERVICE_LAUNCH_PROTECTED_WINDOWS_LIGHT(0x2) | SCM uruchamia usługę w chronionym procesie Windows Light. |
|                     | SERVICE_LAUNCH_PROTECTED_ANTIMALWARE_LIGHT(0x3) | SCM uruchamia usługę w chronionym procesie Antimalware Light. |
|                     | SERVICE_LAUNCH_PROTECTED_APP_LIGHT(0x4) | SCM uruchamia usługę w chronionym procesie App Light (tylko wewnętrznie). |
| - | - | - |
| SvcHostSplitDisable | 0 lub 1 (TRUE lub FALSE)   | Gdy ustawione na 1, zabrania SCM włączenia podziału Svchost. Wartość ta dotyczy tylko usług współdzielonych. |


### Service applications //783

Konta sieciowe: Proces działający w koncie sieciowym nie może załadować sterownika urządzenia ani otworzyć dowolnych procesów.
Procesy działające w koncie sieciowym korzystają z profilu konta sieciowego. Składnik rejestru profilu konta sieciowego ładuje się pod HKU\S-1-5-20, a pliki i katalogi tego komponentu znajdują się w %SystemRoot%\ServiceProfiles\NetworkService.

Przykład usługi w koncie sieciowym: Przykładem usługi działającej w koncie sieciowym jest klient DNS, odpowiedzialny za rozwiązywanie nazw DNS i lokalizację kontrolerów domeny.

Dostęp do klucza Parameters: SCM nie uzyskuje dostępu do podklucza Parameters usługi, dopóki usługa nie zostanie usunięta. Wtedy SCM usuwa cały klucz usługi, wraz z podkluczami, takimi jak Parameters.

Usługi bez interfejsu użytkownika: Ponieważ większość usług nie ma interfejsu użytkownika, są one tworzone jako programy konsolowe.

Rejestracja usługi: Podczas instalacji aplikacji zawierającej usługę, program instalacyjny (który zazwyczaj działa również jako SCP) musi zarejestrować usługę w systemie. Do tego celu używa funkcji CreateService systemu Windows, eksportowanej w Advapi32.dll (%SystemRoot%\System32\ Advapi32.dll). Ważniejsze interfejsy API klienta SCM są zaimplementowane w innej bibliotece DLL, Sechost.dll, będącej biblioteką hosta dla API klienta SCM i LSA. Komunikacja z SCM większości interfejsów API klienta odbywa się przez RPC. SCM jest zaimplementowany w pliku Services.ex

### The Service Control Manager (SCM) //825

Service Control Manager (SCM): SCM jest odpowiedzialny za uruchamianie, zatrzymywanie i współpracę z procesami usług. Jego plik wykonywalny to %SystemRoot%\System32\Services.exe, uruchamiany przez proces Wininit na wczesnym etapie bootowania systemu.

Inicjalizacja SCM: Proces inicjalizacji SCM (funkcja SvcCtrlMain) obejmuje ustawienie zabezpieczeń procesu, utworzenie reprezentacji w pamięci SID, oraz stworzenie dwóch zdarzeń synchronizacyjnych (SvcctrlStartEvent_A3752DX i SC_AutoStartComplete) mających kluczowe znaczenie dla kontroli procesów.

Baza danych usług SCM: SCM tworzy bazę danych usług, czytając i przechowując zawartość klucza rejestru HKLM\SYSTEM\CurrentControlSet\Services. Baza ta obejmuje parametry związane z usługami oraz śledzi ich status.

Grupy usług: SCM organizuje usługi w grupy na podstawie wartości klucza Group. Grupy te określają kolejność startu usług, co jest istotne dla zapewnienia poprawności uruchamiania usług zależnych.

Zależności usług: SCM czyta i rejestruje zależności między usługami, korzystając z wartości kluczy DependOnGroup i DependOnService, co pozwala określić, która usługa jest zależna od konkretnej usługi.

Czyszczenie i inicjalizacja: SCM usuwa z rejestru usługi oznaczone jako usunięte (DeleteFlag) i generuje listę zależności dla każdej usługi w bazie danych.

Tryb awaryjny: SCM sprawdza, czy system został uruchomiony w trybie awaryjnym, co jest istotne dla późniejszego określenia, czy dana usługa powinna zostać uruchomiona.

Inicjalizacja dodatkowa: Przed uruchomieniem usług autostartowych, SCM inicjalizuje menedżer sterowników UMDF, a także oczekuje na pełną inicjalizację znanych bibliotek DLL