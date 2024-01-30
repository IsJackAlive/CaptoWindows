# Pusty serwis

# Tworzenie usługi
$serviceName = "Loop3Service"
$serviceDisplayName = "Loop3 Service"

# Definiowanie kodu C#
$serviceCode = @"
using System;
using System.ServiceProcess;
using System.Threading;

namespace powerShellService
{
    public class pShellService : ServiceBase
    {
        public pShellService()
        {
            ServiceName = "$serviceName";
            CanStop = true;
            CanPauseAndContinue = true;
        }
        public static void Main()
        {
            ServiceBase.Run(new pShellService());
        }
    }
}
"@

# Zapisywanie kodu C# do pliku
$serviceCodePath = Join-Path -Path $env:TEMP -ChildPath "$serviceName.cs"
$serviceCode | Out-File -FilePath $serviceCodePath -Encoding UTF8

# Tworzenie ścieżki do pliku wykonywalnego (.exe)
$assemblyPath = Join-Path -Path $env:TEMP -ChildPath "$serviceName.exe"

# Parametry kompilacji
$compilerParams = @{
    TypeDefinition = Get-Content -Path $serviceCodePath -Raw
    OutputAssembly = $assemblyPath
    ReferencedAssemblies = "System.dll", "System.ServiceProcess.dll"
}

# Kompilacja kodu do pliku wykonywalnego (.exe)
Add-Type @compilerParams

# Dodawanie serwisu do Serwisów Windows
$binPath = "`"$(Convert-Path $assemblyPath)`""
New-Service -Name $serviceName -BinaryPathName $binPath -DisplayName $serviceDisplayName -StartupType Automatic

# Dodanie zależności Loop3Service od Loop2Service
Start-Process -FilePath "sc.exe" -ArgumentList "config $serviceName depend= Loop2Service" -NoNewWindow -Wait

# Zapisz informacje o utworzonym serwisie na pulpicie
$desktopPath = [Environment]::GetFolderPath("Desktop")
$servicesFilePath = Join-Path -Path $desktopPath -ChildPath "CaptoServices.txt"
$creationDate = Get-Date -Format "MM-dd HH:mm:ss"
Add-Content -Path $servicesFilePath -Value "Date: $creationDate Name: $serviceName Path: $assemblyPath"

Write-Host "Aby uruchomic wpisz: sc.exe start $serviceName `nJesli wystapily bledy usun za pomoca: sc.exe delete $serviceName `nPlik $serviceName.exe znajduje sie w $assemblyPath"