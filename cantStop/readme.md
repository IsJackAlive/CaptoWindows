# Opis skryptu CantStop.ps1

## Wprowadzenie

Skrypt CantStop.ps1 służy do utworzenia i uruchomienia prostego serwisu systemowego w systemie Windows o nazwie "cantStop". Serwis ten jest napisany w języku C# i kompilowany do pliku wykonywalnego (.exe) w trakcie działania skryptu.

<details open>
  <summary>Skrypt wykonuje następujące czynności:</summary>

* Definiowanie parametrów serwisu
Na początku skryptu definiowane są podstawowe parametry serwisu, takie jak nazwa, wyświetlana nazwa i opis. `$serviceName` `$serviceDisplayName` `$serviceDescription`

* Definiowanie kodu C#
Skrypt zawiera fragment kodu w języku C#, który definiuje logikę działania serwisu. `$serviceCode`

* Kod C# tworzy klasę MyService, dziedziczącą po klasie ServiceBase, która jest podstawową klasą bazową dla serwisów systemowych w .NET Framework.

* W kodzie C# znajduje się metoda Main, która uruchamia serwis.

* Zapisywanie i kompilowanie kodu C#
Skrypt zapisuje kod C# do pliku o nazwie "cantStop.cs" w folderze tymczasowym systemu ($env:TEMP). Następnie używa funkcji Add-Type do skompilowania kodu C# do pliku wykonywalnego (.exe) o nazwie "cantStop.exe" w tym samym folderze. W trakcie kompilacji podane są wymagane odwołania do biblioteki System.ServiceProcess.dll.

* Dodawanie serwisu do Serwisów Windows
Po skompilowaniu pliku .exe skrypt tworzy serwis z automatycznym typem startu.

</details>

## Aby uruchomić serwis
W PowerShell wpisz: `sc.exe start cantStop`

## Uwagi
Przed uruchomieniem skryptu upewnij się, że masz odpowiednie uprawnienia administratora.