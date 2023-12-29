# Dokumentacja projektu psSession0

[![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/IsJackAlive/CaptoWindows/tree/main/psSession0/README.en.md)

## Wprowadzenie

Z uwagi na to, że konfiguracja Visual Studio sprawiała mi wiele problemów, uniemożliwiając prawidłową kompilację biblioteki DLL, udostępniam pliki, które umożliwią otwarcie działającego projektu do kompilacji DLL w języku C dla systemu Windows.

## Opis

Biblioteka DLL wykonuje polecenie PowerShell w sesji 0. 
Uruchamia proces PowerShell z poleceniem uruchomienia usługi 'CertService'.
<a href="https://github.com/IsJackAlive/CaptoWindows/tree/main/certService">Link do usługi CertService</a>

Jest to zmodyfikowana wersja programu svc.c autorstwa Grzegorza Tworek. Kod svc.c jest dostępny na <a href="https://github.com/gtworek/PSBits/blob/master/Services/sekurak/svc.c">GitHub</a>.

> <details open>
>  <summary>Zrzuty ekranu</summary> </br>
>    <img alt="" src=".scs/0.png" height=600px>
>    <img alt="" src=".scs/1.png" height=600px> </br>
>    Powershell uruchomiony przez administratora w zwyczajny sposób:
>    <img alt="" src=".scs/2.png" height=600px>
> </details>

## Opis Funkcji

### PowerShellService

Uruchamia proces PowerShell z określonym poleceniem, odczekuje na zakończenie procesu, zabija go i odczytuje status. Zwracaną wartością jest kod błędu lub 0 w przypadku sukcesu.

### ServiceMain

Funkcja główna obsługująca zdarzenia związane z kontrolą nad usługą, takie jak START, STOP, PAUSE, CONTINUE.