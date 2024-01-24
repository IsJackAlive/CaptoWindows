# Konfiguracja środowiska VisualStudio

## Gotowe konfiguracje

W przypadku trudności z przygotowaniem projektu VisualStudio można skorzystać z gotowych projektów dostępnych w repozytorium.

* [noReboot](https://github.com/IsJackAlive/CaptoWindows/blob/main/attachments/noReboot/service-example.vcxproj) - plik konfiguracyjny do kompilacji kodu w języku C do pliku wykonywalnego (.exe).
* [deleteCert](https://github.com/IsJackAlive/CaptoWindows/blob/main/deleteCert/deletecert.vcxproj) - plik konfiguracyjny do kompilacji kodu w języku C++ do pliku wykonywalnego (.exe).
* [psSession0](https://github.com/IsJackAlive/CaptoWindows/blob/main/psSession0/dll-example.vcxproj) - plik konfiguracyjny do kompilacji kodu w języku C do pliku biblioteki dynamicznej (.dll).

Korzystając z gotowej konfiguracji projektu, należy odpowiednio zmienić wartość znacznika `ClCompile` który wskazuje kompilatorowi Visual Studio, który plik ma zostać skompilowany.
```xml
<ClCompile Include="example.c" />
```

## Kompilowanie aplikacji (.exe)

> <details open>
>  <summary>Tworzenie nowego projektu</summary>
>    <img alt="Create a new project" src=".scs/1.png" height=400px> </br>
>    <img alt="Windows Desktop Wizard" src=".scs/2.png" height=400px> </br>
>    <img alt="" src=".scs/3.png" height=400px> </br>
>    <img alt="ConsoleApplication(.exe) [x]EmptyProject" src=".scs/4.png" height=400px> </br>
>    <img alt="Add New Item: example.c" src=".scs/5.png" height=400px> </br>
>    <img alt="Project -> <projectname> Properties" src=".scs/6.png" height=400px> </br>
>    <img alt="" src=".scs/7.png" height=400px> </br>
>    <img alt="" src=".scs/8.png" height=400px> </br>
>    <img alt="Release" src=".scs/9.png" height=400px> </br>
>    <img alt="Success output" src=".scs/10.png" height=400px> </br>
> </details>

## Kompilowanie biblioteki (.dll)

> <details open>
>  <summary>Tworzenie nowego projektu</summary>
>    <img alt="Create a new project" src=".scs/1.png" height=400px> </br>
>    <img alt="" src=".scs/11.png" height=400px> </br>
>    <img alt="DynamicLinkLibrary(.dll) [x]EmptyProject" src=".scs/12.png" height=400px> </br>
>    <img alt="Add New Item: example.c" src=".scs/13.png" height=400px> </br>
>    <img alt="Right-click on 'SolutionExplorer' -> Properties" src=".scs/14.png" height=400px> </br>
>    <img alt="" src=".scs/15.png" height=400px> </br>
>    <img alt="" src=".scs/7.png" height=400px> </br>
>    <img alt="Release" src=".scs/9.png" height=400px> </br>
>    <img alt="Success output" src=".scs/17.png" height=400px> </br>
> </details>
