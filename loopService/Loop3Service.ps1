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
        protected override void OnStart(string[] args)
        {   
            base.OnStart(args);
        }
        protected override void OnStop()
        {   
            base.OnStop();
        }
        protected override void OnPause()
        {
            base.OnPause();
        }
        protected override void OnContinue()
        {
            base.OnContinue();
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
    ReferencedAssemblies = "System.ServiceProcess.dll"
}

# Kompilacja kodu do pliku wykonywalnego (.exe)
Add-Type @compilerParams

# Dodawanie serwisu do Serwisów Windows
$binPath = "`"$(Convert-Path $assemblyPath)`""
Start-Process -FilePath "sc.exe" -ArgumentList "create $serviceName binpath= `"$binPath`" DisplayName= `"$serviceDisplayName`" start= auto" -NoNewWindow -Wait

# Sprawdzanie stanu serwisu
Get-Service -Name $serviceName | Select-Object Name, Status

# Dodanie zależności Loop3Service od Loop2Service
Start-Process -FilePath "sc.exe" -ArgumentList "config $serviceName depend= Loop2Service" -NoNewWindow -Wait

Write-Host "Aby uruchomić wpisz: sc.exe start $serviceName `nJeśli wystąpiły błędy usuń za pomocą: sc.exe delete $serviceName"