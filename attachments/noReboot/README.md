# Dokumentacja NoRebootService

## Wprowadzenie
Z uwagi na problemy z konfiguracją Visual Studio, udostępniam gotowy do użycia projekt dla kompilacji EXE w języku C dla Windows.

* Autor: Grzegorz Tworek
* Opis: Jest to zmodyfikowana wersja programu NoReboot.c
* Link do kodu: https://github.com/gtworek/PSBits/blob/master/NoRebootSvc/NoReboot.c

## Opis
Jest to przykład wykorzystania usługi Windows do opóźnienia wyłączenia systemu.

Usługa reaguje na komunikat SERVICE_CONTROL_PRESHUTDOWN, który jest jednym z komunikatów kontrolnych, które System Control Manager (SCM) może wysłać do usługi systemowej. Po otrzymaniu komunikatu usługa rozpoczyna proces pre-shutdown, który obejmuje wyświetlanie komunikatu i blokowanie ponownego uruchomienia systemu na określony czas.

Usługa może być zdalnie wyłączona poleceniem `taskkill`.
W zmodyfikowanej wersji czas oczekiwania został ustawiony na 10 sekund.

## Funkcje
1. **NoRebootSvcMain** Główna funkcja usługi. Rejestruje funkcję obsługi dla usługi, ustawia typ usługi i kod wyjścia, a następnie zgłasza status usługi jako oczekujący na uruchomienie i inicjalizuje usługę.

2. **NoRebootSvcCtrlHandlerEx** W zależności od zdarzenia kontrolnego (np. SERVICE_CONTROL_STOP, SERVICE_CONTROL_PRESHUTDOWN), funkcja podejmuje odpowiednie kroki.

3. **ConfigurePreshutdownTimeout** Konfiguruje czas pre-shutdown, czyli czas blokowania systemu.

4. **NoRebootSvcInit** Funkcja inicjuje usługę i ustawia czas pre-shutdown za pomocą ConfigurePreshutdownTimeout. Następnie usługa ustawia swój stan na SERVICE_RUNNING i przechodzi w nieskończoną pętlę, co blokuje jej działanie do momentu otrzymania komunikatu STOP.

5. **NoRebootReportSvcStatus** Zgłasza bieżący status usługi.

6. **wmain** Punkt wejścia do programu. Tworzy tablicę z funkcją główną usługi i uruchamia kontroler usług. Jeżeli uruchomienie nie powiedzie się, wyświetla komunikat.

* **dispatchTable** Tablica jest używana do zarejestrowania głównej funkcji usługi. Każdy element tablicy SERVICE_TABLE_ENTRY składa się z dwóch pól: nazwy usługi (SVCNAME) i wskaźnika na funkcję główną usługi (NoRebootSvcMain).

* **StartServiceCtrlDispatcher** Łączy główną funkcję usługi z kontrolerem usług. Przyjmuje tablicę dispatchTable jako argument.