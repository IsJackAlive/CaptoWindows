# Dokumentacja projektu psSession0

[![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/IsJackAlive/CaptoWindows/tree/main/psSession0/README.en.md)

## Wprowadzenie

Z uwagi na problemy z konfiguracją Visual Studio, udostępniam gotowy do użycia projekt dla kompilacji DLL w języku C dla Windows.

## Opis

Biblioteka DLL wykonuje polecenie PowerShell w sesji 0. 
Uruchamia proces PowerShell z poleceniem uruchomienia usługi 'CertService'.
<a href="https://github.com/IsJackAlive/CaptoWindows/tree/main/certService">Link do usługi CertService</a>

Jest to zmodyfikowana wersja programu svc.c autorstwa Grzegorza Tworek. Kod svc.c jest dostępny na <a href="https://github.com/gtworek/PSBits/blob/master/Services/sekurak/svc.c">GitHub</a>.

> <details open>
>  <summary>Zrzuty ekranu</summary> </br>
>    <img alt="" src=".scs/0.png">
>    <img alt="" src=".scs/1.png"> </br>
>    Powershell uruchomiony przez administratora w zwyczajny sposób:
>    <img alt="" src=".scs/2.png">
> </details>

## Opis Funkcji

### PowerShellService

Uruchamia proces PowerShell z określonym poleceniem, odczekuje na zakończenie procesu, zabija go i odczytuje status. Zwracaną wartością jest kod błędu lub 0 w przypadku sukcesu.

### ServiceMain

Funkcja główna obsługująca zdarzenia związane z kontrolą nad usługą, takie jak START, STOP, PAUSE, CONTINUE.

# Jak uruchomić

Utwórz usługę, która będzie oparta na procesie svchost.
<img alt="create own service 'CaptoPs' based on svchost" src=".scs/5.png"> </br>

Rozmiar pliku DLL(po kompilacji) wynosi 132 KB / 135 680 B.
<img alt="correct size is about 132KB / 135 680B" src=".scs/7.png"> </br>

Otwórz Edytor rejestru (regedit) i utwórz nowy klucz dla swojej usługi. Klucz ten powinien być umieszczony w odpowiedniej lokalizacji.
<img alt="create new key in own service (regedit)" src=".scs/6.png"> </br>

Skonfiguruj ścieżkę do skompilowanej biblioteki DLL Twojej usługi.
<img alt="path to compiled dll" src=".scs/8.png"> </br>

Dodaj nazwę grupy dla svchost, w której umieściłeś swoją usługę.
<img alt="add group name for svchost" src=".scs/9.png"> </br>

Dodaj nazwę swojej usługi do wcześniej utworzonej grupy svchost.
<img alt="add service name in added group" src=".scs/10.png"> </br>

Otwórz DebugView jako administrator, aby śledzić informacje związane z działaniem DLL.
<img alt="view debug info in DebugView(admin)" src=".scs/11.png"> </br>

Uruchom usługę.
<img alt="start service 'CaptoPs'" src=".scs/12.png"> </br>