# Dokumentacja skryptów LoopService

## Wprowadzenie

Zestaw skryptów LoopService służy do tworzenia i uruchamiania prostych serwisów systemowych, analogicznie do przykładów RunService, CertService, cantStop.

```powershell
# Ustaw zależność serwisu Loop2 od serwisu Loop1
sc.exe config Loop2Service depend= Loop1Service

# Ustaw zależność serwisu Loop1 od serwisu Loop2
sc.exe config Loop1Service depend= Loop2Service
```

<details open>
  <summary>Opis skryptów:</summary>

1. **Loop1Service.ps1**
    - Zapisuje zainstalowane sterowniki w pliku `C:\InstalledDrivers.txt`

2. **Loop2Service.ps1**
    - Tworzy plik `C:\\SystemInfo.txt`, który może zawierać: Informacje o kontach użytkowników, grupach, uprawnieniach oraz datę ostatniej aktualizacji systemu

</details>