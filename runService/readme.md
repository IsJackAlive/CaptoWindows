# Opis skryptu RunService.ps1
## Wprowadzenie
Skrypt służy do utworzenia i uruchomienia prostego serwisu systemowego w systemie Windows. Serwis ten jest napisany w języku C# i kompilowany do pliku wykonywalnego (.exe) w trakcie działania skryptu.

<details open>
  <summary>Skrypt wykonuje następujące czynności:</summary>
  
* Definiowanie parametrów serwisu 
Na początku skryptu definiowane są podstawowe parametry serwisu, takie jak nazwa, wyświetlana nazwa i opis. `$serviceName` `$serviceDisplayName` `$serviceDescription`

* Definiowanie kodu C#
Skrypt zawiera fragment kodu w języku C#, który definiuje logikę działania serwisu. `$serviceCode`

* Kod C# tworzy klasę MyService, dziedziczącą po klasie ServiceBase, która jest podstawową klasą bazową dla serwisów systemowych w .NET Framework.

* Metoda OnStart jest wywoływana po rozpoczęciu pracy serwisu i inicjuje timer, który co 30 sekund wykonuje metodę DoWork, odpowiedzialną za wykonanie konkretnej logiki serwisu. Metoda OnStop jest wywoływana przy zatrzymywaniu serwisu i usuwa timer.

* W kodzie C# znajduje się metoda Main, która uruchamia serwis.

* Zapisywanie i kompilowanie kodu C#
Skrypt zapisuje kod C# do pliku o nazwie "RunService.cs" w folderze tymczasowym systemu ($env:TEMP). Następnie używa funkcji Add-Type do skompilowania kodu C# do pliku wykonywalnego (.exe) o nazwie "RunService.exe" w tym samym folderze. W trakcie kompilacji podane są wymagane odwołania do biblioteki System.ServiceProcess.dll.

* Dodawanie serwisu do Serwisów Windows
Po skompilowaniu pliku .exe skrypt uruchamia narzędzie sc.exe (Service Control) w celu utworzenia serwisu systemowego. Wywołanie sc.exe używa parametrów takich jak nazwa serwisu, ścieżka do pliku .exe i wyświetlana nazwa serwisu. Serwis jest tworzony z ustawieniami autostartu i automatycznego uruchamiania.

* Ustawianie opisu serwisu
Skrypt używa WMI (Windows Management Instrumentation) do pobrania obiektu serwisu o nazwie `$serviceName` i ustawienia opisu serwisu `$serviceDescription`. Zmiany są zapisywane przy użyciu metody Put().

* Sprawdzanie stanu serwisu
Na końcu skrypt używa polecenia Get-Service w celu sprawdzenia stanu serwisu i wyświetlenia informacji o nim.
</details>

## Aby uruchomić serwis
W PowerShell wpisz: `sc.exe start RunService`

## Uwagi
Przed uruchomieniem skryptu upewnij się, że masz odpowiednie uprawnienia administratora.

## Podsumowanie
Skrypt RunService.ps1 służy do tworzenia i uruchamiania prostego serwisu systemowego w systemie Windows. Można go dostosować i wykorzystać jako przykład do tworzenia własnych serwisów systemowych w oparciu o język C# i PowerShell.